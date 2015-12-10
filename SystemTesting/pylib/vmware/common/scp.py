#!/usr/bin/python

import logging
import pexpect
import vmware.common.global_config as global_config

expectations = ['[Pp]assword',
                'continue (yes/no)?',
                pexpect.EOF,
                pexpect.TIMEOUT,
                'Name or service not known',
                'Permission denied',
                'No such file or directory',
                'No route to host',
                'Network is unreachable',
                'failure in name resolution',
                'No space left on device']


class SCP(object):
    def __init__(self, ip="", username="", password="",
                 source_file_path="", dest_file_path=""):
        self.ip = ip
        self.username = username
        self.password = password
        self.source_file_path = source_file_path
        self.dest_file_path = dest_file_path
        self.pylogger = global_config.pylogger
        if self.pylogger is None:
            func = global_config.configure_logger
            self.pylogger = func(log_prefix="SCP", stdout=True,
                                 log_level=logging.INFO,
                                 logfile_level=logging.DEBUG)

    def CopyFileSCP(self, child=None, timeout=30):
        try:
            if not child:
                child = pexpect.spawn('scp %s %s@%s:%s' %
                                      (self.source_file_path, self.username,
                                       self.ip, self.dest_file_path))
                child.timeout = timeout
            res = child.expect(expectations)
            self.pylogger.info("Child Exit Status : %s" % child.exitstatus)
            self.pylogger.info("%s,::%s, :After:%s" % (res, child.before,
                                                       child.after))
            if res == 0:
                child.sendline('%s' % self.password)
                return self.CopyFileSCP(child, timeout)
            elif res == 1:
                child.sendline('yes')
                return self.CopyFileSCP(child, timeout)
            elif res == 2:
                line = child.before
                self.pylogger.info("Line:%s" % line)
                return True
            elif res == 3:
                child.kill(0)
                return False
            elif res >= 4:
                child.kill(0)
                self.pylogger.error("ERROR:%s" % expectations[res])
                return False
            return True
        except:
            import traceback
            traceback.print_exc()
            self.pylogger.error("Copy for file %s failed with status %s"
                                % (self.source_file_path, child.exitstatus))
