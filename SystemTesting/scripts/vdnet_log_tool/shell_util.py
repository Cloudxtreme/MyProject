#!/usr/bin/env python
import os
from subprocess import Popen, PIPE
from datetime import datetime
import vmware.common.global_config as global_config

pylogger = global_config.pylogger

DBC_FINDUSER_BIN = '/build/apps/machines/bin/dbc-finduser'
GET_LOG_NAME_CMD = 'echo $LOGNAME'
GET_HOME_DIR_CMD = 'echo $HOME'
PROCESSED_LOG_DIR_NAME = 'vdnet_processed_logs'
BASE_GROK_URL = ('https://opengrok.eng.vmware.com'
                 '/source/xref/nsx-qe.git/vdnet/automation/')
CAT_SERVER_URL = 'https://cat.eng.vmware.com'
CAT_WDC_SERVER_URL = 'https://cat-wdc-services.eng.vmware.com'
HOME_SERVER_URL = 'http://engweb.eng.vmware.com/'
PUBLIC_HTML = 'public_html'
LOG_URL_POINT = 'Processed testcase log url:'
CAT_STORAGE_PREFIX = ('/PA', '/WDC')
CAT_STORAGE_WDC_PREFIX = ('/WDC')
DBC_STORAGE_PREFIX = ('/dbc')
HOME_STORAGE_PREFIX = ('/mts')


class ShellUtil(object):

    def __init__(self):
        self.log_name = ''

    '''
    Get the dbc directory of the log on user.
    If the user does not have dbc, return 'none'
    If the user have one dbc, return the (dbc direcroy, dbc server name)
    If the user have multi dbcs, retrun the first item.
    '''
    def get_dbc_directory(self):
        log_name = self.get_log_name()
        command = DBC_FINDUSER_BIN + ' ' + log_name
        msg = 'Waiting for get the dbc directory of %s,'% log_name
        msg += ' this process may be slow and last for several minutes. '
        msg += ' Had better defined html_published_dir with '
        msg += ' your dbc or home directory in deploy yaml file.\n'
        pylogger.warn(msg)
        (rt_code, stdout, stderr) = self.run_command(command)
        if not rt_code:
            cmd_out = stdout.rstrip()
            if cmd_out:
                dbc_items = stdout.rstrip().splitlines()
                # use the first dbc item
                dbc_item = dbc_items[0]
                # dbc_item sample:
                # /dbc/pek2-dbc201/haichaom on pek2-dbc201
                dbc_directory = dbc_item.split(' on ')[0]
                dbc_server_name =  dbc_item.split(' on ')[1]
                return (dbc_directory, dbc_server_name)

    def get_home_directory(self):
        command =  GET_HOME_DIR_CMD
        (rt_code, stdout, stderr) = self.run_command(command)
        if not rt_code:
            return stdout.rstrip()

    def generate_result_directory(self, base_directory, testcase_file_name):
        testcase_name = testcase_file_name.split(os.sep)[-3]
        date_time_now = datetime.now().strftime("%Y%m%d-%H%M%S")
        result_directory_name = os.path.join(base_directory, PROCESSED_LOG_DIR_NAME,
                               date_time_now, testcase_name)
        if not os.path.exists(result_directory_name):
            try:
                os.makedirs(result_directory_name)
            except:
                 pylogger.error("Please chmod the directory: " + os.path.join(base_directory,
                                PROCESSED_LOG_DIR_NAME) + " to have the write ablity")
                 raise
        return result_directory_name

    def transfer_results_location(self, src_log_html_dir, dst_log_dir):
        if os.path.exists(src_log_html_dir):
            command = 'cp -r ' + src_log_html_dir + ' ' + dst_log_dir
            self.run_command(command)

    def get_log_name(self):
        command = GET_LOG_NAME_CMD
        (rt_code, stdout, stderr) = self.run_command(command)
        if not rt_code:
            return stdout.rstrip()

    def run_command(self, command):
        p = None
        p = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
        stdout, stderr = p.communicate()
        return (p.returncode, stdout, stderr)

    def display_processed_log_link(self, shared_html_filename):
        if shared_html_filename.startswith(CAT_STORAGE_PREFIX):
            if shared_html_filename.startswith(CAT_STORAGE_WDC_PREFIX):
                CAT_file_url =  CAT_WDC_SERVER_URL + shared_html_filename
            else:
                CAT_file_url =  CAT_SERVER_URL + shared_html_filename
            pylogger.info("%s\n  %s  \n " % (LOG_URL_POINT, CAT_file_url))
        elif shared_html_filename.startswith(DBC_STORAGE_PREFIX):
            # ex, testcase_filename:
            #     /dbc/pa-dbc1123/haichaom/vdnetlogs/XXXX/testcase.html
            # ex, dbc_site_name: pa-dbc1123
            dbc_site_name = shared_html_filename.split(os.sep)[2]
            # ex, dbc_file_name: /haichaom/vdnetlogs/XXXX/testcase.html
            dbc_file_name = shared_html_filename.split(dbc_site_name)[1]
            dbc_file_url = " http://" + dbc_site_name + dbc_file_name
            pylogger.info("%s\n %s \n " % (LOG_URL_POINT, dbc_file_url))
        elif shared_html_filename.startswith(HOME_STORAGE_PREFIX):
            # ex, /mts/home3/haichaom/public_html/vdnetlogs/.../testcase.html
            user_name = shared_html_filename.split(os.sep)[3]
            home_file_name = shared_html_filename.split(PUBLIC_HTML)[1]
            home_file_url = HOME_SERVER_URL + '~' + user_name + home_file_name
            pylogger.info("%s\n %s \n " % (LOG_URL_POINT, home_file_url))
        else:
            html_dir_path = os.path.dirname(shared_html_filename)
            msg = "%s did not in a storage that"% shared_html_filename
            msg = msg + 'can be accessed through web, so you need publish the '
            msg = msg + 'follow html folder to a web access storage:\n %s'% html_dir_path
            pylogger.warn(msg)

if __name__ == '__main__':
    sh = ShellUtil()
