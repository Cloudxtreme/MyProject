#This file provides method to update PR number on CAT.
#Handles user authentication and updates triage provided
#PR/Bug id and CAT test run ID is given.
#Example useage:
#
# from cat_triage import *
# cat_triage(username, password, str(bug_id), str(testrun_id))
#
#Sometimes in above implementation the urllib2 breaks the
#request packet into one for header and another for json object.
#This may cause HTTPError since the server considers only the
#first packet and thus cant find the params. To avoid this
#call the python script as a seperate process and pass the
#paramerers as arguments as shown:
#
# import os
# os.system('python cat_triage.py %s %s %d %d' % /
#          (USER, PASSWORD, bug_id, options.catid))
#
################################################################################

import urllib2
import json
import logging
import sys

LOG_FORMAT = '%(asctime)s %(levelname)-8s %(message)s'

logging.basicConfig(level=logging.DEBUG,
                    format=LOG_FORMAT,
                    datefmt='%a, %d %b %Y %H:%M:%S')

CAT_URI = 'http://nsx-cat.eng.vmware.com/api/v2.0/bugzilla/'

def cat_triage(username, password, bug_id, testrun_id):
    '''Function to update CAT with the bug number

    Param          Type         Description
    user           string       username for cat login
    password       string       Password for cat login
    bug_id         int          Bug ID / PR number
    testrun_id     int          CAT testrun ID
    '''
    params = {}
    params['username'] = username
    params['password'] = password
    params['number'] = bug_id
    params['testruns'] = [testrun_id]
    params['copylogs'] = [testrun_id]

    try:
        headers = {"Content-type" : "application/json",
                   "Accept" : "text/plain"}

        #First do GET for given PR number to see if it exists in the system
        request = urllib2.Request("%s?format=json&number=%s" % (CAT_URI,
                                  params['number']))
        request.get_method = lambda: 'GET'
        resp = urllib2.urlopen(request)
        resp_dict = json.loads(resp.read())

        if resp_dict['meta']['total_count'] == 0:
            # No resource with given PR, create new
            logging.debug("No resource with given PR, do POST")
            # URI will in form "http://cat/api/v2.0/bugzilla/"
            request = urllib2.Request("%s?format=json" % CAT_URI,
                                      json.dumps(params), headers)
            request.get_method = lambda: 'POST'

        else:
            # resource exists, do a PATCH
            logging.debug("resource exists, do a PATCH")
            # URI will in form "http://cat/api/v2.0/bugzilla/24973/"
            if 'number' in params:
                del params['number'] # Bugzilla resource already has number.

            request = urllib2.Request("%s%s/?format=json" %
                                 (CAT_URI, resp_dict['objects'][0]['id']),
                                  json.dumps(params), headers)
            request.get_method = lambda: 'PATCH'

        resp = urllib2.urlopen(request)

    except urllib2.HTTPError, e:
        logging.debug("HTTPError")
        logging.debug(e.read())
        return 1
    except Exception, e:
        logging.debug('CAT triage request failed: %s' % str(e))
        return 1

    return 0

def main(args):

    return cat_triage(args[0], args[1], args[2], args[3])

if __name__ == "__main__":
    main(sys.argv[1:])
