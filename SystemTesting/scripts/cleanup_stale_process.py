#!/usr/bin/python

# **********************************************************
# Copyright 2014 VMware, Inc.  All rights reserved.
# **********************************************************

__author__ = "VMware, Inc."
#
# This scripts is used to clean up stale processes
#
from subprocess import Popen, PIPE, STDOUT
from optparse import OptionParser
import re
import sys
import time
import logging
import os
import utility

if __name__ == "__main__":
   usage = 'usage: %prog'
   parser = OptionParser(usage=usage)
   parser.add_option("--logdir", dest="logdir", action="store",
                     type="string", help="log directory")

   global cmdOpts
   (cmdOpts, args) = parser.parse_args()
   # Set the logging
   logDir = cmdOpts.logdir
   if not os.path.exists(logDir):
      os.mkdir(logDir)

   LOG_FORMAT = '%(asctime)s %(levelname)-8s %(message)s'
   logfile = cmdOpts.logdir + os.sep + 'cleanup_stale_processes.log'
   logging.basicConfig(filename=logfile, level=logging.DEBUG,
                       format=LOG_FORMAT,datefmt='%a, %d %b %Y %H:%M:%S')
   global logger
   logger = logging.getLogger('cleanup')

   # Get unique and sorted sid list without header
   cmd = 'ps x -o sid --sort=sid | uniq | sed -e 1d'
   (returncode, stdout, stderr) = utility.run_command_sync(cmd)
   if (returncode != 0):
      logger.error('Command %s returns error: %s' % (cmd, stderr))
      exit(1)
   sid_list = utility.split_string_to_list(stdout)
   if (len(sid_list) < 1):
      logger.error('Command %s returns nothing' % (cmd))
      exit(1)

   logger.debug('Session id list: %s' % (sid_list))

   for index in range(0, len(sid_list)):
      sid_list[index] = sid_list[index].strip()
      # Subprocess can not process multi layer grep well
      # Get vdNet process list for this session
      #
      # PR1308044 Do not use option 'e' because it will list the environment
      # of a process too. Checking environment for patterns
      # like ruby, java, zookeeper will result in false alarms
      # and cause those process to be killed.
      cmd = "ps f -o pid,sid,command -s %s | sed -e 1d " % sid_list[index]
      (returncode, stdout, stderr) = utility.run_command_sync(cmd)
      if (returncode != 0):
         logger.error('Command %s returns error: %s' % (cmd, stderr))
         logger.debug('returncode %s stdout %s' % (returncode,stdout))
         continue
      logger.debug('Process list for session %s is\n%s' %(sid_list[index],stdout))
      vdnet_process_list = utility.split_string_to_list(stdout)

      # If there is vdNet process in this session, continue
      # If not, kill zookeeper/InlineJava processes if exist
      if (utility.pattern_match_in_list(vdnet_process_list, "vdNet.pl") == 1):
         continue

      # Find if there is zookeeper/InlineJava processes in this session
      cmd = "ps f -o pid,sid,command -s %s" % sid_list[index]
      (returncode, stdout, stderr) = utility.run_command_sync(cmd)
      if (returncode != 0):
         logger.error('Command %s returns error %s: %s' % (cmd, returncode, stderr))
         continue
      vdnet_process_list = utility.split_string_to_list(stdout)
      stale_list = []
      for item in vdnet_process_list:
         # Discard grep process itself
         if re.search("grep", item):
            continue
         if re.search("zookeeper|InlineJava|ruby", item) == None:
            continue
         stale_list.append(item)

      if (len(stale_list) < 1):
         continue

      # If there is process, kill them
      logger.info('Following processes have been killed:')
      killed_process_data = ""
      for item in stale_list:
          process_data = item.split()
          cmd = "kill -9 %s" % (process_data[0])
          (returncode, stdout, stderr) = utility.run_command_sync(cmd)
          if (returncode != 0):
             logger.error('Command %s returns error %s: %s' %
                 (cmd, returncode, stderr))
             continue
          killed_process_data += item
      logger.info('%s\n' % killed_process_data)

   sys.exit(0)

