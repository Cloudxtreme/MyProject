########################################################################
# Copyright (C) 2009 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::NPFunc;
#
# This module exports arrays of test data that works with Netperf utility.
# Each data (command line arguments) have to be comma separated within an
# array of data.
#

@testData = (
"-t TCP_STREAM -l 10 -- -m 8192 -s 32768 -S 65536",
"-t TCP_STREAM -l 10 -- -m 4096 -s 8192 -S 4096",
"-t TCP_STREAM -l 10 -- -m 1024 -s 8192 -S 16384",
"-t TCP_STREAM -l 10 -- -m 16384 -s 32768 -S 32768",
"-t TCP_STREAM -l 10 -- -m 65536 -s 65536 -S 65536",
"-t UDP_STREAM -l 30 -- -m 4096 -s 8192 -S 16384",
"-t UDP_RR -l 20 -- -s 4096 -S 16384 -r 4096,16384",
"-t UDP_RR -l 10 -- -s 16384 -S 16384 -r 96,96",
"-t UDP_RR -l 10 -- -s 4096 -S 4096 -r 5,5",
"-t TCP_RR -l 20 -- -s 32 -S 32 -r 32,32",
"-t UDP_STREAM -l 20 -- -m 40 -s 80 -S 80",
"-t UDP_STREAM -l 20 -- -m 1024 -s 4096 -S 4096",
"-t UDP_STREAM -l 20 -- -m 4096 -s 4096 -S 4096",
"-t UDP_STREAM -l 20 -- -m 4096 -s 8192 -S 4096",
);

@UDP = (
"-t UDP_STREAM -l 20 -- -m 4096 -s 4096 -S 16384",
"-t UDP_STREAM -l 20 -- -m 16384 -s 32768 -S 32768",
"-t UDP_STREAM -l 20 -- -m 16384 -s 32768 -S 32768",
# this fails on windows, might be feature bug
#"-t UDP_RR -l 60 -- -s 4096 -S 16384 -r 4096,16384",
);

@TSOData = (
"-t TCP_STREAM -l 30 -- -m 4096 -s 8192 -S 4096",
);

@Stress =  (
"NetFailPktAlloc 1",
"IOForceCopy 1",
"IOForceSplit 1",
"NetIfForceRxSWCsum 1",
"NetFailKseg 1",
"NetFailPktCopyBytesOut 1",
"NetFailCopyFromSGMA 1",
"NetFailPortEnable 1",
"NetFailPortsetEnablePort 1",
"NetFailPortsetDisablePort 1",
"NetFailPortsetConnectPort 1",
);

@JFData = (
"-t TCP_STREAM -l 20 -- -m 32768 -s 32768 -S 32768",
"-t TCP_STREAM -l 20 -- -m 16384 -s 32768 -S 32768",
"-t TCP_STREAM -l 20 -- -m 16384 -s 65536 -S 65536",
"-t UDP_RR -l 20 -- -s 16384 -S 16384 -r 16384,32768",
"-t UDP_RR -l 20 -- -s 32768 -S 32768 -r 32768,32768",
"-t UDP_STREAM -l 20 -- -m 65536 -s 65536 -S 65536",
"-t UDP_STREAM -l 20 -- -m 15384 -s 32768 -S 32768",
);

@JFTxRxData = (
"-t UDP_STREAM -l 20 -- -m 4096 -s 8192 -S 4096",
"-t TCP_STREAM -l 20 -- -m 4096 -s 4096 -S 16384",
"-t TCP_STREAM -l 20 -- -m 16384 -s 32768 -S 32768",
"-t TCP_STREAM -l 20 -- -m 65536 -s 65536 -S 65536",
"-t UDP_RR -l 20 -- -s 4096 -S 16384 -r 4096,8384",
"-t TCP_RR -l 20 -- -s 32768 -S 32768 -r 8384,8384",
"-t UDP_STREAM -l 20 -- -m 4096 -s 8192 -S 4096",
"-t UDP_STREAM -l 20 -- -m 4096 -s 4096 -S 16384",
);

@TxRxData = (
"-t TCP_STREAM -l 20 -- -m 4 -s 8192 -S 4096",
"-t TCP_STREAM -l 20 -- -m 1024 -s 4096 -S 16384",
"-t TCP_STREAM -l 20 -- -m 16384 -s 32768 -S 32768",
"-t UDP_RR -l 20 -- -s 40 -S 16 -r 4,8",
"-t UDP_RR -l 20 -- -s 4096 -S 4096 -r 4096,4096",
"-t TCP_RR -l 20 -- -s 32 -S 32 -r 32,32",
"-t UDP_STREAM -l 20 -- -m 40 -s 80 -S 80",
"-t UDP_STREAM -l 20 -- -m 1024 -s 4096 -S 4096",
"-t UDP_STREAM -l 20 -- -m 4096 -s 4096 -S 4096",
);

1;
