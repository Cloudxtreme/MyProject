########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################

package VDNetLib::TestData::StressTestData;

#
# This package defines hashes which groups a set of stress options
# that can be understood by VDNetLib::Host::HostOperation (specifically
# the HostStress() method) and VDNetLib::Workloads::HostWorkload modules.
# The format of the hash should be:
#    var1 => (
#       'stressOption1'   => <stressValue>,
#       'stressOption2'   => <stressValue>,
#       'stressOption3'   => <stressValue>,
#       .
#       .
#       'stressOptionN'   => <stressValue>,
#    );
# Here 'stressOption<x>' is just the option name not an absolute path.
#
# If the value of <stressValue> is undef, the recommended value will be taken
# by HostStress() method in VDNetLib::Host::HostOperation module.
#
#

%networkStress = (
   NetFailVmxnetMapTx         => undef, # take recommended
   NetVmxnetTxIncompletePkt   => undef, # take recommended
   NetForceSplitGiantPktTx    => undef, # take recommended
   NetFailPktAlloc            => undef, # take recommended
   NetVmxnetRxRingFull        => undef, # take recommended
   NetVmxnetRxRing2Full       => undef, # take recommended
   NetIfForceRxSWCsum         => undef, # take recommended
   NetFailKseg                => undef, # take recommended
   NetFailPktCopyBytesOut     => undef, # take recommended
   NetFailCopyFromSGMA        => undef, # take recommended
);

%portStress = (
   NetFailPortEnable          => undef, # take recommended
   NetFailPortsetEnablePort   => undef, # take recommended
   NetFailPortsetConnectPort  => undef, # take recommended
   NetFailPortReserve	      => undef, # take recommended
   NetFailPortWorldAssoc      => undef, # take recommended
   NetFailPortInputResume     => undef, # take recommended
   NetFailPortsetProcCreate   => undef, # take recommended
   NetFailPortsetActivate     => undef, # take recommended
   NetFailPortsetPortOutput   => undef, # take recommended
   NetCorruptPortInput	      => undef, # take recommended
   NetCorruptPortOutput	      => undef, # take recommended
);

%vmxnet3Stress = (
   NetVmxnet3KsegPartialRxBuf => undef, # take recommended
   NetVmxnet3FailMapNextChunk => undef, # take recommended
   NetVmxnet3FailFixCsum      => undef, # take recommended
   NetVmxnet3SkipRxDesc       => undef, # take recommended
   NetVmxnet3HdrTooBig        => undef, # take recommended
   NetVmxnet3StopRxQueue      => undef, # take recommended
   NetVmxnet3StopTxQueue      => undef, # take recommended
   NetVmxnet3FailTsoSplitMove => undef, # take recommended
   NetVmxnetRxRingFull        => undef, # take recommended
   NetVmxnetRxRing2Full       => undef, # take recommended
   NetVmxnetNoLPD             => undef, # take recommended

);

%vmxnetStress = (
   NetVmxnetTxIncompletePkt  => undef, # take recommended
   NetVmxnetRxRingFull       => undef, # take recommended
   NetVmxnetRxRing2Full      => undef, # take recommended
   NetVmxnetNoLPD            => undef, # take recommended
   NetFailVmxnetMapTx        => undef, # take recommended
   NetFailVmxnetPinBuffers   => undef, # take recommended
);

%e1000Stress = (
   NetE1000ForceLargeHdrCopy     => undef, # take recommended
   NetE1000ForceSmallChangelog   => undef, # take recommended
   NetE1000LoggingDelayTxComp    => undef, # take recommended
   NetE1000IpCsumBadPsod         => undef, # take recommended
   NetE1000OutOfBoundPA          => undef, # take recommended
   NetE1000FailMapGuestPA        => undef, # take recommended
   NetIfE1000TsoForcePullTail    => undef, # take recommended
   NetE1000FailTxZeroCopy        => undef, # take recommended
);

%uptStress = (
   NetUPTQuiesceEmuFailure    => undef, # take recommended
   NetUPTOOBAllocFailure      => undef, # take recommended
   NetUPTOOBXMapFailure       => undef, # take recommended
   NetUPTOOBIOMMUFailure      => undef, # take recommended
   NetUPTPrep4PTFailure       => undef, # take recommended
   NetUPTInferTxGenFailure    => undef, # take recommended
   NetUPTInferRxGenFailure    => undef, # take recommended
   NetUPTForceTQError         => undef, # take recommended
   NetUPTForceRQError         => undef, # take recommended
   NetUPTSimuLostIntrs        => undef, # take recommended
   NetUPTSaveStateFailure     => undef, # take recommended
   NetPTPinPagesDelay         => undef, # take recommended
   NetPTPinPagesFailure       => undef, # take recommended
   NetPTInitVFFailure         => undef, # take recommended
   NetPTSetupIntrProxyFailure => undef, # take recommended
   NetPTActivateVFFailure     => undef, # take recommended
   NetPTQuiesceVFFailure      => undef, # take recommended
   NetPTDelayPT2EmuForce      => undef, # take recommended
);

%vmkLinuxStress = (
   NetIfCorruptRxTcpUdp       => undef, # take recommended
   NetIfCorruptEthHdr         => undef, # take recommended
   NetIfFailRx                => undef, # take recommended
   NetIfCorruptTx             => undef, # take recommended
   NetIfFailHardTx            => undef, # take recommended
   NetIfFailTxAndStopQueue    => undef, # take recommended
   NetIfForceRxSWCsum         => undef, # take recommended
   NetGenTinyArpRarp          => undef, # take recommended
   NetBlockDevIsSluggish      => undef, # take recommended
   NetIfForceHighDMAOverflow  => undef, # take recommended
);

$dvFilterStress = (
   NetDvfilterAllocFail             => undef, # take recommended
   NetDvfilterMsgAllocFail          => undef, # take recommended
   NetDvfilterSendtoFailure         => undef, # take recommended
   NetFailDVFilterRegisterFastPath  => undef, # take recommended
   NetAbortDVFilterVMotionPrefetch  => undef, # take recommended
   NetAbortDVFilterVMotionLength    => undef, # take recommended
   NetFailDVFilterCreation          => undef, # take recommended
   NetFailDVFilterConnection        => undef, # take recommended
   NetFailDVFilterDetachFilter      => undef, # take recommended
   NetFailDVFilterAllocMsgId        => undef, # take recommended
   NetMaxDVFilterPktTags            => undef, # take recommended
   NetFailDVFilterSetSlowPath       => undef, # take recommended
   NetFailDVFilterClearSlowPath     => undef, # take recommended
);

%packetStress =(
   NetFailPktAlloc            => undef, # take recommended
   # Not supported. Will enable if supported on future builds
   # NetFailPktSlabHeapAlloc    => undef, # take recommended
   NetFailPktClone            => undef, # take recommended
   NetFailPktFrameCopy        => undef, # take recommended
   NetFailPktCopyBytesIn      => undef, # take recommended
   NetFailPktCopyBytesOut     => undef, # take recommended
   NetFailPktlistClone        => undef, # take recommended
   NetFailPrivHdr             => undef, # take recommended
   NetFailCopyToSGMA          => undef, # take recommended
   NetFailCopyFromSGMA        => undef, # take recommended
   NetFailKseg                => undef, # take recommended
   NetFailPartialCopy         => undef, # take recommended
   NetForcePktSGSpanPages     => undef, # take recommended
   NetPktCompareFreq          => undef, # take recommended
   NetCheckDupPkt             => undef, # take recommended
   NetPktDbgForceUseHeap      => undef, # take recommended
   NetVlanAllocFail           => undef, # take recommended
);

%portSetPortStress = (
   NetQueueCommitInput           => undef, # take recommended
   NetFailPortWorldAssoc         => undef, # take recommended
   NetFailPortEnable             => undef, # take recommended
   NetFailPortInputResume        => undef, # take recommended
   NetFailPortsetActivate        => undef, # take recommended
   # Not supported. Will enable if supported on future builds
   # NetFailPortsetDisablePort     => undef, # take recommended
   NetFailPortsetEnablePort      => undef, # take recommended
   NetFailPortsetConnectPort     => undef, # take recommended
   NetCorruptPortInput           => undef, # take recommended
   NetCorruptPortOutput          => undef, # take recommended
);

%uplinkStress = (
   NetUplinkSyncAsyncSkipWait      => undef, # take recommended
   NetUplinkSyncAsyncForceTimeout  => undef, # take recommended
   NetUplinkDelayAsync             => undef, # take recommended
   NetUplinkDelaySyncAsync         => undef, # take recommended
   NetUplinkFailDisconnect         => undef, # take recommended
   NetUplinkFailHelperRequest      => undef, # take recommended
   NetCopyToLowSG                  => undef, # take recommended
   NetUplinkForceXmitError         => undef, # take recommended
   NetUplinkForceOpenFail          => undef, # take recommended
   NetUplinkWritableInetHeaders    => undef, # take recommended
);

%netDVSStress  =  (
   NetDVSSyncStaleUpdate          => undef, # take recommended
   NetDVSSyncBadRx                => undef, # take recommended
);

%pktapiVmxnet3  = (
   NetVmxnet3KsegPartialRxBuf => undef,
   NetVmxnet3FailMapNextChunk => undef,
   NetVmxnet3FailFixCsum      => undef,
   NetVmxnet3SkipRxDesc       => undef,
   NetVmxnet3HdrTooBig        => undef,
   NetVmxnet3StopRxQueue      => undef,
   NetVmxnet3StopTxQueue      => undef,
   NetVmxnet3FailTsoSplitMove => undef,
   NetVmxnetRxRingFull        => undef,
   NetVmxnetRxRing2Full       => undef,
   NetVmxnetNoLPD             => undef,
   NetForceSplitGiantPktTx    => undef,
);

%pktapiE1000 = (
   NetE1000ForceLargeHdrCopy     => 2000,  # recommended value, 50 is heavy;
                                           # hit count 9300
   NetE1000OutOfBoundPA          => 2,     # recommended value, 10 is too low;
                                           # hit count 0
   NetE1000FailMapGuestPA        => 20000, # recommended value, 100 is too
                                           # heavy, hit count 377970
   NetE1000FailTxZeroCopy        => 2000,  # recommended value, 50 is too heavy
                                           # hit count 9463
   NetFailPktCanAppend           => 16000, # recommended 1 is to heavy (hit
                                           # count 2549091)
);

%pktapiVmxnet2 = (
   NetVmxnetTxIncompletePkt  => undef,
   NetVmxnetRxRingFull       => 128000,   # recommended value 50 is too heavy,
                                          # hit count 463776
   NetVmxnetRxRing2Full      => 1000,     # recommended value 50 is too heavy,
                                          # hit count 2491
   NetVmxnetNoLPD            => 1000,     # recommended value 50 is heavy,
                                          # hit count 1861
   NetFailVmxnetMapTx        => 300000,   # recommended value 50 is too heavy,
                                          # hit count 753858
   NetFailVmxnetPinBuffers   => undef,
   NetForceSplitGiantPktTx   => undef,
);

%pktvmkLinux = (
   NetIfCorruptRxTcpUdp       => 500,
   NetIfCorruptEthHdr         => 500,
   NetIfFailRx                => undef,
   NetIfCorruptTx             => 500,
   # Causes host to loose connectivity if
   # recommended value is used.
   NetIfFailHardTx            => 500,
   # Causes host to loose connectivity if
   # recommended value is used.
   #NetIfFailTxAndStopQueue    => 300,
   NetIfForceRxSWCsum         => undef,
   NetGenTinyArpRarp          => undef,
   NetBlockDevIsSluggish      => undef,
   NetIfForceHighDMAOverflow  => undef,
   NetIfCorruptRxData         => 500,
);

%pktpacket =(
   NetFailPktAlloc            => undef,
   NetFailPktClone            => undef,
   NetFailPktFrameCopy        => undef,
   # Not supported now, can enable if supported on host
   # NetPortInputCorrupt        => undef,
   # NetPortOutputCorrupt       => undef,
   NetFailPktCopyBytesIn      => undef,
   NetFailPktCopyBytesOut     => undef,
   NetFailPktlistClone        => undef,
   NetFailPrivHdr             => undef,
   # Not supported now, can enable if supported on host
   # NetChkSumAsmC              => undef,
   NetFailCopyToSGMA          => undef,
   NetFailCopyFromSGMA        => undef,
   NetFailKseg                => undef,
   NetFailPartialCopy         => undef,
   NetForcePktSGSpanPages     => undef,
   NetPktCompareFreq          => undef,
   NetCheckDupPkt             => undef,
   NetPktDbgForceUseHeap      => undef,
   NetVlanAllocFail           => undef,
);

%pktportSetPort = (
   #NetDelayProcessIocl           => undef, #the option is not supported in OP
   #NetDelayProcessDeferredInput  => undef, #the option is not supported in OP
   NetQueueCommitInput           => undef,
   NetFailPortWorldAssoc         => undef,
   NetFailPortEnable             => undef,
   NetFailPortInputResume        => undef,
   NetFailPortsetActivate        => undef,
   NetFailPortsetEnablePort      => undef,
   NetFailPortsetConnectPort     => undef,
   NetCorruptPortInput           => undef,
   NetCorruptPortOutput          => undef,
);
%VMKTCPIPStress = (
   NetFailPktAlloc            => undef, #takes Recommemded values
   NetFailPktClone            => undef,
   NetFailPktFrameCopy        => undef,
   NetFailPktCopyBytesIn      => undef,
   NetFailPktCopyBytesOut     => undef,
   NetFailPrivHdr             => undef,
   NetFailCopyFromSGMA        => undef,
   NetFailKseg                => undef,
   NetFailPartialCopy         => undef,
   NetHwRetainBuffer          => undef,
   NetCorruptPortInput        => undef,
   NetCorruptPortOutput       => undef,
   NetIfCorruptEthHdr         => undef,
   NetIfCorruptRxData         => undef,
   NetIfCorruptRxTcpUdp       => undef,
   NetIfFailRx                => undef,
   NetFailNDiscHeapAlloc      => undef,
   NetCopyToLowSG             => undef,
   NetIfCorruptTx             => undef,
   NetIfFailHardTx            => undef,
);

%VMKTCPIPJFNetstress = (
   NetFailPktAlloc            => undef, #takes Recommemded values
   NetFailPrivHdr             => undef,
   NetFailPktCopyBytesOut     => undef,
   NetFailCopyFromSGMA        => undef,
   NetFailKseg                => undef,
   NetIfCorruptRxTcpUdp       => undef,
   NetIfCorruptRxData         => undef,
   NetIfCorruptEthHdr         => undef,
   NetIfForceRxSWCsum         => undef,
);

%VMKTCPIPNetstress = (
   NetIfForceRxSWCsum         => undef,#takes Recommemded values
   TcpipAllocFailMin          => undef,
   TcpipAllocFailMax          => undef,
   NetFailPktFrameCopy        => undef,
   NetFailPktAlloc            => undef,
   NetFailPrivHdr             => undef,
   NetFailPktCopyBytesOut     => undef,
   NetFailCopyFromSGMA        => undef,
   NetFailKseg                => undef,
   NetIfCorruptRxData         => undef,
   NetIfCorruptEthHdr         => undef,
   NetIfForceRxSWCsum         => undef,
);

%vlanStress = (
   NetVlanAllocFail           => 10,
);

%CoalwithStressOpt = (
   NetFailGPHeapAlloc         => 50,
);

%TxWithNetFailPortWorldAssoc = (
   NetFailPortWorldAssoc => 1,
);

%TxWithNetFailPortsetDisablePort = (
   NetFailPortsetDisablePort => 1,
);

%TxWithNetFailPortEnable = (
   NetFailPortEnable         => 1,
);

%TxWithNetFailPortsetEnablePort = (
   NetFailPortsetEnablePort => 100,
);

%TxWithNetFailPortsetConnectPort = (
   NetFailPortsetConnectPort => 1,
);

%TxWithNetFailPortInputResume = (
   NetFailPortInputResume   => 100,
);

%TxWithNetCorruptPortInput = (
   NetCorruptPortInput    => 100,
);

%TxWithNetCorruptPortOutput = (
   NetCorruptPortOutput    => 100,
);

%TxWithNetE1000ForceLowTcpUdpLen = (
   NetE1000ForceLowTcpUdpLen    => 1,
);

%VLANwithStressOption = (
   NetFailPartialCopy     => 5,
);

%IOWithNetDelayBhRx = (
   NetDelayBhRx => 3,
);

%TxWithNetFailVmxnetMapTx  = (
   NetFailVmxnetMapTx => 50,
);

%TxWithNetFailKseg = (
   NetFailKseg => 100,
);

%TxWithNetFailVmxnetPinBuffers = (
   NetFailVmxnetPinBuffers => 1,
);

%TxWithNetVmxnetTxIncompletePkt  = (
   NetVmxnetTxIncompletePkt => 50,
);

%TxWithNetVmxnetRxRingFull  = (
   NetVmxnetRxRingFull => 50,
);

%TxWithNetVmxnetRxRing2Full = (
   NetVmxnetRxRing2Full => 50,
);

%TxWithNetVmxnetNoLPD = (
   NetVmxnetNoLPD => 50,
);

%TxWithNetTxWorldlet = (
   NetTxWorldlet => 50,
);

%TxWithNetVmxnet3KsegPartialRxBuf = (
   NetVmxnet3KsegPartialRxBuf => 3,
);

%TxWithNetVmxnet3FailMapNextChunk  = (
   NetVmxnet3FailMapNextChunk => 3,
);

%TxWithNetVmxnet3FailFixCsum = (
   NetVmxnet3FailFixCsum => 50,
);

%TxWithNetIfForceRxSWCsum = (
   NetVmxnet3FailFixCsum => 50,
   NetIfForceRxSWCsum    => 1,
);

%TxWithNetVmxnet3SkipRxDesc = (
   NetVmxnet3SkipRxDesc => 50,
);

%TxWithNetVmxnet3HdrTooBig = (
   NetVmxnet3HdrTooBig => 50,
);

%TxWithNetVmxnet3StopRxQueue = (
   NetVmxnet3StopRxQueue => 50,
);

%TxWithNetVmxnet3StopTxQueue = (
   NetVmxnet3StopTxQueue => 50,
);

%TxWithNetVmxnet3FailTsoSplitMove = (
   NetVmxnet3FailTsoSplitMove => 50,
);

%TxWithNetForceSplitGiantPktTx = (
   NetForceSplitGiantPktTx => 1,
);

%TxWithNetE1000FailTxZeroCopy = (
   NetE1000FailTxZeroCopy => 50,
);

%TxWithNetFailPktCanAppend = (
   NetFailPktCanAppend => 1,
);

%TxWithNetForcePktSGSpanPages = (
   NetForcePktSGSpanPages => 1,
);

%TxWithNetE1000ForceLargeHdrCopy = (
   NetE1000ForceLargeHdrCopy => 50,
);

%TxWithNetE1000ForceSmallChangelog = (
   NetE1000ForceSmallChangelog => 50,
);

%TxWithNetPktDbgForceUseHeap = (
   NetPktDbgForceUseHeap => 1,
);

%TxWithNetCheckDupPkt = (
   NetCheckDupPkt => 500,
);

%TxWithNetE1000IpCsumBadPsod = (
   NetE1000IpCsumBadPsod => 0,
);

%TxWithNetE1000OutOfBoundPA = (
   NetE1000OutOfBoundPA   => 10,
   NetE1000FailMapGuestPA => 100,
);

%TxWithNetFailGPHeapAlign = (
   NetFailGPHeapAlign => 50,
);

%NetVmxnet3StopTxQueue = (
   NetVmxnet3StopTxQueue => 25,
);

%NetVmxnet3StopRxQueue = (
   NetVmxnet3StopRxQueue => 25,
);

%IOwithNetVmxnet3HdrTooBig = (
   NetVmxnet3HdrTooBig => 5,
);

%NetDelayBhTxComplete = (
   NetDelayBhTxComplete => 10,
);

%InboundIOwithSO = (
   NetVmxnet3FailMapNextChunk => 3,
   NetVmxnet3KsegPartialRxBuf => 3,
);

%IOwithNetVmxnet3HdrTooBig = (
   NetVmxnet3HdrTooBig => 2,
);

%NetFailCopyToSGMA = (
   NetFailCopyToSGMA => 1,
);

%TxWithNetQueueCommitInput = (
   NetQueueCommitInput => 3,
);

%TxWithNetDelayProcessDeferredInput = (
   NetDelayProcessDeferredInput => 3,
);

%TxWithNetDelayProcessIocl = (
   NetDelayProcessIocl => 3,
);

%TxWithNetFailNDiscHeapAlloc = (
   NetFailNDiscHeapAlloc => 50,
);

%TxWithNetFailGPHeapAlign = (
   NetFailGPHeapAlign => 50,
);

%TxWithNetFailGPHeapAlloc = (
   NetFailGPHeapAlloc => 50,
);

%VXLANStress = (
   Vdl2IPCacheUpdateFail => 50,
   Vdl2CPWorldTaskPostFail => 100,
   Vdl2CPUpdateFail => 100,
   Vdl2PktNotWritable => 1000,
   Vdl2InstanceInitFail => undef,
   Vdl2PortInitFail => undef,
   Vdl2VmknicInitFail => undef,
   Vdl2TrunkInitFail => undef,
   Vdl2McastGroupJoinFail => undef,
   Vdl2McastGroupCreateFail => undef,
   Vdl2IPCacheUpdateFail => undef,
   Vdl2CPWorldTaskPostFail => undef,
);

%TSOStress = (
   NetTsoValidationFailurePSOD  => undef,
   NetUplinkWritableInetHeaders => undef,
   NetTSOOneSegmentTSOPSOD      => undef,
   NetIfE1000TsoForcePullTail   => undef,
   NetDVFilterCertTsoMode       => undef,
   NetVmxnetNoLPD               => undef,
   NetForceTSOSplit             => undef,
   NetVmxnet3FailTsoSplitMove   => undef,
   NetE1000ForceLargeHdrCopy    => undef,
);

1;
