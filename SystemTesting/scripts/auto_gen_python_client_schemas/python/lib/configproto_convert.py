# Copyright (C) 2011 Nicira, Inc.
#
# This is an unpublished work, is confidential and proprietary to
# Nicira, Inc. as a trade secret and is not to be used or
# disclosed without Nicira's consent.

from proto_cloudnet.configproto_node_pb2 import PBCPMessage
import sys

def ConfigProtoConvert(buf):
    """Convert a buffer of bytes into a PBCPMessage protobuf
    """
    msg = PBCPMessage()
    msg.ParseFromString(buf)
    return msg

if __name__ == "__main__":
    if len(sys.argv) > 1:
        infile = open(sys.argv[1], 'r')
    else:
        infile = sys.stdin
    buf = infile.read()
    print ConfigProtoConvert(buf)
