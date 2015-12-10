########################################################################
# Copyright (C) 2014 VMware, Inc.
# # All Rights Reserved
########################################################################

#
# This script converts tests that are written for ESX or KVM (but applicable
# to both) to either KVM or ESX or mixed mode having ESX & KVM.
# But for Avalanche, we only support ESX -> KVM & ESX -> Hybrid
#

import os
import sys
import re
import collections
from optparse import OptionParser

# Error codes
SUCCESS = 0
FAILURE = 1
INVALID = 2
UNSUPPORTED = 3

# Mapper dictionaries
esx_to_kvm_mapper_dict = {
   'index': {
      'esx.' : 'kvm.',
      'esx.\[(.*)\].vmnic.\[(.*)\]' : 'kvm.[\\1].pif.[\\2]',
      # This is needed for intermediate conversion
      'kvm.\[(.*)\].vmnic.\[(.*)\]' : 'kvm.[\\1].pif.[\\2]',
      'vnic' : 'vif',
      'portgroup' : 'FIXME',
      'vss' : 'FIXME',
      '--ESX' : '--KVM'
   },
   'meta_tags': {}
}

kvm_to_esx_mapper_dict = {
   'index': {
      'kvm.\[(.*)\].pif.\[(.*)\]' : 'esx.[\\1].vmnic.[\\2]',
      'kvm.' : 'esx.',
      '.pif.' : '.vmnic.',
      'vif' : 'vnic',
      'bridge' : 'FIXME',
      'ovs' : 'FIXME',
      '--KVM' : '--ESX'
   },
   'meta_tags': {}
}

def map_tds(options):
   """ Routine to convert TDS written for ESX to KVM or vice versa or hybrid
   (containing both ESX & KVM)

   @type options: dict
   @param: options: Command line arguments
   @rtype: integer
   @return: Status codes SUCCESS/FAILURE/INVALID/UNSUPPORTED
   """

   input_tds = options.inputtds
   output_tds = options.outputtds
   mode = options.mode

   if input_tds is None or output_tds is None or mode is None:
      print "Invalid input parameters. Usage: mapper_tool.py "\
             "--inputtds <file> --outputtds <file/dir> --mode <mode>"
      sys.exit(INVALID)

   # For Avalanche, we only support ESX -> KVM & ESX -> Hybrid
   # TODO, remove this check when we support KVM -> ESX & Hybrid
   if mode.lower() != 'kvm' and mode.lower() != 'hybrid':
      print "Unsupported mode"
      sys.exit(UNSUPPORTED)

   if os.path.isfile(input_tds):
      input_tds_handle = open(input_tds, 'r')
   else:
      print "Input TDS is not a file"
      sys.exit(INVALID)

   if os.path.isdir(output_tds):
      output_tds = output_tds + '/' + mode.upper() + 'TDS.yaml'
   output_tds_handle = open(output_tds, 'w+')

   ret = convert_tds_files(input_tds_handle,output_tds_handle, mode)
   if ret == SUCCESS:
      print "Conversion succeeded. Converted file is %s" % output_tds
   else:
      print "Conversion failed"
      sys.exit(FAILURE)

def convert_tds_files(input_tds_handle, output_tds_handle, mode):
   """ Routine to convert the TDSes

   @type input_tds_handle: file handle
   @param input_tds_handle: Input file handle
   @type output_tds_handle: file handle
   @param output_tds_handle: Output file handle
   @type mode: string
   @param mode: Output TDS type
   @type dictindex: string
   @param dictindex: Index into the mapper dict
   @rtype: integer
   @return: Status codes SUCCESS/FAILURE/INVALID/UNSUPPORTED
   """

   if mode.lower() == 'kvm':
      mapper_dict = esx_to_kvm_mapper_dict
   elif mode.lower() == 'esx':
      mapper_dict = kvm_to_esx_mapper_dict
   else:
      # TODO: Add hybrid mode dict
      print "Output TDS is hybrid mode"
      sys.exit(UNSUPPORTED)

   # Sort the dictionary
   for index in mapper_dict:
      mapper_dict[index] = collections.OrderedDict(sorted(mapper_dict[index].items()))
      for line in input_tds_handle:
         for key in mapper_dict[index]:
            line = re.sub(key, mapper_dict[index][key], line)
         output_tds_handle.write(line)
   return SUCCESS

if __name__ == "__main__":
   usage = "usage: %prog [options]"
   parser = OptionParser(usage=usage)
   parser.add_option("--inputtds", dest="inputtds", action="store",
                     type="string", help="Input TDS to convert")
   parser.add_option("--outputtds", dest="outputtds", action="store",
                     type="string", help="Output TDS dir/file")
   parser.add_option("--mode", dest="mode", action="store",
                     type="string", help="Coversion mode: KVM/ESX/Hybrid")
   (options, args) = parser.parse_args()
   map_tds(options)
