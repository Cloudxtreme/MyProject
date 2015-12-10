#!/build/toolchain/lin32/python-2.6.1/bin/python -S
import sys
# Workaround until PR 1436594 is fixed
sys.path.insert(1, "/build/toolchain/lin32/python-2.6.1/lib/python2.6/")
import os
import re
import yaml
from time import sleep as sleep_sec
import racetrack
from log_parse import *
from bugzilla_client import *
from optparse import OptionParser
from subprocess import Popen, PIPE

'''Global dictionary to store options'''
options = None

def parse_options(args):
    parser = OptionParser(usage="%prog -r")

    parser.add_option("-r", "--racetrackid",
                      action="store", dest="rtid", default=None,
                      help="Racetrack id",
                      type="int")

    parser.add_option("-d", "--logdir",
                      action="store", dest="logdir", default=None,
                      help="Path to test case results",
                      type="string")

    parser.add_option("-a", "--assignee",
                      action="store", dest="assignee", default=None,
                      help="User name of person to whom bug is to be assigned",
                      type="string")

    parser.add_option("-b", "--filebug",
                      action="store_true", dest="filebug", default=False,
                      help="Use this option to enable bug filing")

    parser.add_option("-y", "--config",
                      action="store", dest="confyaml", default=None,
                      help="configuration yaml file",
                      type="string")

    parser.add_option("--file_product_bug",
                      action="store", dest="fileproductbug", default=None,
                      help="File PR against products",
                      type="string")

    parser.add_option("-t", "--testcase",
                      action="store", dest="testcase", default=None,
                      help="Testcase name",
                      type="string")

    parser.add_option("-l", "--logfiles",
                      action="append", dest="logfiles", default=None,
                      help="Name of log file to be parsed",
                      type="string")

    parser.add_option("--testrunurl",
                      action="store", dest="testrunurl",
                      default= None,
                      help="CAT testrun URL", type="string")

    (globals()["options"], args) = parser.parse_args(args)
    return args


def main(args):

    args = parse_options(args)

    if not options.testrunurl:
        logging.debug("CAT testrun ID not provided. \
        Bug ID will not be updated on CAT");
    else:
        options.testrunurl = options.testrunurl.rstrip('/')
        testrun_id = int(options.testrunurl.split('/')[-1])

    if not options.rtid:
        logging.debug("Racetrack ID not provided. \
        Bug ID will not be updated on Racetrack");
    else:
        racetrack.advanced = True

    curr_dir = os.path.dirname(os.path.realpath(__file__))

    if not options.confyaml:
        #keep the yaml file in same folder as the script
        options.confyaml = '%s/vdnet_auto_triage_config.yaml' % curr_dir

    #Read yaml
    config_file = open(options.confyaml, 'r')
    config_data = yaml.safe_load(config_file)
    log_info = config_data['logfiles']
    bug_info = config_data['buginfo']
    present_bugzilla = config_data['present_bugzilla']

    bug_uname = config_data['accounts']['bugzilla']['username']
    bug_password = config_data['accounts']['bugzilla']['password']

    cat_uname = config_data['accounts']['cat']['username']
    cat_password = config_data['accounts']['cat']['password']

    #set assignee and CC list if given
    if options.assignee:
        owners = options.assignee.split(',')

        #assign the bug to first owner
        bug_info['assigned_to'] = owners[0]

        #add rest all to cc list
        if len(owners) > 1:
            if bug_info['cc']:
                bug_info['cc'] += owners[1:]
            else:
                bug_info['cc'] = owners[1:]

    bug_client = BugzillaClient(bug_uname, bug_password)
    bug_client.login()

    log_parser = LogParse()

    #Get all valid log files to parse, from yaml
    valid_logs = log_info.keys()

    if not os.path.isdir(options.logdir):
        #Throw error if logdir is not a valid path
        raise Exception("Invalid Log directory: %s" % options.logdir)

    if options.testcase:
        matched_product = None
        recent_bugs = {}
        matched_product = re.match(present_bugzilla['pattern'],
                                    options.testcase, re.I)

        # assign PR to default bugzilla assignee in case of product
        #  issue othewise default owner in case of Vdnet failure
        if matched_product:
            if matched_product.group(2) != present_bugzilla['default']['category']\
               and options.fileproductbug == "yes":
                bug_info['assigned_to'] = ""
                recent_bugs = bug_client.search_bug(product = bug_info['product'],
                                               category = matched_product.group(2),
                                               in_days = 0)

        # hardcoded for 'NSXTransformers' now as dev team can't
        #  change product name on bugzilla
        if matched_product:
            if matched_product.group(1) == 'NSXTransformers':
                bug_info['product'] = 'NSX Transformers'
            else:
                bug_info['product'] = matched_product.group(1)
        else:
            logging.debug("Failed to parse testcase: "
                            "%s" % options.testcase)

        if recent_bugs:
            bug_info['category'] = matched_product.group(2)
            # only VDNet has a different component
            if bug_info['category'] == 'VDNet':
                bug_info['component'] = present_bugzilla['default']['component']
        else:
            if options.fileproductbug == "yes":
                logging.debug("Product not matched in bugzilla."
                                " Filing against default product.")
            bug_info['product'] = present_bugzilla['default']['product']
            bug_info['category'] = present_bugzilla['default']['category']
            bug_info['component'] = present_bugzilla['default']['component']

    triage_count = 0

    #recursively walk throught the directory structure
    for (path, dirs, files) in os.walk(options.logdir):
        #Get all log files in given path, which need to be parsed
        log_files = [f for f in files if f in valid_logs]

        #parse only given log files if specified
        if options.logfiles:
            log_files = [f for f in log_files if f in options.logfiles]

        if options.testcase:
            test_case = options.testcase
        else:
            test_case = ""

        bug_description = ''

        #clear all previous search keys
        log_parser.clear_search_keys()
        #Iterate through all log files in given path
        for log_file in log_files:
            logging.debug("Parsing %s" % log_file)
            bug_description += log_parser.generate_report(test_case,
                               path, log_file,
                               log_info[log_file])

        #skip rest if no description for filing bug
        if not bug_description:
            continue

        #add CAT testrun URL to description
        if options.testrunurl:
            bug_description = "CAT testrun URL: %s\n%s" % (options.testrunurl,
                                                           bug_description)

        triage_count += 1

        if options.filebug:
            logging.debug("Search Keys: %s" % log_parser.get_search_keys())

            #set summary and description for the bug
            bug_info['summary'] = log_parser.get_summary()
            bug_info['description'] = bug_description

            max_keywords_match = log_parser.get_max_keywords_match()

            #File a new bug
            if log_parser.get_search_keys():
                bug_id = bug_client.check_and_create_bug(log_parser.get_search_keys(),
                                                        bug_info, max_keywords_match)

                #Update CAT if id is specified
                if(testrun_id and bug_id):
                    logging.debug("Adding PR no. %d to Testrun ID. %d on CAT"\
                                  % (bug_id, testrun_id))

                    cmd = 'python %s/cat_triage.py %s %s %d %d' %\
                          (curr_dir, cat_uname, cat_password, bug_id, testrun_id)

                    p = Popen(cmd.split(' '), stdout=PIPE)

                #Update Racetrack if id is specified
                if(options.rtid is not None and bug_id is not None):
                    logging.debug("Adding Bug ID. %d to Racetrack ID. %d" % \
                                    (bug_id, options.rtid))
                    racetrack.testCaseTriage(options.rtid,'PRODUCT',bug_id)

    logging.debug("Exiting Auto Triage")

    return triage_count

if __name__ == "__main__":
    main(sys.argv[1:])

