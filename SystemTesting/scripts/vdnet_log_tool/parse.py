#!/usr/bin/env python
########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

import argparse

import vmware.common.global_config as global_config

pylogger = global_config.pylogger

DEFAULT_TESTCASE_NAME = './test.log'
DEFAULT_CODE_PATH = '/build/trees/vdnet/main/automation/'
DEFAULT_HTML_SOURCE = 'opengrok.eng.vmware.com'
DEFAULT_HTML_PUBLISHED_DIR = 'none'
LOG_PATH_HELP_INFO = 'the path of testcase log to be processed'
CODE_PATH_HELP_INFO = 'the vdnet source code automation directory'
HTML_SOURCE_HELP_INFO = (
                  'Option to define the source file location which the error link jumps to. '
                  ' The default value is opengrok.eng.vmware.com.'
                  ' If defined as \'local\', the error link will jump to the cached'
                  ' html files in the html directory.')
HTML_PUBLISHED_DIR_HELP_INFO = (
                  'Option to specfiy the folder which the html files publish to. '
                  ' if this option defined as \'default\', it will find  '
                  ' dbc/home directory of the user as the html published directory. ')


class Parser():

    def __init__(self):
        self._args = None
        self.parser = argparse.ArgumentParser()
        self.parser.add_argument('-l', '--log_path', default = DEFAULT_TESTCASE_NAME,
                                 help = LOG_PATH_HELP_INFO)
        self.parser.add_argument('-p', '--code_path', default = DEFAULT_CODE_PATH,
                                 help = CODE_PATH_HELP_INFO)
        self.parser.add_argument('-s', '--html_source', default = DEFAULT_HTML_SOURCE,
                                 help = HTML_SOURCE_HELP_INFO)
        self.parser.add_argument('-d', '--html_published_dir', default = DEFAULT_HTML_PUBLISHED_DIR,
                                 help = HTML_PUBLISHED_DIR_HELP_INFO)

    @property
    def args(self):
        self._args = self.parser.parse_args()
        return self._args
