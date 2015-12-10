#!/usr/bin/env python
########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

import os

import vmware.common.global_config as global_config

pylogger = global_config.pylogger

TITLE = 'VDNet Log Viewer'


class HtmlMaker(object):
    def __init__(self, output_file, body_data = ''):
        self.body_data = body_data
        self.fo = open(output_file, 'w')

    def write_header(self):
        title = '<title>%s</title>\n' % TITLE
        body_header = '<body>\n<pre>\n'
        self.fo.write('<html>\n')
        self.fo.write('<head>\n')
        self.fo.write(title)
        self.fo.write('</head>\n')
        self.fo.write(body_header)

    def write_body(self, data):
        self.fo.write(data)

    def write_footer(self):
        body_footer = '</pre>\n</body>\n'
        self.fo.write(body_footer)
        self.fo.write('</html>\n')
        self.fo.close()

    def produce_html(self):
        self.title = '<title>%s</title>\n' % TITLE
        body_data = '<body>\n<pre>\n%s' % self.body_data
        body_data = self.body + '</pre>\n</body>\n'
        with open(self.out_put, 'w') as fo:
            fo.write('<html>\n')
            fo.write('<head>\n')
            fo.write(self.title)
            fo.write('</head>\n')
            fo.write(self.body)
            fo.write('</html>\n')
            fo.close()
