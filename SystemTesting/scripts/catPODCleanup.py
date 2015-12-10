#!/usr/bin/env python
#
# This script can be used to cleanup VMs that were deployed
# by vdnet as part of CAT infrastructure
#
# It connects to the VC managing the given POD, goes through all VMs.
# If the VM name contains CAT's 'testrunid' id, then it checks the status
# of the testrun. If the testrun is complete, then it destroys the VM.
#
import json
import os
import re
import urllib

import vmware.common.nimbus_utils as nimbus_utils
import vmware.common.vsphere_utilities as vsphere_utilities

if 'NIMBUS_BASE' in os.environ.keys():
    NIMBUS_BASE = os.environ['NIMBUS_BASE']
else:
    NIMBUS_BASE = "/mts/git"


def run_cleanup():
   proxy = 'local'
   #
   # Get the Server name and credentials from the
   # environment variables
   #
   func = nimbus_utils.read_nimbus_config
   config_dict = func(os.environ['NIMBUS_CONFIG_FILE'],
                      os.environ['NIMBUS'])
   server = config_dict['vc']
   user = config_dict['vc_user']
   password = config_dict['vc_password']

   # Create a session with the server
   command = 'STAF %s vm connect agent %s userid %s password \"%s\" ssl' % \
      (proxy, server, user, password)
   nimbusOutput = vsphere_utilities.run_command(command,returnObject=True)
   (stdout,stderr) = nimbusOutput.communicate()

   # Get the list of VMs
   command = 'STAF %s vm getvms anchor %s:%s' % (proxy, server, user)
   nimbusOutput = vsphere_utilities.run_command(command,returnObject=True)
   (stdout,stderr) = nimbusOutput.communicate()
   temp = re.split(r"\n", stdout)
   for line in temp:
      if re.search("VM NAME", line):
         vm = re.split(r": ", line)
         #
         # VMs deployed by vdnet uses - as delimiter, where
         # the last portion indicates testrun id
         # example: vmktestdevnanny-vdnet-esx-sb-2819285-2-7701321
         # Here, 7701321 is the testrunid
         #
         vmName = re.split(r"-", vm[1])
         user = vmName[0]
         if len(vmName) >= 6 and vmName[-1].isdigit():
            testrunid = vmName[-1]
            # check for greater testrun id to avoid VMs
            # with testrunid inserted manually like
            # user-vdnet-esx-1331820-2-2
            #
            if int(testrunid) < 6000000:
               continue

            url = 'http://nsx-cat.eng.vmware.com/api/v1.0/testrun/%s/' % testrunid
            json_data = urllib.urlopen(url).read()
            info = json.loads(json_data)
            # If endtime is defined, then the testrun is complete,
            # so, destroying those VMs
            if info['endtime'] != None:
               command = '%s/bin/nimbus-ctl --path users/%s off %s' % (
                  NIMBUS_BASE, user, vm[1])
               nimbusOutput = vsphere_utilities.run_command(command,
                                                            returnObject=True)
               (stdout,stderr) = nimbusOutput.communicate()
               command = '%s/bin/nimbus-ctl --path users/%s destroy %s' % (
                  NIMBUS_BASE, user, vm[1])
               nimbusOutput = vsphere_utilities.run_command(command,
                                                            returnObject=True)
               (stdout,stderr) = nimbusOutput.communicate()


if __name__ == "__main__":
   run_cleanup()

