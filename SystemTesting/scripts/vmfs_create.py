#!/build/toolchain/lin32/python-2.7.9-openssl1.0.1k/bin/python
########################################################################
# Copyright (C) 2014 VMware, Inc.
# # All Rights Reserved
########################################################################

# This script is borrowed from ETC
import sys
import re
import json
import ssl

from connect import connected
from connect import hostsystem as _hostsystem

import argparse

from pyVmomi import Vmodl, Vim, SoapStubAdapter

import logging
LOGGER = logging.getLogger('esx.vmfs_create')


def create(args):
   ''' create vmfs volumes on an esx host '''
   ipaddr = args['ipaddr']
   user = args['username']
   password = args['password']
   free_luns = args['free_luns']
   diskpattern = args['diskpattern']
   prefix = args['prefix']

   stub = SoapStubAdapter(host=ipaddr, port=443, path="/sdk", version="vim.version.version7")
   serviceInstance = Vim.ServiceInstance("ServiceInstance", stub)
   content = serviceInstance.RetrieveContent()
   content.sessionManager.Login(user, password)
   if serviceInstance:
      hostsystem = _hostsystem(serviceInstance)
      hostsystem.configManager.storageSystem.RescanVmfs()
      datastoreSystem = hostsystem.configManager.datastoreSystem
      uuids_before = [x.info.vmfs.uuid for x in datastoreSystem.datastore
         if hasattr(x.info, 'vmfs')]

      available_disks = [x.devicePath for x in
         datastoreSystem.QueryAvailableDisksForVmfs() if not x.ssd]
      available_disks = [
         x for x in available_disks if re.compile(diskpattern).search(x)]

      specs = []
      for disk in available_disks:
         specs += datastoreSystem.QueryVmfsDatastoreCreateOptions(disk, 5)

      uuids_created = []
      label_index = 0
      for spec in specs:
         if len(uuids_created) >= len(specs) - free_luns:
            break
         while True:
            label_index = label_index + 1
            spec.spec.vmfs.volumeName = "%s%d" % (prefix, label_index)
            try:
               datastore = datastoreSystem.CreateVmfsDatastore(spec.spec)
               uuids_created += [datastore.info.vmfs.uuid]
            except Vim.Fault.DuplicateName, ex:
               # duplicate name, pick another
               continue
            except Vim.Fault.PlatformConfigFault, ex:
               # weird python error; does not happen with rbvmomi
               LOGGER.debug(str(ex))
            break

      uuids = [x.info.vmfs.uuid for x in datastoreSystem.datastore
         if hasattr(x.info, 'vmfs')]
      available_disks = [x.devicePath for x in
         datastoreSystem.QueryAvailableDisksForVmfs() if not x.ssd]
      available_disks = [
         x for x in available_disks if re.compile(diskpattern).search(x)]

      return json.dumps({
         "uuids_before": uuids_before,
         "uuids_created": uuids_created,
         "uuids": uuids,
         "available": available_disks
      })


def main():
   ''' main function '''
   parser = argparse.ArgumentParser()
   parser.add_argument('-v', '--verbose', action='store_true',
      help='verbose output')
   subparsers = parser.add_subparsers(title='subcommands',
   dest="subcommand")

   lease_parser = subparsers.add_parser('lease',
      help='for use in an ETC lease context')
   lease_parser.add_argument('--leaseid', metavar='LEASEID',
      type=int, required=True,
      help='the ETC leaseid to operate on')
   lease_parser.add_argument('--source', metavar='SOURCE',
      type=str, required=True,
      help='the name (testbed spec host key) of the host to operate on')
   lease_parser.add_argument('--destination', metavar='DESTINATION',
      type=str, required=False,
      help='the name (testbed spec host key) to use as destination')
   lease_parser.add_argument('--free_luns', metavar='FREE_LUNS',
      type=int, default=0,
      help='the number of luns *not* to format vmfs')
   lease_parser.add_argument('--diskpattern', metavar='DISKPATTERN',
      type=str, required=False, default='mpx',
      help='the diskpattern used to match the luns')
   lease_parser.add_argument('--prefix', metavar='PREFIX',
      type=str, required=False, default='local-',
      help='the vmfs label prefix')
   #lease_parser.set_defaults(func=lease, onsuccess=create)

   standalone_parser = subparsers.add_parser('standalone',
      help='for use in outside of an ETC lease context')
   standalone_parser.add_argument('--ipaddr', metavar='IPADDR',
      type=str, required=True,
      help='the ipaddr of the esx host')
   standalone_parser.add_argument('--username', metavar='USERNAME',
      type=str, required=True,
      help='the username to connect as')
   standalone_parser.add_argument('--password', metavar='PASSWORD',
      type=str, required=False, default='',
      help='the password to connect with')
   standalone_parser.add_argument('--free_luns', metavar='FREE_LUNS',
      type=int, required=True,
      help='the number of luns *not* to format vmfs')
   standalone_parser.add_argument('--diskpattern', metavar='DISKPATTERN',
      type=str, required=False, default='mpx',
      help='the diskpattern used to match the luns')
   standalone_parser.add_argument('--prefix', metavar='PREFIX',
      type=str, required=False, default='local-',
      help='the vmfs label prefix')
   standalone_parser.set_defaults(func=create)

   args = parser.parse_args()
   args = vars(args)

   log_format = '%(message)s'
   LOGGER.setLevel(logging.INFO)
   if args['verbose']:
      LOGGER.setLevel(logging.DEBUG)
      log_format = '%(asctime)s  %(levelname)s - %(funcName)s:%(lineno)d %(message)s'
   # configure logging
   logging.basicConfig(format=log_format)
   ssl._create_default_https_context = ssl._create_unverified_context
   try:
      resp = args['func'](args)
      if resp is not None:
         print str(resp)
         return 0
      return 1
   except Exception, ex:
      if args['verbose']:
         LOGGER.exception(str(ex))
      else:
         LOGGER.critical(str(ex))
      return -1


if __name__ == '__main__':
   sys.exit(main())
