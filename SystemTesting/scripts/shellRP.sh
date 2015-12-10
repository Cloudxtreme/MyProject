#!/bin/sh
# shellRP.sh
# Script to configure resource (memory) for ESX shell
# This is copied from ATLAS framework, any bug, update it from
#  //depot/Proj/atlas-stable/etc/shellRP.sh
#
vmvisor=$(vsish -e set /sched/groupPathNameToID host vim vmvisor | cut -d ' ' -f 1)
vmvisorshell=$(vsish -e set /sched/groupPathNameToID host vim vmvisor shell | cut -d ' ' -f 1)
shellmax=$(vsish -e get /sched/groups/$vmvisorshell/memAllocationInMB | grep max | cut -d ':' -f 2)
visormax=$(vsish -e get /sched/groups/$vmvisor/memAllocationInMB | grep max | cut -d ':' -f 2)
echo "VMvisor RP: $vmvisor, maxMem: $visormax"
echo "VMvisor shell RP: $vmvisorshell, maxMem: $shellmax"

boostMem=512
if [ "$shellmax" = "-1" ]; then
   echo "Capping shell maxMem to $boostMem"
   newvisormax=`expr $visormax + $boostMem`
   echo "Boosting visor maxMem from $visormax to $newvisormax"

   vsish -e set /sched/groups/$vmvisorshell/memAllocationInMB min=$boostMem max=$boostMem
   vsish -e set /sched/groups/$vmvisor/memAllocationInMB min=$newvisormax max=$newvisormax
fi



