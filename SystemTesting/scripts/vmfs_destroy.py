#!/usr/bin/env python
########################################################################
# Copyright (C) 2014 VMware, Inc.
# # All Rights Reserved
########################################################################

# This script is borrowed from ETC
import sys
import json
import time
import ssl

from connect import connected
from connect import hostsystem as _hostsystem

import argparse

from pyVmomi import Vim

import logging
LOGGER = logging.getLogger('esx.vmfs_destroy')

EXCEPT_FAULTS = (
   Vim.Fault.ResourceInUse,
   Vim.Fault.PlatformConfigFault,
   Vim.Fault.InvalidState
)


def _destroy(datastoreSystem, datastore, tries=1):
   while tries > 0:
      try:
         datastoreSystem.RemoveDatastore(datastore)
         return True
      except EXCEPT_FAULTS, ex:
         LOGGER.debug('failed to remove vmfs: %s' % str(ex))
         time.sleep(1)
         tries = tries - 1
   return False


def destroy(args):
   ''' destroy all vmfs volumes on an esx host '''
   ipaddr = args['ipaddr']
   user = args['username']
   password = args['password']

   with connected(ipaddr, user=user, password=password) as serviceInstance:
      hostsystem = _hostsystem(serviceInstance)
      datastoreSystem = hostsystem.configManager.datastoreSystem
      datastores = [x for x in datastoreSystem.datastore
         if hasattr(x.info, 'vmfs')]
      uuids = [x.info.vmfs.uuid for x in datastores]

      destroyed = []
      for datastore in datastores:
         uuid = datastore.info.vmfs.uuid
         if _destroy(datastoreSystem, datastore, tries=3):
            destroyed += [uuid]
      return json.dumps({
         'datastores': uuids,
         'destroyed': destroyed
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
   standalone_parser.set_defaults(func=destroy)

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
