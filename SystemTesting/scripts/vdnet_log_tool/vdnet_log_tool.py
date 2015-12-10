#!/usr/bin/env python
########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

import os
from time import time
from subprocess import Popen, PIPE

import vmware.common.global_config as global_config

from parse import Parser
from convert import LogConvert
from shell_util import ShellUtil

pylogger = global_config.pylogger

PUBLIC_HTML = 'public_html'
HTML = 'html'
FALSE = 'false'
TRUE = 'true'
HTML_PUBLISHED_DEFAULT = 'default'
SHARED_STORAGE_PREFIX = ('/PA', '/WDC', '/dbc', '/mts')


def main():
    t1 = time()
    parser = Parser()
    log_path = parser.args.log_path
    code_path = parser.args.code_path
    html_source = parser.args.html_source
    html_published_dir = parser.args.html_published_dir
    log_path_dir = os.path.join(os.path.dirname(log_path), HTML)
    # Prepare to process the log files
    log_converter = LogConvert(log_path, code_path, html_source)
    # Process different log level info with different display formats
    testcase_html_name = log_converter.process_logs()
    pylogger.info("processed html file: %s" % testcase_html_name)

    sh = ShellUtil()
    base_directory = ''
    # if user defined the shared log dir, then copy processed files to it.
    if html_published_dir.startswith(SHARED_STORAGE_PREFIX):
        base_directory = html_published_dir
    elif html_published_dir == HTML_PUBLISHED_DEFAULT:
         dbc_directory = sh.get_dbc_directory()
         # if dbc is not available then get user's home dir.
         if dbc_directory is not None:
              base_directory = dbc_directory[0]
         else:
              home_directory = sh.get_home_directory()
              base_directory = os.path.join(home_directory, PUBLIC_HTML)
    else:
        base_directory = log_path_dir

    # Copy processed files if needed.
    if base_directory != log_path_dir:
       dst_result_directory = sh.generate_result_directory(
                              base_directory, testcase_html_name)
       sh.transfer_results_location(log_path_dir, dst_result_directory)
       testcase_html = testcase_html_name.split(os.sep)[-1]
       testcase_html_name = os.path.join(dst_result_directory,
                                         HTML, testcase_html)

    # Display the processed log url that can be access from web.
    sh.display_processed_log_link(testcase_html_name)

    t2 = time()
    pylogger.info("Processed log time: " + str(t2 - t1) + " seconds")

if __name__ == '__main__':
    main()
