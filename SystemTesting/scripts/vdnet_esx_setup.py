#!/usr/bin/python

# **********************************************************
# Copyright 2014 VMware, Inc.  All rights reserved.
# **********************************************************

__author__ = "VMware, Inc."
#
# This scripts is used to configure ESX host
# to run vdnet tests
#
from subprocess import Popen, PIPE
from optparse import OptionParser
import re
import sys
import time
import logging
import os

STAF_TOOLCHAIN = "/vmfs/volumes/build-toolchain.eng.vmware.com_0/lin32/staf-3.4.1"
STAF_MOUNTPOINT='stafmirror'
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
   def run_command_list(cls, command_list):
      """ function to run commands on the host

      @param command_list: list of commands to be executed
      @return None
      """
      length = len(command_list)
      for y in range(0,length):
         (output, stdout, stderr) = ShellUtil.run_command(command_list[y])

   @classmethod
   def grep_file(cls, filename, pattern):
      """Search if the given file contains pattern string.

      @param filename: the file to be searched
      @param pattern: the pattern used to search file
      @return boolean if file content matches pattern
      """
      found = False
      file = open(filename)
      try:
         for line in file:
            if pattern in line:
               found = True
               break
      finally:
         file.close()

      return found

   @classmethod
   def update_file(cls, filename, update_dict):
      """Update the file with given update_dict.

      @param filename: the name of file to be updated
      @param update_dict: the key is line tag indicates
      which line should be updated with the value of the
      key. If the key can't be found in the file, add
      the value to the end of the file directly.
      @return None
      """
      #read original lines from file
      file = open(filename, 'r')
      try:
         old_lines = file.readlines()
      finally:
         file.close()
      new_lines = []
      find = False
      #updated_keys contains keys have found in file
      updated_keys = []

      #handle lines one by one
      for line in old_lines:
          # check if the line contains any line tag
          for key in update_dict.keys():
             if key in line:
                find = True
                new_lines.append(update_dict[key])
                new_lines.append('\n')
                updated_keys.append(key)
                break
          if find == False:
             new_lines.append(line)

      #Add left values to end of file directly
      for key in update_dict.keys():
         if key not in updated_keys:
            new_lines.append(update_dict[key])
            new_lines.append('\n')

      #write updated content to file
      file = open(filename, 'w')
      try:
         file.writelines(new_lines)
      finally:
         file.close()

class BuildInfo:
   """Class for managing ESXi build information (i.e. build number ,etc.).
   """
   #TODO: will merge this class in to build_utilities.py
   #Not do this now because there are many modules missing
   #in python of esx which needed by build_utilities.py
   #And when we call this script, python on toolchain is not
   #ready yet.
   def __init__(self):
      """Create an instance of BuildInfo class.
      """

      self._bldnum = None
      self._vmtree = None
      self._bldtree = None
      self._bldtype = None

      file = open('/etc/vmware/.buildInfo')
      for line in file:
         line = line.strip()
         if line.startswith('VMTREE'):
            self._vmtree = line.replace('VMTREE:', '')
         elif line.startswith('BUILDNUMBER'):
            self._bldnum = line.replace('BUILDNUMBER:', '')
         elif line.startswith('VMBLD'):
            self._bldtype = line.replace('VMBLD:', '')
      file.close()

   def get_vmtree(self):
      """Returns ESXi's VMTREE.
      """
      return self._vmtree

   def get_buildnumber(self):
      """Returns ESXi's build number.
      """
      return self._bldnum

   def get_buildtype(self):
      """Returns ESXi's build type.
      """
      return self._bldtype

   def _parse_buildtree(self):
      """Parse build tree of the ESXi host.
      """
      print 'Loading build tree information, which may take a few minutes..'

      # Disable firewall temporarily
      cmd = 'esxcli network firewall get | awk \'/Enabled/ {print $2}\''
      (output, stdout, stderr) = ShellUtil.run_command(cmd)
      firewall_status = stdout
      if firewall_status != "false":
         cmd = 'esxcli network firewall set --enabled=false'
         ShellUtil.run_command(cmd)

      # Look up build tree.
      kind = self.get_vmtree().split('/')[4][:2]
      if kind != 'sb':   # Sandbox build or official build
         kind = 'ob'
      cmd = '/apps/bin/bld -k %s tree %s' % (kind, self.get_buildnumber())
      (output, stdout, stderr) = ShellUtil.run_command(cmd)
      build_tree = stdout
      self._bldtree = build_tree.strip()

      # Restore firewall settings.
      if firewall_status != 'false':
         cmd = 'esxcli network firewall set --enabled=true'
         ShellUtil.run_command(cmd)

   def get_buildtree(self):
      """Returns ESXi's build tree.
      """
      if not self._bldtree:
         self._parse_buildtree()

      return self._bldtree


def find_datastore(mount_point, share, server):
   """ function to find if the given mount point/datastore exists

   @param mount_point: name of datastore/mount point on ESX
   @param share: name of the share from the nfs server
   @param server: ip of the NFS server
   @first return value 0 if mount_point exists, 1 if does not exist, 2 if exists with
   different configuration
   @second return value for current mount point
   """
   command = "esxcli storage nfs list | grep \"" + share + "\""
   (output, stdout, stderr) = ShellUtil.run_command(command)
   nfs_list = stdout.rstrip()
   if not nfs_list:
      # PR 1222875: if different share use same mount point, search with
      # share returns blank. Then we search with mount point again to check
      # if it is mounted to another server or share
      command =  "esxcli storage nfs list | grep \"" + mount_point + "\""
      (output, stdout, stderr) = ShellUtil.run_command(command)
      mount_list = stdout.rstrip()
      mount_list = mount_list.split('\n')
      for item in mount_list:
         if (item.startswith(mount_point) == True):
            nfs_list = item
            break
      if not nfs_list:
         print ('%s is not mounted' % mount_point)
         return (1, None)
   command = 'echo %s | awk \'{print $1}\'' % nfs_list
   (output, stdout, stderr) = ShellUtil.run_command(command)
   stdout = stdout.rstrip()
   if stdout != mount_point:
      print ('Expected mount point %s while it is mounted as %s' % (mount_point, stdout))
      return (2, stdout)
   command = 'echo %s | awk \'{print $2}\'' % nfs_list
   (output, stdout, stderr) = ShellUtil.run_command(command)
   stdout = stdout.rstrip()
   if stdout != server:
      print ('%s is not on desired server %s' % (mount_point, server))
      return (2, mount_point)
   command = 'echo %s | awk \'{print $3}\'' % nfs_list
   (output, stdout, stderr) = ShellUtil.run_command(command)
   stdout = stdout.rstrip()
   if stdout != share:
      print ('%s is not mounted to desired share %s' % (mount_point, share))
      return (2, mount_point)
   command = 'echo %s | awk \'{print $4}\'' % nfs_list
   (output, stdout, stderr) = ShellUtil.run_command(command)
   stdout = stdout.rstrip()
   if stdout.lower() != 'true':
      print ('%s is not available on desired server %s' % (mount_point, server))
      return (2, mount_point)
   return (0, mount_point)

def add_datastore(mount_point, share, server, read_only=1):
   """ function to add the given nfs server

   @param mount_point: name of datastore/mount point on ESX
   @param share: name of the share from the nfs server
   @param server: ip of the NFS server
   @return 0 if nfs server mounted successfully, 1 in case of error
   """

   command = "esxcli storage nfs add -v %s -H %s -s %s" % (mount_point, server, share)
   if read_only:
       command = "%s -r" % command

   (output, stdout, stderr) = ShellUtil.run_command(command)
   if not stdout :
       return 1
   else :
       return 0

def remove_datastore(mount_point) :
   """ function to remove the given mount point/ nfs datastore

   @param mount_point: name of the nfs datastore
   @return 0 if datastore removed successfully, 1 in case of error
   """
   command = "esxcli storage nfs remove -v " + mount_point + \
      "| grep \"Error: Unknown command or namespace storage nfs remove\""
   (output, stdout, stderr) = ShellUtil.run_command(command)
   if not stdout:
       return 0
   else :
       return 1


def set_hostname():
   """ function to install staf on ESX

   @param None
   @return None
   """
   (output, stdout, stderr) = ShellUtil.run_command("esxcli system hostname \
                              get")
   print "The out of get hostname:%s " %output
   host_name = stdout.split("Host Name: ",1)[1]
   print "The hostname is:%s " %host_name
   host_name = host_name.strip()
   if host_name.isdigit():
      (output, stdout, stderr) = ShellUtil.run_command("esxcli system \
                                 hostname set --host=vdnet-assigned")
      (output, stdout, stderr) = ShellUtil.run_command("esxcli system \
                                 hostname get")
      print "After fix, host name is: %s" %stdout


def install_staf():
   """ function to install staf on ESX

   @param None
   @return None
   """
   print "install staf on host"
   (output, stdout, stderr) = ShellUtil.run_command("staf local ping ping")
   if not re.search('PONG', stdout):
      if os.path.exists('/vmfs/volumes/%s' % STAF_MOUNTPOINT):
         stafdir = '/vmfs/volumes/%s' % STAF_MOUNTPOINT
      else:
         stafdir = STAF_TOOLCHAIN

      paths = {'%s/bin/STAFProc' % stafdir: '/bin/STAFProc',
               '%s/bin/STAF' % stafdir: '/bin/staf',
               '%s/lib/libSTAF.so' % stafdir: '/lib/libSTAF.so',
               '%s/codepage' % stafdir: '/usr/local/staf',
               '%s/lib/libssl.so.0.9.8k' % stafdir: '/lib/libssl.so.0.9.8',
               '%s/lib/libcrypto.so.0.9.8k' % stafdir: '/lib/libcrypto.so.0.9.8',
               '%s/lib/libSTAFLIPC.so' % stafdir: '/lib/libSTAFLIPC.so',
               '%s/lib/libSTAFTCP.so' % stafdir: '/lib/libSTAFTCP.so',
               '%s/lib/libSTAFDSLS.so' % stafdir: '/lib/libSTAFDSLS.so',
               '%s/lib/libJSTAF.so' % stafdir: '/lib/libJSTAF.so'
               }
      ShellUtil.run_command('mkdir -p /usr/local/staf')
      STAF_cfg = (
            '# Turn on tracing of internal errors and deprecated options\n'
            'trace enable tracepoints "error deprecated"\n'
            '# Enable TCP/IP connections\n'
            'interface tcp library STAFTCP\n'
            '# Set default local trust\n'
            'trust machine *://* level 5\n'
            '# Add default service loader\n'
            'serviceloader library STAFDSLS'
            )
      ShellUtil.run_command('echo -e "' + STAF_cfg + '">/bin/STAF.cfg')
      for src in paths:
         ShellUtil.run_command(''.join(('ln -sf ', src, ' ', paths[src])))
      # make sure all files are correct linked. Just for debug
      ShellUtil.run_command('ls -l ' + ' '.join(paths.values()))
      ShellUtil.run_command("setsid /bin/STAFProc", True)
      (output, stdout, stderr) = ShellUtil.run_command("staf local ping ping")
      retry = 5
      while (retry and not re.search('PONG', stdout)):
         (output, stdout, stderr) = ShellUtil.run_command("staf local ping ping")
         time.sleep(2)
         retry -= 1

def mount_nfs(mount_list):
   """ function to mount nfs datastores in given list

   @param mount_list: list of nfs datastores
   @return None
   """
   for key in mount_list.keys():
      add_flag = 0
      if (mount_list[key] == None or mount_list[key] == 'none'):
         print 'user did not wish to mount %s' %key
         continue
      server, share = mount_list[key].split(':')
      return_val, existing_mountpoint = find_datastore(key, share, server)
      if return_val == 2 :
         return_val_remove  = remove_datastore(existing_mountpoint)
         if return_val_remove == 1:
            print 'failed to remove datastore %s \n' % existing_mountpoint
            sys.exit(1)
         else:
            return_val = 1
      if return_val == 1:
         read_only = 1
         if key == 'vdnetSharedStorage':
            read_only = 0
         add_datastore(key, share, server, read_only)
         add_flag = 1
      if add_flag == 1 :
         return_val, new_mountpoint = find_datastore(key, share, server)
      if return_val != 0 :
         print 'failed to add datastore %s \n' % key
         sys.exit(return_val)

def setup_buildtree(bld_info):
   """Set up $BUILDTREE environment variable.

   @param bld_info: build information
   @return None
   """
   #build_tree = '/build/storage60/release/bora-1677196'
   build_tree = bld_info.get_buildtree()
   if not os.path.exists(build_tree):
      print 'Setting up build tree (%s)..' % build_tree
      storage_server = build_tree.split('/')[2]
      build_server = 'build-%s.eng.vmware.com:/%s' %(storage_server, storage_server)
      mount_list = {storage_server: build_server}
      mount_nfs(mount_list)
      command = 'ln -sf /vmfs/volumes/%s  /build/%s' %(storage_server, storage_server)
      ShellUtil.run_command(command)
      if not os.path.exists(build_tree):
         raise Exception('failed to set up build tree')

def setup_vmtree(bld_info):
   """Set up $VMTREE environment variable.

   @param bld_info: build information
   @return None
   """

   if (('VMTREE' not in os.environ) or
      (('VMTREE' in os.environ) and
      (os.environ['VMTREE'] != bld_info.get_vmtree()))):
      os.environ['VMTREE'] = bld_info.get_vmtree()
      update_dict = {'VMTREE': 'export VMTREE=%s' % os.environ['VMTREE']}
      ShellUtil.update_file('/etc/profile.local', update_dict)
      #Also update /root/.profile to avoid the variables being overwriten
      ShellUtil.update_file(os.path.expanduser('~/.profile'), update_dict)

   if os.path.exists(os.environ['VMTREE']):
      print 'VMTREE was already configured. Skip it.'
   else:
      # Set up build tree at first
      setup_buildtree(bld_info)

      print 'Setting up VMTREE (%s)..' % os.environ['VMTREE']
      # Make /build/mts/release pointing to /vmfs/volumes/ob/release
      cmds = ['mkdir -p /build/mts/',
              'ln -sf /vmfs/volumes/ob/release /build/mts/release']
      ShellUtil.run_command_list(cmds)

      if not os.path.exists(os.environ['VMTREE']):
         raise Exception("failed to set up VMTREE")

def enable_coverage(code_coverage_type):
   """Enable code coverage.
   @param code_coverage_type: code coverage target type
   @return None
   """

   cov_root_dir = '/coverage'

   if os.path.isdir(cov_root_dir):
      print 'Code coverage was already enabled. Skip it.'
      return

   print 'Enabling %s code coverage..' % code_coverage_type
   #generate options for coverage.py
   options = ['--init-package', 'work']
   coverage_type_list = ['vmk', 'vmx', 'monitor', 'hostd']
   if ('vmk' == code_coverage_type):
      options.extend(['--enable-%s-coverage' % code_coverage_type])
   elif (code_coverage_type in coverage_type_list):
      options.extend(['--enable-%s-coverage' % code_coverage_type, 'data'])
   else:
      raise Exception('invalid coverage type.')

   #get path of coverage.py
   cmd = [os.path.join(os.environ['VMTREE'],
                       'support/scripts/coverage/coverage.py')]
   cmd.extend(options)
   #run coverage.py to enable code coverage with target type
   ShellUtil.run_command(' '.join(cmd))

   if not os.path.isdir(cov_root_dir):
      print 'Please check if ESX build is instrument build. For more info, \
             refer to https://wiki.eng.vmware.com/VMkernelTestDev/CodeCoverage'
      raise Exception('failed to enable %s code coverage.' % code_coverage_type)

def set_env_for_nsx_logging(log_level):

   """Set NSX_LOG_LEVEL ENV variable to log at DEBUG
   @param log_level
   @return None
   """
   command_list = ['mkdir ~/.ssh','echo ''NSX_LOG_LEVEL=VERBOSE'' >> ~/.ssh/environment']
   ShellUtil.run_command_list(command_list)
   update_dict = {'LOGLEVEL':'PermitUserEnvironment yes'}
   ShellUtil.update_file('/etc/ssh/sshd_config', update_dict)
   update_env_dict = {'LOGLEVEL':'export NSX_LOG_LEVEL=%s' % log_level}
   ShellUtil.update_file('/etc/profile.local', update_env_dict)
   ShellUtil.run_command('source /etc/profile.local')

if __name__ == "__main__":
   usage = 'usage: %prog [options]'
   parser = OptionParser(usage=usage)
   parser.add_option('--toolchain', dest='toolchain', action='store',
                     default='build-toolchain.eng.vmware.com:/toolchain',
                     type='string', help='Toolchain server and share')
   parser.add_option('--staf', dest='staf', action='store',
                     type="string", help="STAF Installation server and share")
   parser.add_option('--vdnet', dest='vdnet', action='store',
                     type='string', help='VDNet source server and share')
   parser.add_option('--vmrepository', dest='vm_repository', action='store',
                     type='string', help='VM repository/server and share')
   parser.add_option('--sharedstorage', dest='shared_storage', action='store',
                     type="string", help="Shared storage and share")
   parser.add_option('--codecoveragetype', dest='code_coverage_type', action='store',
                     type='string', help='Specify coverage type: vmk/vmx/monitor/hostd')
   parser.add_option('--coveragedatarepo', dest='coverage_data_repos', action='store',
                     type='string', help='Code coverage data repository to upload coverage data')
   parser.add_option('--launcher', dest='launcher_ip', action='store',
                     type='string', help='IP address of launcher/master controller')
   global options
   (options, args) = parser.parse_args()

   max_volumes =\
      'esxcli system settings advanced set -o /NFS/MaxVolumes --int-value 32'
   (output, stdout, stderr) = ShellUtil.run_command(max_volumes)

   mount_list = {'build-toolchain.eng.vmware.com_0': options.toolchain, \
                 'automation': options.vdnet, \
                 'vdtest': options.vm_repository, \
                 'vdnetSharedStorage': options.shared_storage}
   # add staf to the mount list. use the one on toolchain by default
   if options.staf is not None:
      print "use customized staf mirror ", options.staf
      mount_list[STAF_MOUNTPOINT] = options.staf
   mount_nfs(mount_list)
   #Now execute all the setup commands one after the other
   print "execute set up commands now"
   setup_commands = ['echo %s %s >> /etc/hosts' % (options.launcher_ip, \
                                                   options.launcher_ip),
                     'perl -v',
                     'mkdir -p /build',
                     'rm -f /build/toolchain',
                     'ln -sf /vmfs/volumes/build-toolchain.eng.vmware.com_0 /build/toolchain',
                     'ln -sf /build/toolchain/lin32/perl-5.8.8/lib /lib',
                     'ln -sf /build/toolchain/lin32/perl-5.8.8/lib/5.8.8/i686-linux-thread-multi/CORE/libperl.so /lib',
                     'ln -sfn /vmfs/volumes/automation /automation',
                     'cp /vmfs/volumes/automation/certs/vmware.cert /usr/share/certs/vmware.cert',
                     'ln -sf /build/toolchain/lin32/staf-3.4.1/lib/perl510/libPLSTAF.so /lib',
                     'ln -sf /build/toolchain/lin32/perl-5.10.0/bin/perl /bin',
                     'vsish -e get /system/version',
                     'vsish -e set /config/Net/intOpts/GuestIPHack 1',
                     'vsish -e set /config/Misc/intOpts/VmkStressEnable 0',
                     'vsish -e set /config/Misc/intOpts/BlueScreenTimeout 1',
                    ]
   ShellUtil.run_command_list(setup_commands)

   set_hostname()
   set_env_for_nsx_logging('VERBOSE')
   install_staf()
   #Check code coverage option and do necessary setup
   if options.code_coverage_type != None:
      print "Need to set esx for %s coverage \n" % options.code_coverage_type
      #mount build/apps datastores
      cov_mount_list = {'ob': 'build-ob.eng.vmware.com:/misc/ob', \
                        'apps': 'build-apps.eng.vmware.com:/apps'}
      #mount data repository storage
      if options.coverage_data_repos != None:
         cov_mount_list['dbc'] = options.coverage_data_repos
      else:
         cov_mount_list['dbc'] = 'pa-dbc1113:/dbc/pa-dbc1113/netfvt/code_coverage'
      mount_nfs(cov_mount_list)
      #create symbol links
      cov_commands = ['mkdir -p /misc',
                      'ln -sf /vmfs/volumes/ob /misc/ob',
                      'ln -sf /vmfs/volumes/apps /apps',
                      'ln -sf /vmfs/volumes/toolchain /toolchain',
                     ]
      ShellUtil.run_command_list(cov_commands)
      #parse build information
      build_info = BuildInfo()
      #setup environment variable for VMTREE
      setup_vmtree(build_info)
      #enable coverage
      enable_coverage(options.code_coverage_type)
      #update environment variables
      if not ShellUtil.grep_file('/etc/profile.local', 'CODE_COVERAGE'):
         cov_util_dir = '%s/support/scripts/coverage' % os.environ['VMTREE']
         update_dict = {'CODE_COVERAGE': 'export CODE_COVERAGE=%s' % options.code_coverage_type,
                        'PATH': 'export PATH=$PATH:%s' % cov_util_dir,
                        'VMBLD': 'export VMBLD=%s' % build_info.get_buildtype()}
         ShellUtil.update_file('/etc/profile.local', update_dict)
         ShellUtil.update_file(os.path.expanduser('~/.profile'), update_dict)
   sys.exit(0)

