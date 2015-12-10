#!/bin/python

#
# This scripts is used to configure Linux host/guest
# to run vdnet tests
# NOTE: Do not use utilites or any other imports for this as
# its a standalone script
#
from subprocess import Popen, PIPE
from optparse import OptionParser
import os
import re
import sys
import time

def run_command(command, returnObject=False):
    """ function to run command on the linux hosts

    @param command: command to be executed
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

def find_datastore(mount_point, share, server):
    """ function to find if the given mount point/datastore exists

    @param mount_point: name of datastore/mount point
    @param share: name of the share from the nfs server
    @param server: ip of the NFS server
    @first return value 0 if mount_point exists, 1 if does not exist, 2 if exists with
    different configuration
    @second return value for current mount point
    """
    command = "mount | grep \"" + share + "\""
    (output, stdout, stderr) = run_command(command)
    nfs_list = stdout.rstrip()
    if not nfs_list:
       print ("%s is not mounted\n\n" % mount_point)
       return (1, None)
    command = 'echo \"%s\" | awk \'{print $3}\'' % nfs_list
    (output, stdout, stderr) = run_command(command)
    stdout = stdout.rstrip()
    if stdout != mount_point:
       print ("Expected mount point %s while it is mounted as %s" % (mount_point, stdout))
       return (2, ' '.join(stdout.splitlines()))
    command = 'echo \"%s\" | awk \'{split($0,a,":"); print a[1]}\'' % nfs_list
    (output, stdout, stderr) = run_command(command)
    stdout = stdout.rstrip()
    if stdout != server:
       print ("%s is not on desired server %s It is on %s" % (mount_point, server, stdout))
       return (2, mount_point)
    print ('MOUNT: %s is correctly mounted' % mount_point)
    return (0, mount_point)

def add_datastore(mount_point, share, server, read_only=1):
    """ function to add the given nfs server

    @param mount_point: name of datastore/mount point
    @param share: name of the share from the nfs server
    @param server: ip of the NFS server
    @return 0 if nfs server mounted successfully, 1 in case of error
    """
    if os.path.islink(mount_point):
        print ("%r is a symlink to %r" %
               (mount_point, os.path.realpath(mount_point)))
        print ('Removing this symbolic link now')
        os.unlink(mount_point)
    elif os.path.ismount(mount_point):
        print ("%r is a mount point already" % mount_point)
        print("Unmounting it now")
        run_command("umount %s" % mount_point)
    command1 = "mkdir -p %s" % (mount_point)
    command2 = "mount -t nfs %s:%s %s" % (server, share, mount_point)
    command = "%s ; %s" % (command1, command2)
    if read_only:
        command = "%s -r" % command

    (output, stdout, stderr) = run_command(command)
    if not stdout :
        return 1
    else :
        return 0


def remove_datastore(mount_point) :
    """ function to remove the given mount point/ nfs datastore

    @param mount_point: name of the nfs datastore
    @return 0 if datastore removed successfully, 1 in case of error
    """
    command = 'umount %s | grep "Error: "' % mount_point
    (output, stdout, stderr) = run_command(command)
    if not stdout:
        return 0
    else :
        return 1


def install_staf():
    """ function to install staf

    @param None
    @return None
    """
    (output, stdout, stderr) = run_command("staf local ping ping")
    if not re.search('PONG', stdout):
        run_command("rm -f /usr/local/staf")
        run_command("unlink /bin/staf")
        (output, stdout, stderr) = run_command("uname -m")
        if re.search('x86_64', stdout):
            run_command("/pa-group/stautomation/stafInstall/StafSetup_unified.pl --staf64")
        else:
            run_command("/pa-group/stautomation/stafInstall/StafSetup_unified.pl --staf")
        run_command("sudo bash /usr/local/staf/STAFEnv.sh")
        run_command("ln -s /usr/local/staf/bin/staf /bin/staf")
        run_command("export PATH=$PATH:/usr/local/staf/bin; /usr/local/staf/bin/STAFProc")
        (output, stdout, stderr) = run_command("staf local ping ping")
        retry = 5
        while (retry and not re.search('PONG', stdout)):
            (output, stdout, stderr) = run_command("staf local ping ping")
            time.sleep(2)
            retry -= 1
            if retry == 0:
               print "STAF is not starting on this machine"
    else:
        print "STAF is running fine on this machine"


if __name__ == "__main__":
    usage = "usage: %prog [options]"
    parser = OptionParser(usage=usage)
    parser.add_option("--toolchain", dest="toolchain", action="store",
                      default='build-toolchain.eng.vmware.com:/toolchain',
                      type="string", help="Toolchain server and share")
    parser.add_option("--trees", dest="trees", action="store",
                      default='scm-trees.eng.vmware.com:/trees',
                      type="string", help="SCM Trees server and share")
    parser.add_option("--staf", dest="staf", action="store",
                      default='pa-group.eng.vmware.com:/stautomation',
                      type="string", help="STAF Installation server and share")
    parser.add_option("--vdnet", dest="vdnet", action="store",
                      type="string", help="VDNet source server and share")
    parser.add_option("--vmrepository", dest="vm_repository", action="store",
                      type="string", help="VM repository/server and share")
    parser.add_option("--sharedstorage", dest="shared_storage", action="store",
                      type="string", help="Shared storage and share")
    parser.add_option("--launcher", dest="launcher_ip", action="store",
                      type="string", help="IP address of launcher/master controller")
    global options
    (options, args) = parser.parse_args()

    mount_list = {
                  '/bldmnt/toolchain': options.toolchain,
                  '/bldmnt/trees': options.trees,
                  '/pa-group/stautomation': options.staf
                 }
    if options.vm_repository:
       mount_list['/vdtest'] = options.vm_repository
    if options.shared_storage:
       mount_list['/vdnetSharedStorage'] = options.shared_storage
    if options.vdnet:
       # We already mount scm-trees by default.
       # If user says pick src code in remote machines from scm-tree we do symlink
       # If user says mount my own server/share and pick src code from there, we mount that
       if re.search('scm-trees', options.vdnet):
          server, share = options.vdnet.split(":",1)
          (output, stdout, stderr) = run_command('rm -f /automation')
          (output, stdout, stderr) = run_command('%s%s%s%s' % ('ln -s /bldmnt', share, '/', ' /automation'))
       else:
          mount_list['/automation'] = options.vdnet

    run_command("mount")
    for key in mount_list.keys():
        add_flag = 0
        print "Working on %s from the list " % key
        server, share = mount_list[key].split(':')
        return_val, existing_mountpoint = find_datastore(key, share, server)
        if return_val == 2 :
            return_val_remove  = remove_datastore(existing_mountpoint)
            if return_val_remove == 1:
                print "failed to remove datastore %s \n" %existing_mountpoint
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
            print "failed to add datastore %s \n" % key
            sys.exit(return_val)
    # Now execute all the setup commands one after the other
    print "execute set up commands now"
    setUpCommands = ["echo %s %s >> /etc/hosts" % (options.launcher_ip, \
                                                   options.launcher_ip),
                     "perl -v",
                     "mkdir -p /build",
                     "ln -s /bldmnt/toolchain /build/toolchain",
                     "ln -s /bldmnt/trees /build/trees",
                     "ls -l /automation/",
                    ]
    length = len(setUpCommands)
    for y in range(0,length):
        (output, stdout, stderr) = run_command(setUpCommands[y])
        #TODO: Check output/return code for verification
    install_staf()

    print "vdnet_linux_setup finished. Existing now"
    sys.exit(0)

