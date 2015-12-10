########################################################################
# Copyright (C) 2012 VMWare, Inc.
# All Rights Reserved
########################################################################

#
# sendKeystrokes.py --
#     This script is used to send keystrokes to the given VM
#
import sys
sys.path.append("/usr/lib/vmware/python/pyVigor.zip")
import pyVigor
# argv[1] is the absolute vmx path given as command line
# parameter to this script
c = pyVigor.ConnectLocal(sys.argv[1])
c.MKS.SendKeySequence('a')
