#!/usr/bin/python

# **********************************************************
# Copyright 2014 VMware, Inc.  All rights reserved.
# **********************************************************

__author__ = "VMware, Inc."

import os
import sys
import time
import shutil
from optparse import OptionParser
from subprocess import Popen, PIPE

if 'VMBLD' not in os.environ:
   raise Exception('please set up $VMBLD environment variable.')
if 'VMTREE' not in os.environ:
   raise Exception('please set up $VMTREE environment variable.')
if 'CODE_COVERAGE' not in os.environ:
   raise Exception('$CODE_COVERAGE variable is not configured properly.')

VMBLD = os.environ['VMBLD']
VMTREE = os.environ['VMTREE']
COVERAGE_TYPE = os.environ['CODE_COVERAGE']

TMP_DIR = '/tmp'
DATA_REPOS = '/vmfs/volumes/dbc'

class ShellUtil:
   """Class of shell utility functions.
   """

   @classmethod
   def run_command(cls, command, returnObject=False):
      """ function to run command on the host

      @param command: command to be executed
      @param returnObject: boolean to indicate whether should be executed
      asynchrnously and return process handle or not
      @return process returncode, stdout, stderr if returnObject=False
      otherwise, process handle is returned
      """
      print ('Executing command %s' % command)
      p = None
      if returnObject:
          p = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
      else:
          p = Popen(command, shell=True, stdout=PIPE, stderr=PIPE)
          stdout, stderr = p.communicate()
          print ('returncode: %s' % p.returncode)
          print ('stdout : %s' % stdout)
          print ('stderr : %s' % stderr)
          return (p.returncode, stdout, stderr)
      return p

   @classmethod
   def create_dir(cls, dirname):
      """Create a directory.

      @param dirname: directory name
      @return None
      """
      if not os.path.isdir(dirname):
         os.makedirs(dirname, 0755)

   @classmethod
   def copy_file(cls, src_file, dst_file):
      """Copy a file or directory to the destination.

      @param src_file: source file
      @param dst_file: destination file
      @return None
      """
      if os.path.isdir(src_file):
         shutil.copytree(src_file, dst_file)
      else:
         shutil.copy2(src_file, dst_file)

   @classmethod
   def delete_file(cls, file):
      """Remove a file or directory from file system.

      @param file: file to be deleted
      @return None
      """
      if os.path.isdir(file):
         shutil.rmtree(file)
      else:
         os.remove(file)

def upload_data_package(data_package):
   """Upload data package to depository.

   @param data_package: coverage data package
   @return: None
   """
   if not os.path.exists(data_package):
      raise Exception('snapshot data file does not exist.')

   print 'uploading data package to depository..'
   target_package = os.path.join(DATA_REPOS,
                                 os.path.basename(data_package))
   ShellUtil.copy_file(data_package, target_package)

def upload_src_package(name_prefix):
   """Upload source package to depository.

   @param name_prefix: prefix of src folder
   @return None
   """
   src_dir = os.path.join(VMTREE,'build/esx/%s/coverage-src' % VMBLD)
   target_dir_name = '%s_src' % name_prefix
   target_dir = os.path.join(DATA_REPOS, target_dir_name)
   if not os.path.exists(target_dir):
      cmd = 'mkdir -p %s' % target_dir
      ShellUtil.run_command(cmd)
   if not os.path.isdir(target_dir):
      print 'uploading source package to depository..'
      ShellUtil.copy_file(src_dir, target_dir)

def generate_data_package(name_prefix):
   """Generate pacakge for current coverage data.

   @param name_prefix: prefix of coverage data package name
   @return package: coverage data package generated
   """
   data_package_name = '%s.tar.gz' % name_prefix
   data_package = os.path.join('/tmp', data_package_name)

   # Build up arguments for coverage.py.
   options = ['--work-in-package', 'work',
              '--publish-package', data_package]
   if ('vmk' == COVERAGE_TYPE):
      options.append('--snapshot-vmk-data')
   elif ('monitor' == COVERAGE_TYPE):
      options.extend(['--snapshot-vmm-data', 'data'])
   elif ('vmx' == COVERAGE_TYPE or 'hostd' == COVERAGE_TYPE):
      options.extend(['--snapshot-%s-data' % COVERAGE_TYPE, 'data'])
   else:
      raise Exception('invalid coverage type.')

   print 'producing coverage package, which may take a few minutes..'
   cmd = [os.path.join(VMTREE, 'support/scripts/coverage/coverage.py')]
   cmd.extend(options)
   ShellUtil.run_command(' '.join(cmd))

   return data_package

def cleanup(data_package):
   """Clean up snapshot data package and data directory.

   @param data_package: coverage data package
   @return: None
   """
   if os.path.exists(data_package):
      ShellUtil.delete_file(data_package)

if __name__ == '__main__':
   usage = 'usage: %prog [options]'
   parser = OptionParser(usage=usage)
   parser.add_option('--launcher', dest='launcher_ip', action='store',
                     type='string', help='IP address of launcher/master controller')
   global options
   (options, args) = parser.parse_args()
   if options.launcher_ip == None:
      options.launcher_ip = 'unknownLauncher'
   name_prefix = '%s_%s_%s' % (COVERAGE_TYPE, options.launcher_ip, time.strftime('%Y%m%d_%H%M%S'))
   data_package = generate_data_package(name_prefix)
   upload_data_package(data_package)
   upload_src_package(name_prefix)
   cleanup(data_package)

