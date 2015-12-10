import re
import sys
import string
import logging
import operator

LOG_FORMAT = '%(asctime)s %(levelname)-8s %(message)s'

logging.basicConfig(level=logging.DEBUG,
                    format=LOG_FORMAT,
                    datefmt='%a, %d %b %Y %H:%M:%S')


class LogParse:
    '''Class to generate report from test logs
    '''

    def __init__(self):
        '''Constructor to create an instance of class LogParse
        '''
        self.report = None
        self.search_keys = []
        self.summary = ""

    def generate_report(self, testcase_name,
                        log_dir, log_file,
                        log_info):

        '''Searches for keywords in log file and generates a
           report file <logfilename>.log.rep in same folder.
           Also generates search keys to search for similar bugs in bugzilla.

           Param          Type         Description
           testcase_name  String       testcase name
           log_dir        String       path to log file
           log_file       String       name of log file
           log_info       Dictionary   dictionary having keywords to search,
                                       lines to print, regex expressions to
                                       identify timestamp, file names in logs
        '''

        keywords = log_info['keywords']
        before = 0
        after = 0
        max_keywords_match = 0
        timestamp = None
        failure_pattern = None
        negative_key = None
        scriptfile = None
        pattern_type = None
        keyword_log_limit = 0

        if 'before' in log_info['print_lines'].keys():
            before = log_info['print_lines']['before']

        if 'after' in log_info['print_lines'].keys():
            after = log_info['print_lines']['after']

        if 'max_keywords_match' in log_info.keys():
            max_keywords_match = log_info['max_keywords_match']

        if 'timestamp' in log_info['logformat'].keys():
            timestamp = log_info['logformat']['timestamp']

        if 'filename' in log_info['logformat'].keys():
            scriptfile = log_info['logformat']['filename']

        if 'negative_key' in log_info['logformat'].keys():
            negative_key = log_info['logformat']['negative_key']

        if 'failure_pattern' in log_info.keys():
            failure_pattern = log_info['failure_pattern']

        if 'log_levels' in log_info.keys():
            log_levels = log_info['log_levels']

        if 'pattern_type' in log_info.keys():
            pattern_type = log_info['pattern_type']

        if 'keyword_log_limit' in log_info.keys():
            keyword_log_limit = log_info['keyword_log_limit']

        failure_pattern_matched = False

        file_name = ("%s/%s" % (log_dir, log_file)).replace('//', '/')

        # Open the log flie
        log_file_handle = open(file_name, 'r')

        self.report = ""

        if testcase_name:
            self.report = "Testcase Name: %s\n" % testcase_name
        self.report += "Log File: %s\n\n" % file_name

        if pattern_type:
            for pattern in pattern_type:
                self.parse(pattern, log_info, log_file_handle)

        self.report += "\n"
        line_isascii = False
        searchlines = []

        for line in log_file_handle.readlines():
            line_isascii = self.is_ascii(line)
            if line_isascii:
                searchlines.append(line)

        print_till = -1
        keyw_log_limit = 0

        inc_keyw = {}
        for k, v in keywords.iteritems():
            for k1, v1 in v.iteritems():
                if k1 == 'include_in_search' and v1 == 1:
                    inc_keyw[k] = v

        sorted_keyword = sorted(inc_keyw.iteritems(),
                                key=lambda x: x[1]['weight'],
                                reverse=True)
        keyw_per_weight = [key[0] for key in sorted_keyword]

        # Iterate through the file and search for keywords
        for i, line in enumerate(searchlines):

            for keyw in keyw_per_weight:
                # If keyword is present then print it to report
                if re.search(keyw, line):
                    if keyw_log_limit <= keyword_log_limit:
                        if i > print_till:

                            for x in range(i - before, i):
                                self.report += searchlines[x]

                        print_till = i + after

                    # capture filename format
                    scriptfile = log_info['logformat']['filename']

                    # capture max. level of keywords to match
                    self.max_keywords_match = log_info['max_keywords_match']

                    # capture log level
                    self.log_levels = log_info['log_levels']

                    # capture limit of messages on bugzilla
                    self.keyword_log_limit = log_info['keyword_log_limit']

                    # remove the timestamp from line if present
                    if timestamp:
                        tmp_line = re.sub(timestamp, '', line)

                    # set the summary line
                    if not self.summary:
                        self.summary = "[auto-triage] Failure: %s" %\
                                            tmp_line

                    if keyw not in log_levels:
                        scriptfile = None
                        searchObj = re.search(keyw, tmp_line)

                        if searchObj:
                            tmp_line = searchObj.group()
                            keyw_log_limit += 1
                        else:
                            tmp_line = ""

                    # add file name in line to search keys,
                    # if format is given
                    # else add whole line to search keys.
                    if scriptfile:
                        tmp_line = re.findall(scriptfile, tmp_line)

                        if tmp_line:
                            tmp_line = keyw + " - \[\@" + tmp_line[0] + "\]"
                            keyw_log_limit += 1
                        else:
                            tmp_line = ""

                    if tmp_line and tmp_line not in self.search_keys:
                        self.search_keys.append(tmp_line)

                    break

            # erase report if errors were found in
            #  negative testing workload block
            if ((negative_key != None) and (re.search(negative_key, line))):
                self.report = ""
                self.summary = ""
                print_till = 0

            if i <= print_till:
                self.report += line

                if i == print_till:
                    self.report += ".\n.\n.\n"

            if failure_pattern:
                if re.search(failure_pattern, line):
                    self.report += line
                    failure_pattern_matched = True

        self.report += "\n"

        log_file_handle.close()

        # return description for bug only if failure_pattern
        # gets matched or is not specified
        if failure_pattern_matched or not failure_pattern:
            # Create the report file
            report_file = open(file_name.replace(".log", ".report"), 'w')
            report_file.write(self.report)
            report_file.close()
            logging.debug("%s created" % report_file.name)

            return self.report

        logging.debug("Failure pattern \"%s\" not matched" % failure_pattern)
        return ""

    def clear_search_keys(self):
        '''Clear the bugzilla serch keys'''
        self.search_keys = []
        self.summary = ""

    def get_search_keys(self):
        '''Return the bugzilla serach keys'''
        return self.search_keys

    def get_summary(self):
        '''Returns the summary line for bug'''
        return self.summary

    def get_max_keywords_match(self):
        '''Returns max. no of keywords to match from top keystring'''
        return self.max_keywords_match

    def is_ascii(self, line):
        '''Returns if the string is ascii'''
        try:
            return all(ord(c) < 128 for c in line)
        except TypeError:
            return False

    def workload_results(self, log_info, log_file_handle):
        workload_results_format = None
        workload_results_sort_type = None
        workload_results_num_times = 0

        if 'format' in log_info['workload_results'].keys():
            workload_results_format = log_info[
                                          'workload_results']['format']

        if 'sort_type' in log_info['workload_results'].keys():
            workload_results_sort_type = log_info[
                                             'workload_results']['sort_type']

        if 'num_times' in log_info['workload_results'].keys():
            workload_results_num_times = log_info[
                                             'workload_results']['num_times']

        log_read = log_file_handle.read()
        workload_results = []

        for match in re.findall(workload_results_format, log_read):
            workload_results.append(match[0])

        self.report += "\n"

        if workload_results:
            if workload_results_num_times == 1 and \
                   workload_results_sort_type == 'reverse':
                self.report += workload_results[(len(workload_results)-1)]
            elif workload_results_num_times == 1 and \
                    workload_results_sort_type == 'forward':
                self.report += workload_results[0]

            if workload_results_num_times > 1 and \
                    workload_results_sort_type == 'reverse':
                for workload_result in reversed(workload_results):
                    self.report += workload_result
                    self.report += "\n"
            elif workload_results_num_times > 1 and \
                    workload_results_sort_type == 'forward':
                for workload_result in workload_results:
                    self.report += workload_result
                    self.report += "\n"

        log_file_handle.seek(0)

    def parse(self, pattern, log_info, log_file_handle):
        if pattern == 'workload_results':
            self.workload_results(log_info, log_file_handle)

