#!/usr/bin/env python
########################################################################
# Copyright (C) 2014 VMware, Inc.
# # All Rights Reserved
########################################################################

# This script is borrowed from ETC
import sys
import contextlib

sys.path.append('/mts/git/pyvpx-5_0')
import pyVim.connect
import pyVim.host


@contextlib.contextmanager
def connected(ipaddr, user='root', password='ca$hc0w'):
   serviceInstance = None
   try:
      serviceInstance = pyVim.connect.Connect(host=ipaddr, user=user,
         pwd=password)
      yield serviceInstance
   except Exception:
      raise
   finally:
      if serviceInstance is not None:
         pyVim.connect.Disconnect(serviceInstance)


def hostsystem(serviceInstance):
   rootFolder = pyVim.host.GetRootFolder(serviceInstance)
   datacenter = rootFolder.childEntity[0]
   return datacenter.hostFolder.childEntity[0].host[0]
