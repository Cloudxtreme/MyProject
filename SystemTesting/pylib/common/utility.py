#!/usr/bin/python

# **********************************************************
# Copyright 2014 VMware, Inc.  All rights reserved.
# **********************************************************

__author__ = "VMware, Inc."
#
# This file is for common python utilities
#
from subprocess import Popen, PIPE, STDOUT
import re
import sys
import time
import os

def run_command_sync(command):
   """ Routine to run command in sync mode
   @param command: command to run
   @param stdout: file handle for stdout
   @param stderr: file handle for stderr
   @return tuple: (returncode, stdout, stderr)
   """
   p = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
   stdout, stderr = p.communicate()
   return (p.returncode, stdout, stderr)

def split_string_to_list(stdout):
   """ Routine to split a multiple lines string to a list
   each list item will contain one line
   @param stdout: string to split
   @return allLines: list with all lines
   """
   stdout = stdout.rstrip('\n')
   allLines = []
   allLines = stdout.split('\n')
   return allLines

def pattern_match_in_list(pList, pattern):
   """ Routine to search pattern in a list
   @param pList: list to operate on
   @param pattern: pattern searched
   @return isMatch: indicate if pattern found
   """
   isMatch = 0
   for item in pList:
      if re.search(pattern, item):
         return 1
   return isMatch

