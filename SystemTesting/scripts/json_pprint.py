#!/usr/bin/env python
import json
from pprint import pprint
import sys

with open(sys.argv[1],'r') as fo:
    json_ = json.loads(fo.read())

if len(sys.argv) > 2:
    # go down the levels of a dict and at the end of the chain print the value
    # usage example:  pprint_config.py  /tmp/vdnet/1234/config.json  esx  1  build
    target = json_
    for i,key in enumerate(sys.argv[2:]):
	try:
	    target = target[key]
	except KeyError, ex:
	    pprint("%d'th key failed with %s" % (i,ex))
	    break
    pprint(target)
else:
    pprint(json_)
