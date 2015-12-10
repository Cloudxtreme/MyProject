########################################################################
# Copyright (C) 2013 VMWare, Inc.
# # All Rights Reserved
########################################################################
#
# Script to get the build number of ESX host or VC using the IP address
#
import sys
import ssl
from pyVim import arguments
from pyVmomi import Vmodl, Vim, SoapStubAdapter

def main():
   ssl._create_default_https_context = ssl._create_unverified_context
   supportedArgs = [ (["s:", "server="], "localhost", "Host name", "server") ]
   supportedToggles = [ (["usage", "help"], False, "Show usage information", "usage") ]

   args = arguments.Arguments(sys.argv, supportedArgs, supportedToggles)
   if args.GetKeyValue("usage") == True:
      args.Usage()
      sys.exit(0)

   try:
      host = args.GetKeyValue("server")
      stub = SoapStubAdapter(host, 443, "vim25/2.5", "/sdk")
      si = Vim.ServiceInstance("ServiceInstance", stub)
      sc = si.RetrieveContent()
      print sc.about.build
   except Exception, e:
      print e
      sys.exit(1)

# Start program
if __name__ == "__main__":
    main()
