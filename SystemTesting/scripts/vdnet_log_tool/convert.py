#!/usr/bin/env python
########################################################################
# Copyright (C) 2015 VMware, Inc.
# All Rights Reserved
########################################################################

import os, sys, re

import vmware.common.global_config as global_config

from htmlclass import HtmlMaker

pylogger = global_config.pylogger

HTML_SUFFIX = 'html'
LOCAL = 'local'
BASE_GROK_URL = ('https://opengrok.eng.vmware.com'
                '/source/xref/nsx-qe.git/vdnet/automation/')
PID_COLOR_LIST = [
                   'Aqua', 'Magenta', 'Maroon', 'Orange', 'Coral',
                   'Fuchsia','Lime', 'MediumSpringGreen', 'ForestGreen', 'Tomato',
                   'Chartreuse', 'Cyan', 'HotPink', 'GreenYellow', 'Red',
                   'DeepSkyBlue', 'DarkViolet', 'Green', 'LightSeaGreen'
                 ]


class LogConvert(object):

    def __init__(self, log_path, code_path, html_source):
        self.log_path = log_path
        self.log_dir = os.path.dirname(self.log_path)
        if not os.path.exists(self.log_path):
            pylogger.error("%s do not exist" % self.log_path)
            raise Exception("%s do not exist" % self.log_path)
        self.html_log_dir = os.path.join(self.log_dir, 'html')
        if not os.path.exists(self.html_log_dir):
            os.mkdir(self.html_log_dir)
        # renaming the "testcase.html" to "<TestCaseName>.html"
        # eg. "1_TDS.NSXTransformers.Edge.TestOrder.TestRouteRedistribution1.html"
        testcase_name = self.log_path.split(os.sep)[-2]
        testcase_html = '.'.join((testcase_name, HTML_SUFFIX))
        self.testcase_filename = os.path.join(self.html_log_dir, testcase_html)
        self.code_path= code_path
        self.base_url = BASE_GROK_URL
        self.html_source = html_source
        self.anchorInfo = dict()
        self.tag_dict = {  # tag:   (tag_color,   link_color)
                          'PASS':  ('Lime',      'white'),
                          'FAIL':  ('HotPink',   'white'),
                          'ABORT': ('Magenta',   'white'),
                          'FATAL': ('Fuchsia',   'white'),
                          'ERROR': ('OrangeRed', 'yellow'),
                          'WARN':  ('yellow',    'white'),
                          'INFO':  ('Aqua',      'white'),
                          'DEBUG': ('Pink',     'white'),
                          'TRACE': ('orange',    'white'),
                       }

    def process_logs(self):
        # processed data
        self.handle_data_tag()
        if self.html_source == LOCAL:
            self.process_cached_source_file()
        return self.testcase_filename

    def add_anchor_info(self, key, value):
        if key not in self.anchorInfo:
            self.anchorInfo[key] = set()
        self.anchorInfo[key].add(value)

    def get_anchor_info(self):
        return self.anchorInfo

    # Add tag for WARN INFO DEBUG TRACE color
    def handle_data_tag(self):
        if self.html_source == LOCAL:
            self.base_url = ''
        pattern = r'\[(.*)\].*\[@(.+:\d+)\]\s*\[(\d+)\]'
        # Write the data immediately instead of storing in a variable
        # to avoid the issue when processing huge log.
        # It can save the processed time from 38.6577670574 to 0.630407810211
        # when processing a 10M size log.
        hm = HtmlMaker(self.testcase_filename)
        hm.write_header()
        with open(self.log_path, 'r') as f:
            for eachline in f.readlines():
                eachline = self.chg_tag_color(pattern, eachline)
                hm.write_body(eachline)
        pass
        hm.write_footer()

    def chg_tag_color(self, pattern, eachline):
        result = ''
        d = re.search(pattern, eachline)
        if d:
            if d.group(1) in self.tag_dict.keys():
                tag = d.group(1)
                link_clue = d.group(2)
                pid_num = d.group(3)
                tag_color =  self.tag_dict[d.group(1)][0]
                link_color = self.tag_dict[d.group(1)][1]
                result = self.process_linker(tag, link_clue, pid_num, tag_color, link_color)
                rx = re.compile(pattern)
                eachline = rx.sub(result, eachline)
        return eachline

    # text example: VDNetLib::Workloads::WorkloadsManager:646
    def process_linker(self, tag, link_clue, pid_num, tag_color, link_color):
        result = ''
        html_suffix = ''
        pid_num = int(pid_num)
        pid_color_size = len(PID_COLOR_LIST)
        parts = link_clue.replace('::', '/')
        parts = parts.split(':')
        # VDNetLib/Workloads/WorkloadsManager
        file_key = parts[0]
        line_num = parts[1]  # 646
        if self.html_source == LOCAL:
            tag_line_num = (tag, line_num)
            self.add_anchor_info(file_key, tag_line_num)
            html_suffix = '.html'
        result = result + '<font style="background:%s">' % tag_color
        result = result + '[%-5s]</font> - ' % tag
        result = result + '<a href = \"%s%s.pm%s' % (self.base_url, file_key, html_suffix)
        result = result + '#%s\" target = "_blank">' % line_num
        result = result + '<font style="background:%s">' % link_color
        result = result + '[@%s]</font></a>' % link_clue
        result = result + '<font color=%s>' % PID_COLOR_LIST[pid_num%pid_color_size]
        result = result + ' [<b>%s</b>] </font>' % pid_num
        return result

    def process_cached_source_file(self):
        for file_key in self.anchorInfo.keys():
            # file_key : VDNetLib/Workloads/WorkloadsManager
            source_file_path =  os.path.join(self.code_path, file_key + '.pm')
            source_file_name = file_key.split(os.sep)[-1] + '.pm'
            relative_directory = os.sep.join(file_key.split(os.sep)[:-1])
            html_directory = os.path.join(self.html_log_dir, relative_directory)
            if not os.path.exists(html_directory):
                os.makedirs(html_directory)
            html_file_name = os.path.join(html_directory, source_file_name + '.html')
            self.process_cashed_data(file_key, source_file_path, html_file_name)
        pass

    def process_cashed_data(self, file_key, source_file_path, html_file_name):
        hm = HtmlMaker(html_file_name)
        hm.write_header()
        with open(source_file_path, 'r') as f:
            line_pos = 0
            for eachline in f.readlines():
                temp_data = ''
                line_pos = line_pos + 1
                # tag_line_num : (Debug, 646)
                found_flag = 'false'
                for tag_line_num in self.anchorInfo[file_key]:
                    if str(line_pos) == tag_line_num[-1]:
                        found_flag = 'true'
                        tag = tag_line_num[0]
                        tag_color = self.tag_dict[tag][0]
                        temp_data = temp_data + '<div id=%s></div>'% line_pos
                        temp_data = temp_data + '<font style="background:%s">'% tag_color
                        temp_data = temp_data + '%5d  %s</font>' % (line_pos, eachline)
                        break
                if found_flag == 'false':
                    temp_data = temp_data + '%5d  %s' % (line_pos, eachline)
                hm.write_body(temp_data)
        hm.write_footer()
        pass
