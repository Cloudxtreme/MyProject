/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ClusterConfigSpecEx;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchPortConnecteeConnecteeType;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * For a DRS enabled clustered host with powered off VM's that connects to a
 * standalone DVPort, late binding port group, early binding portgroup put the
 * host into maintenance mode, with migrate powered off vm's set to true.
 */
public class Pos019 extends FunctionalTestBase
{
   // private instance variables go here.
   private ClusterComputeResource icr = null;
   private DistributedVirtualPortgroup idvPortgroup = null;
   private ManagedObjectReference otherHostMor = null;
   private ManagedObjectReference otherHostFolder = null;
   private ManagedObjectReference otherNwSystemMor = null;
   private ManagedObjectReference clusterMor = null;
   private String earlyBindingPgKey = null;
   private String lateBindingPgKey = null;
   private ManagedObjectReference prevHostcluster = null;
   private ManagedObjectReference hostFolder = null;
   private ManagedObjectReference prevOtherHostCluster = null;
   private List<String> standalonePortKeys = null;
   private String dvsName = null;
   private String clusterName = null;
   private String hostName = null;
   private String otherHostName = null;
   private HostNetworkConfig otherHostOrgNetCfg = null;
   private Vector<ManagedObjectReference> vmMors = null;
   private List<ManagedObjectReference> clonedVMs = null;
   private Map<ManagedObjectReference, VirtualMachinePowerState> vmPowerMap = null;
   private Map<String, VirtualMachineConfigSpec> vmConfigspecMap = null;
   private static final int NO_OF_VMS_ON_HOST = 3;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("For a DRS enabled clustered host with powered on "
               + "VM 's that connects to a standalone DVPort, late "
               + "binding portgroup, early binding portgroup put the"
               + " host into maintenance mode.");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
   throws Exception
   {
      boolean setUpDone = false;
      ClusterConfigSpecEx configspec = null;
      Vector hostFolders = null;
      ManagedObjectReference parentFolder = null;
      Vector<ManagedObjectReference> allHosts = null;
      Vector<ManagedObjectReference> hostVms = null;
      DVSConfigSpec reconfigSpec = null;
      DVSConfigInfo configInfo = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpec = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      ManagedObjectReference vmMor = null;
      ManagedObjectReference cloneVMMor = null;
      VirtualMachineRelocateSpec relocateSpec = null;
      VirtualMachineCloneSpec cloneSpec = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      DVPortgroupConfigSpec pgConfigSpec = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      ManagedObjectReference pgMor = null;
      List<ManagedObjectReference> pgMors = null;
      int noOfVms = 0;
      String vmName = null;
      int noOfEthernetCards = 0;
      Map<String, List<String>> excludedPorts = new HashMap<String, List<String>>();
      String portgroupKey = null;
      String freePortKey = null;
      List<DistributedVirtualSwitchPortConnection> ports = null;
      String switchUUID = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      List<String> freePorts = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;

      setUpDone = super.testSetUp();
      if (setUpDone) {
         configInfo = this.iDVS.getConfig(this.dvsMor);
         switchUUID = configInfo.getUuid();
         this.dvsName = configInfo.getName();
         this.hostName = this.ihs.getHostName(this.hostMor);
         this.icr = new ClusterComputeResource(connectAnchor);
         this.idvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         hostFolders = this.iFolder.getAllHostFolders();
         if ((hostFolders != null) && (hostFolders.size() > 0)) {
            parentFolder = (ManagedObjectReference) hostFolders.firstElement();
            if (parentFolder != null) {
               configspec = new ClusterConfigSpecEx();
               this.clusterMor = this.iFolder.createClusterEx(parentFolder,
                        getTestId() + "-Cluster", configspec);
               if (this.clusterMor != null) {
                  this.clusterName = this.icr.getName(this.clusterMor);
                  setUpDone = this.icr.setDRS(this.clusterMor, true, DrsBehavior.FULLY_AUTOMATED);
                  if (setUpDone) {
                     log.info("Successfully enabled the DRS on the cluster");
                     hostVms = this.ihs.getAllVirtualMachine(this.hostMor);
                     if (hostVms != null) {
                        this.vmPowerMap = this.ivm.createVMsStateMap(hostVms);
                        setUpDone = this.ivm.powerOffVMs(hostVms);
                        if (setUpDone) {
                           log.info("Succesfully powered off all the Vms's on"
                                    + " the host " + this.hostName);
                        } else {
                           log.error("Can not power off the VM's on the "
                                    + "host " + this.hostName);
                        }
                     }
                     if (setUpDone) {
                        if (!this.ihs.isStandaloneHost(this.hostMor)) {
                           this.prevHostcluster = this.ihs.getParentNode(this.hostMor);
                           setUpDone = this.ihs.enterMaintenanceMode(
                                    this.hostMor,
                                    TestConstants.ENTERMAINTENANCEMODE_TIMEOUT,
                                    false);
                           if (setUpDone) {
                              log.info("Succesfully moved the host into "
                                       + "maintenance mode " + this.hostName);
                           } else {
                              log.error("Can not move the host into "
                                       + "maintenance mode " + this.hostName);
                           }
                        } else {
                           this.hostFolder = this.ihs.getHostFolder(this.hostMor);
                        }
                        if (setUpDone) {
                           setUpDone = this.icr.moveHostInto(
                                    this.clusterMor, this.hostMor, null);
                           if (setUpDone) {
                              if (this.ihs.isHostInMaintenanceMode(this.hostMor)) {
                                 setUpDone = this.ihs.exitMaintenanceMode(
                                          this.hostMor,
                                          TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS);
                                 if (setUpDone) {
                                    log.info("Successfully exit maintenance"
                                             + " mode for the host "
                                             + this.hostName);
                                 } else {
                                    log.error("Can not exit the host from"
                                             + " the maintenance mode "
                                             + this.hostName);
                                 }
                              }
                              if (setUpDone) {
                                 allHosts = this.ihs.getAllHost();
                                 if ((allHosts != null)
                                          && (allHosts.size() > 0)) {
                                    for (ManagedObjectReference host : allHosts) {
                                       if ((host != null)
                                                && !this.hostName.equals(this.ihs.getName(host))) {
                                          this.otherHostMor = host;
                                          break;
                                       }
                                    }
                                    if (this.otherHostMor != null) {
                                       this.otherHostName = this.ihs.getName(this.otherHostMor);
                                       this.otherNwSystemMor = this.ins.getNetworkSystem(this.otherHostMor);
                                       hostVms = this.ihs.getAllVirtualMachine(otherHostMor);
                                       if (hostVms != null) {
                                          if (this.vmPowerMap != null) {
                                             this.vmPowerMap.putAll(this.ivm.createVMsStateMap(hostVms));
                                          } else {
                                             this.vmPowerMap = this.ivm.createVMsStateMap(hostVms);
                                          }
                                          setUpDone = this.ivm.powerOffVMs(hostVms);
                                          if (setUpDone) {
                                             log.info("Successfully powered"
                                                      + " off the VM's on the"
                                                      + " host "
                                                      + this.otherHostName);
                                          } else {
                                             log.error("Can not power off"
                                                      + " the VM's on the "
                                                      + "host "
                                                      + this.otherHostName);
                                          }
                                       }
                                       if (setUpDone) {
                                          if (!this.ihs.isStandaloneHost(this.otherHostMor)) {
                                             this.prevOtherHostCluster = this.ihs.getParentNode(this.otherHostMor);
                                             setUpDone = this.ihs.enterMaintenanceMode(
                                                      this.otherHostMor,
                                                      TestConstants.ENTERMAINTENANCEMODE_TIMEOUT,
                                                      false);
                                          } else {
                                             this.otherHostFolder = this.ihs.getHostFolder(this.otherHostMor);
                                          }
                                          if (setUpDone) {
                                             setUpDone = this.icr.moveHostInto(
                                                      this.clusterMor,
                                                      this.otherHostMor,
                                                      null);
                                             if (setUpDone) {
                                                log.info("Successfully moved"
                                                         + " the host "
                                                         + this.otherHostName
                                                         + "into the cluster "
                                                         + this.clusterName);
                                                if (this.ihs.isHostInMaintenanceMode(this.otherHostMor)) {
                                                   setUpDone = this.ihs.exitMaintenanceMode(
                                                            this.otherHostMor,
                                                            TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS);
                                                   if (setUpDone) {
                                                      log.info("Successfully"
                                                               + " exit the "
                                                               + "host "
                                                               + this.otherHostName
                                                               + "from "
                                                               + "maintenance "
                                                               + "mode");
                                                   } else {
                                                      log.error("Can not "
                                                               + "exit the "
                                                               + "host "
                                                               + this.otherHostName
                                                               + " from "
                                                               + "maintenance "
                                                               + "mode");
                                                   }
                                                }
                                             } else {
                                                log.error("Can not move the "
                                                         + "host "
                                                         + this.otherHostName
                                                         + "into the cluster "
                                                         + this.clusterName);
                                                assertTrue(setUpDone, "Setup failed");
                                                return setUpDone;
                                             }
                                          }
                                       }
                                    } else {
                                       log.error("The host MOR is null");
                                       setUpDone = false;
                                    }
                                 } else {
                                    log.error("There are no hosts in the VC "
                                             + "inventory");
                                    setUpDone = false;
                                 }
                              }
                           } else {
                              log.error("Can not move the host "
                                       + this.hostName
                                       + " into the cluster "
                                       + this.clusterName);
                           }
                        }
                     }
                  } else {
                     log.error("Can not enable DRS on the cluster "
                              + this.clusterName);
                  }
               } else {
                  log.error("Can not create the cluster ");
                  setUpDone = false;
               }
            } else {
               log.error("The parent folder is null");
               setUpDone = false;
            }
         } else {
            log.error("The host folders is either empty or null");
            setUpDone = false;
         }
         if (setUpDone) {
            reconfigSpec = new DVSConfigSpec();
            reconfigSpec.setConfigVersion(configInfo.getConfigVersion());
            hostConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
            hostConfigSpec.setHost(this.otherHostMor);
            hostConfigSpec.setBacking(new DistributedVirtualSwitchHostMemberPnicBacking());
            hostConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
            reconfigSpec.getHost().clear();
            reconfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpec }));
            setUpDone = this.iDVS.reconfigure(this.dvsMor, reconfigSpec);
            if (setUpDone) {
               log.info("Successfully reconfigured the DVS "
                        + this.dvsName);
               hostNetworkConfig = this.iDVS.getHostNetworkConfigMigrateToDVS(
                        this.dvsMor, this.otherHostMor);
               if ((hostNetworkConfig != null)
                        && (hostNetworkConfig.length >= 2)) {
                  this.otherHostOrgNetCfg = hostNetworkConfig[1];
                  setUpDone = this.ins.updateNetworkConfig(
                           this.otherNwSystemMor, hostNetworkConfig[0],
                           TestConstants.CHANGEMODE_MODIFY);
                  if (setUpDone) {
                     log.info("Successfully updated the network config "
                              + "on the host " + this.otherHostName);
                     hostVms = this.ihs.getAllVirtualMachine(hostMor);
                     if ((hostVms != null) && (hostVms.size() > 0)) {
                        noOfVms = hostVms.size();
                        vmMor = hostVms.firstElement();
                        vmName = this.ivm.getName(vmMor);
                        if (noOfVms < NO_OF_VMS_ON_HOST) {
                           for (int i = 0; i < NO_OF_VMS_ON_HOST - noOfVms; i++) {
                              relocateSpec = new VirtualMachineRelocateSpec();
                              relocateSpec.setPool(this.ivm.getResourcePool(vmMor));
                              relocateSpec.setHost(this.hostMor);
                              cloneSpec = new VirtualMachineCloneSpec();
                              cloneSpec.setTemplate(false);
                              cloneSpec.setPowerOn(false);
                              cloneSpec.setCustomization(null);
                              cloneSpec.setLocation(relocateSpec);
                              cloneVMMor = this.ivm.cloneVM(vmMor,
                                       this.ivm.getParentNode(vmMor), vmName
                                       + "Clone-" + i, cloneSpec);
                              if (cloneVMMor == null) {
                                 log.error("Can not clone the VM "
                                          + vmName);
                                 setUpDone = false;
                                 break;
                              } else {
                                 log.info("Successfully cloned the VM "
                                          + vmName);
                                 if (this.clonedVMs == null) {
                                    this.clonedVMs = new ArrayList<ManagedObjectReference>();
                                 }
                                 this.clonedVMs.add(cloneVMMor);
                              }
                           }
                        }
                        if (setUpDone) {
                           hostVms = this.ihs.getAllVirtualMachine(this.hostMor);
                           if ((hostVms != null)
                                    && (hostVms.size() >= NO_OF_VMS_ON_HOST)) {
                              for (int i = 0; i < NO_OF_VMS_ON_HOST; i++) {
                                 vmMor = hostVms.get(i);
                                 if (this.vmMors == null) {
                                    this.vmMors = new Vector<ManagedObjectReference>();
                                 }
                                 this.vmMors.add(vmMor);
                                 vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                                          vmMor, connectAnchor);
                                 noOfEthernetCards = vdConfigSpec.size();
                                 if (i == 0) {
                                    pgConfigSpec = new DVPortgroupConfigSpec();
                                    pgConfigSpec.setNumPorts(noOfEthernetCards);
                                    pgConfigSpec.setType(DVPORTGROUP_TYPE_EARLY_BINDING);
                                    pgConfigSpec.setName(this.getTestId()
                                             + "-epg");
                                    pgConfigSpec.setConfigVersion("");
                                    pgMors = this.iDVS.addPortGroups(
                                             this.dvsMor,
                                             new DVPortgroupConfigSpec[] { pgConfigSpec });
                                    if ((pgMors != null)
                                             && (pgMors.size() == 1)) {
                                       pgMor = pgMors.get(0);
                                       if (pgMor != null) {
                                          log.info("Successfully added the "
                                                   + "port group");
                                       } else {
                                          setUpDone = false;
                                          log.error("Can not add the "
                                                   + "portgroup");
                                       }
                                    } else {
                                       setUpDone = false;
                                       log.error("Can not add the "
                                                + "portgroup");
                                    }
                                    if (setUpDone) {
                                       portgroupKey = this.idvPortgroup.getKey(pgMor);
                                       this.earlyBindingPgKey = portgroupKey;
                                       ports = new ArrayList<DistributedVirtualSwitchPortConnection>();
                                       for (int j = 0; j < noOfEthernetCards; j++) {
                                          freePortKey = this.iDVS.getFreePortInPortgroup(
                                                   this.dvsMor,
                                                   portgroupKey,
                                                   excludedPorts);
                                          if (freePortKey != null) {
                                             portConnection = new DistributedVirtualSwitchPortConnection();
                                             portConnection.setPortgroupKey(portgroupKey);
                                             portConnection.setPortKey(freePortKey);
                                             portConnection.setSwitchUuid(switchUUID);
                                             ports.add(portConnection);
                                          } else {
                                             setUpDone = false;
                                             log.error("Can not find any free "
                                                      + "ports in the port "
                                                      + "group");
                                             assertTrue(setUpDone, "Setup failed");
                                             return setUpDone;
                                          }
                                       }
                                       if (ports.size() == 0) {
                                          log.error("There are no free "
                                                   + "ports in the early "
                                                   + "binding portgroup");
                                          setUpDone = false;
                                       }
                                    }
                                 } else if (i == 1) {
                                    pgConfigSpec = new DVPortgroupConfigSpec();
                                    pgConfigSpec.setNumPorts(noOfEthernetCards);
                                    pgConfigSpec.setType(DVPORTGROUP_TYPE_LATE_BINDING);
                                    pgConfigSpec.setName(this.getTestId()
                                             + "-lpg");
                                    pgConfigSpec.setConfigVersion("");
                                    pgMors = this.iDVS.addPortGroups(
                                             this.dvsMor,
                                             new DVPortgroupConfigSpec[] { pgConfigSpec });
                                    if ((pgMors != null)
                                             && (pgMors.size() == 1)) {
                                       pgMor = pgMors.get(0);
                                       if (pgMor != null) {
                                          log.info("Successfully added the "
                                                   + "port group");
                                       } else {
                                          setUpDone = false;
                                          log.error("Can not add the "
                                                   + "portgroup");
                                       }
                                    } else {
                                       setUpDone = false;
                                       log.error("Can not add the "
                                                + "portgroup");
                                    }
                                    if (setUpDone) {
                                       portgroupKey = this.idvPortgroup.getKey(pgMor);
                                       this.lateBindingPgKey = portgroupKey;
                                       ports = new ArrayList<DistributedVirtualSwitchPortConnection>();
                                       for (int j = 0; j < noOfEthernetCards; j++) {
                                          portConnection = new DistributedVirtualSwitchPortConnection();
                                          portConnection.setPortgroupKey(portgroupKey);
                                          portConnection.setSwitchUuid(switchUUID);
                                          ports.add(portConnection);

                                       }
                                    }
                                 } else {
                                    portCriteria = this.iDVS.getPortCriteria(
                                             false, null, null, null, null,
                                             false);
                                    freePorts = this.iDVS.fetchPortKeys(
                                             this.dvsMor, portCriteria);
                                    if ((freePorts == null)
                                             || (freePorts.size() < noOfEthernetCards)) {
                                       configInfo = this.iDVS.getConfig(this.dvsMor);
                                       reconfigSpec = new DVSConfigSpec();
                                       reconfigSpec.setConfigVersion(configInfo.getConfigVersion());
                                       reconfigSpec.setNumStandalonePorts(configInfo.getNumStandalonePorts()
                                                + (freePorts == null ? noOfEthernetCards
                                                         : noOfEthernetCards
                                                         - freePorts.size()));
                                       if (!this.iDVS.reconfigure(
                                                this.dvsMor, reconfigSpec)) {
                                          log.error("Can not reconfigure"
                                                   + " the DVS to have the"
                                                   + " required number of "
                                                   + "ports");
                                          setUpDone = false;
                                       } else {
                                          log.info("Successfully "
                                                   + "reconfigured the DVS "
                                                   + "to have the required "
                                                   + "number of standalone "
                                                   + "ports");
                                          freePorts = this.iDVS.fetchPortKeys(
                                                   this.dvsMor, portCriteria);
                                       }
                                    }
                                    if (setUpDone
                                             && (freePorts != null)
                                             && (freePorts.size() >= noOfEthernetCards)) {
                                       ports = new ArrayList<DistributedVirtualSwitchPortConnection>();
                                       for (int j = 0; j < noOfEthernetCards; j++) {
                                          freePortKey = freePorts.get(j);
                                          if (freePortKey != null) {
                                             if (this.standalonePortKeys == null) {
                                                this.standalonePortKeys = new ArrayList<String>(
                                                         noOfEthernetCards);
                                             }
                                             portConnection = new DistributedVirtualSwitchPortConnection();
                                             this.standalonePortKeys.add(freePortKey);
                                             portConnection.setPortKey(freePortKey);
                                             portConnection.setSwitchUuid(switchUUID);
                                             ports.add(portConnection);
                                          } else {
                                             setUpDone = false;
                                             log.error("Can not find any free "
                                                      + "standalone ports in "
                                                      + "the dv switch");
                                             assertTrue(setUpDone, "Setup failed");
                                             return setUpDone;
                                          }
                                       }
                                       if (ports.size() == 0) {
                                          log.error("There are no free "
                                                   + "standalone ports"
                                                   + "on the DV Switch");
                                          setUpDone = false;
                                       }
                                    } else {
                                       setUpDone = false;
                                       log.error("Can not find the required"
                                                + " number of standalone "
                                                + "ports");
                                    }
                                 }
                                 if (setUpDone) {
                                    if (this.vmConfigspecMap == null) {
                                       this.vmConfigspecMap = new HashMap<String, VirtualMachineConfigSpec>();
                                    }
                                    vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                             vmMor,
                                             connectAnchor,
                                             ports.toArray(new DistributedVirtualSwitchPortConnection[ports.size()]));
                                    if ((vmConfigSpec != null)
                                             && (vmConfigSpec.length == 2)
                                             && (vmConfigSpec[0] != null)
                                             && (vmConfigSpec[1] != null)) {
                                       this.vmConfigspecMap.put(
                                                this.ivm.getName(vmMor),
                                                vmConfigSpec[1]);
                                       setUpDone = this.ivm.reconfigVM(
                                                vmMor, vmConfigSpec[0]);
                                       if (setUpDone) {
                                          log.info("Successfully "
                                                   + "reconfigured the VM to "
                                                   + "use the DVswitch");
                                          if (i == 1) {
                                             if (!this.ivm.setVMState(vmMor, POWERED_ON, false)) {
                                                return false;
                                             } else {
                                                log.info("Successfully "
                                                         + "powered on the "
                                                         + "VM");
                                             }
                                          } else {
                                             if (this.ivm.setVMState(vmMor, POWERED_ON, false)) {
                                                if (this.ivm.setVMState(
                                                         vmMor, POWERED_OFF, false)) {
                                                   log.info("powered off the "
                                                            + "VM");
                                                } else {
                                                   log.error("Can not power"
                                                            + " off the VM");
                                                   setUpDone = false;
                                                   assertTrue(setUpDone, "Setup failed");
                                                   return setUpDone;
                                                }
                                             } else {
                                                log.error("Can not power "
                                                         + "on the VM");
                                                setUpDone = false;
                                                assertTrue(setUpDone, "Setup failed");
                                                return setUpDone;
                                             }
                                          }
                                       } else {
                                          log.error("Can not reconfigure"
                                                   + " the VM to use the "
                                                   + "DVswitch");
                                          assertTrue(setUpDone, "Setup failed");
                                          return setUpDone;
                                       }
                                    } else {
                                       log.error("Can not determine the "
                                                + "config spec for the "
                                                + "reconfig vm operation");
                                       setUpDone = false;
                                    }
                                 }
                              }
                           } else {
                              log.error("There are still not enough VM's on "
                                       + "the host");
                              setUpDone = false;
                           }
                        }
                     } else {
                        setUpDone = false;
                        log.error("Can not find any VM's on the host "
                                 + this.hostName);
                     }
                  } else {
                     log.error("Can not update the network config on the "
                              + "host");
                  }
               } else {
                  setUpDone = false;
                  log.error("Can not create the network config to update "
                           + "and restore the host network configuration "
                           + this.otherHostName);
               }
            } else {
               log.error("Can not reconfigure the DVS "
                        + this.dvsName);
            }
         }
      } else {
         log.error("Test Base setup failed");
      }

      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Method that performs the test.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "For a DRS enabled clustered host with powered on "
      + "VM 's that connects to a standalone DVPort, late "
      + "binding portgroup, early binding portgroup put the"
      + " host into maintenance mode.")
      public void test()
   throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = true;
      ManagedObjectReference vmMor = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<String> portKeys = null;
      List<DistributedVirtualPort> oldPorts = null;
      List<DistributedVirtualPort> newPorts = null;
      List<DistributedVirtualPort> ports = null;
      Comparator<DistributedVirtualPort> comparator = this.iDVS.getPortComparator();
      ThreadUtil.sleep(TestConstants.SLEEP_TIME_TEN_SECONDS * 6 * 5);
      if (this.standalonePortKeys != null) {
         portCriteria = this.iDVS.getPortCriteria(
                  true,
                  null,
                  null,
                  null,
                  this.standalonePortKeys.toArray(new String[this.standalonePortKeys.size()]),
                  false);
         testDone &= this.iDVS.refreshPortState(
                  this.dvsMor,
                  this.standalonePortKeys.toArray(new String[this.standalonePortKeys.size()]));
         if (testDone) {
            ports = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
            if (ports != null) {
               oldPorts = new ArrayList<DistributedVirtualPort>();
               oldPorts.addAll(ports);
            }
         } else {
            log.error("Can not refresh the port state of the standalone "
                     + "port keys");
         }
      }
      if (this.earlyBindingPgKey != null) {
         portCriteria = this.iDVS.getPortCriteria(true, null, null,
                  new String[] { this.earlyBindingPgKey }, null, true);
         portKeys = this.iDVS.fetchPortKeys(dvsMor, portCriteria);
         if ((portKeys != null) && (portKeys.size() > 0)) {
            if (this.iDVS.refreshPortState(this.dvsMor,
                     portKeys.toArray(new String[portKeys.size()]))) {
               ports = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
               if ((ports != null) && (ports.size() > 0)) {
                  if (oldPorts == null) {
                     oldPorts = new ArrayList<DistributedVirtualPort>();
                  }
                  oldPorts.addAll(ports);
               } else {
                  testDone &= false;
                  log.error("Can not get the port state of the early "
                           + "binding ports");
               }
            } else {
               testDone &= false;
               log.error("Can not retrieve the port keys in the early "
                        + "binding port group");
            }
         }
      }
      if (this.lateBindingPgKey != null) {
         portCriteria = this.iDVS.getPortCriteria(true, null, null,
                  new String[] { this.lateBindingPgKey }, null, true);
         portKeys = this.iDVS.fetchPortKeys(dvsMor, portCriteria);
         if ((portKeys != null) && (portKeys.size() > 0)) {
            if (this.iDVS.refreshPortState(this.dvsMor,
                     portKeys.toArray(new String[portKeys.size()]))) {
               ports = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
               if ((ports != null) && (ports.size() != 0)) {
                  if (oldPorts == null) {
                     oldPorts = new ArrayList<DistributedVirtualPort>();
                  }
                  oldPorts.addAll(ports);
               } else {
                  testDone &= false;
                  log.error("Can not retrieve the ports from the late "
                           + "binding port group");
               }
            } else {
               testDone &= false;
               log.error("Can not retrieve the port keys in the early "
                        + "binding port group");
            }
         }
      }
      if (testDone) {
         testDone &= this.ihs.enterMaintenanceMode(this.hostMor,
                  TestConstants.ENTERMAINTENANCEMODE_TIMEOUT, true);
         if (testDone) {
            log.info("Successfully entered maintenance mode for the host "
                     + this.hostName);
            for (int i = 0; i < this.vmMors.size(); i++) {
               vmMor = this.vmMors.get(i);
               if (this.ivm.getHostName(vmMor).equals(this.otherHostName)) {
                  log.info("The vm " + this.ivm.getVMName(vmMor)
                           + " is migrated to the other clustered host");
               } else {
                  log.error("The vm " + this.ivm.getVMName(vmMor)
                           + " is not "
                           + "migrated to the other clustered host");
                  testDone = false;
                  assertTrue(testDone, "Test Failed");
                  return;
               }
            }
            ThreadUtil.sleep(TestConstants.SLEEP_TIME_TEN_SECONDS * 6 * 5);
            if (this.standalonePortKeys != null) {
               if (this.iDVS.refreshPortState(
                        this.dvsMor,
                        this.standalonePortKeys.toArray(new String[this.standalonePortKeys.size()]))) {
                  portCriteria = this.iDVS.getPortCriteria(
                           true,
                           null,
                           null,
                           null,
                           this.standalonePortKeys.toArray(new String[this.standalonePortKeys.size()]),
                           false);
                  ports = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
                  if ((ports != null) && (ports.size() > 0)) {
                     newPorts = new ArrayList<DistributedVirtualPort>();
                     newPorts.addAll(ports);
                  } else {
                     testDone &= false;
                     log.error("Can not retrieve the standalone ports");
                  }
               } else {
                  testDone &= false;
                  log.error("Can not refresh the port state of the "
                           + "standalone ports");
               }
            }
            if (this.earlyBindingPgKey != null) {
               portCriteria = this.iDVS.getPortCriteria(true, null, null,
                        new String[] { this.earlyBindingPgKey }, null, true);
               portKeys = this.iDVS.fetchPortKeys(dvsMor, portCriteria);
               if ((portKeys != null) && (portKeys.size() > 0)) {
                  if (this.iDVS.refreshPortState(this.dvsMor,
                           portKeys.toArray(new String[portKeys.size()]))) {
                     ports = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
                     if ((ports != null) && (ports.size() > 0)) {
                        if (newPorts == null) {
                           newPorts = new ArrayList<DistributedVirtualPort>();
                        }
                        newPorts.addAll(ports);
                     } else {
                        testDone &= false;
                        log.error("Can not retrieve the ports in the early "
                                 + "binding port group");
                     }
                  } else {
                     testDone &= false;
                     log.error("Can not refresh the port state of the ports"
                              + " in the early binding port group");
                  }
               } else {
                  testDone &= false;
                  log.error("Can not fetch the port keys in the early "
                           + "binding port group");
               }
            }
            if (this.lateBindingPgKey != null) {
               portCriteria = this.iDVS.getPortCriteria(true, null, null,
                        new String[] { this.lateBindingPgKey }, null, true);
               portKeys = this.iDVS.fetchPortKeys(dvsMor, portCriteria);
               if ((portKeys != null) && (portKeys.size() > 0)) {
                  if (this.iDVS.refreshPortState(this.dvsMor,
                           portKeys.toArray(new String[portKeys.size()]))) {
                     ports = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
                     if ((ports != null) && (ports.size() > 0)) {
                        if (newPorts == null) {
                           newPorts = new ArrayList<DistributedVirtualPort>();
                        }
                        newPorts.addAll(ports);
                     } else {
                        testDone &= false;
                        log.error("Can not retrieve the ports in the late "
                                 + "binding port group");
                     }
                  } else {
                     testDone &= false;
                     log.error("Can not refresh the port state of the ports"
                              + " in the late binding port group");
                  }
               } else {
                  testDone &= false;
                  log.error("Can not fetch the port keys in the late "
                           + "binding port group");
               }
            }
            if ((newPorts != null) && (newPorts.size() == oldPorts.size())) {
               Collections.sort(oldPorts, comparator);
               Collections.sort(newPorts, comparator);
               for (int i = 0; i < oldPorts.size(); i++) {
                  if ((oldPorts.get(i) != null)
                           && (newPorts.get(i) != null)
                           && this.iDVS.comparePortConnecteeNicType(
                                    newPorts.get(i), DistributedVirtualSwitchPortConnecteeConnecteeType.VM_VNIC.value())
                                    && (newPorts.get(i).getState() != null)) {
                     if (!this.iDVS.comparePortState(
                              oldPorts.get(i).getState(),
                              newPorts.get(i).getState())) {
                        log.error("The port state is not retained");
                        testDone = false;
                        break;
                     }
                  }
               }
            } else {
               testDone = false;
               log.error("Can not retrieve all the ports used by the VM");
            }
         } else {
            log.error("Can not enter maintenance mode for the host "
                     + this.hostName);
         }
      }

      assertTrue(testDone, "Test Failed");
   }

   /**
    * Restores the state prior to running the test.
    *
    * @param connectAnchor ConnectAnchor Object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
   throws Exception
   {
      boolean cleanUpDone = true;
      String vmName = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      VirtualMachineRelocateSpec relocateSpec = null;

      if (this.vmMors != null) {
         cleanUpDone &= this.ivm.powerOffVMs(this.vmMors);
         if (cleanUpDone) {
            log.info("Powered off the VM's successfully");
            if (this.clonedVMs != null) {
               for (ManagedObjectReference vmMor : this.clonedVMs) {
                  vmName = this.ivm.getName(vmMor);
                  if (!this.ivm.destroy(vmMor)) {
                     cleanUpDone &= false;
                     log.error("Can not destroy the VM " + vmName);
                  } else {
                     log.info("Destroyed the cloned VM " + vmName);
                  }
               }
               if (!this.vmMors.removeAll(this.clonedVMs)) {
                  cleanUpDone &= false;
                  log.error("Can not remove the cloned VM's from the VM "
                           + "list");
               }
            }
            if (cleanUpDone) {
               relocateSpec = new VirtualMachineRelocateSpec();
               relocateSpec.setHost(this.hostMor);
               for (ManagedObjectReference vmMor : this.vmMors) {
                  if (this.otherHostName.equals(this.ivm.getHostName(vmMor))) {
                     if (this.ihs.isHostInMaintenanceMode(this.hostMor)) {
                        if (!this.ihs.exitMaintenanceMode(
                                 this.hostMor,
                                 TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS)) {
                           cleanUpDone &= false;
                           log.error("Can not exit the host from "
                                    + "maintenance mode " + this.hostName);
                        } else {
                           log.info("Can not exit maintenance mode on the "
                                    + "host " + this.hostName);
                        }
                     }
                     if (!this.ivm.relocateVM(vmMor, relocateSpec, VirtualMachineMovePriority.DEFAULT_PRIORITY)) {
                        cleanUpDone &= false;
                        log.error("Can not move the VM to the other host "
                                 + this.hostName);
                     } else {
                        log.info("Successfully moved the VM to the host "
                                 + this.hostName);
                     }
                  }
                  vmName = this.ivm.getVMName(vmMor);
                  vmConfigSpec = this.vmConfigspecMap.get(vmName);
                  if (!this.ivm.reconfigVM(vmMor, vmConfigSpec)) {
                     cleanUpDone &= false;
                     log.error("Can not reconfigure the VM " + vmName);
                  } else {
                     log.info("Successfully reconfigured the VM "
                              + vmName);
                  }
               }
            }
         } else {
            log.error("Can not power off the VM's");
         }
      }
      if ((this.otherHostMor != null)
               && this.icr.getName(this.icr.getParentNode(this.otherHostMor)).equals(
                        this.clusterName)) {
         if (this.prevOtherHostCluster != null) {
            if (this.ihs.enterMaintenanceMode(this.otherHostMor,
                     TestConstants.ENTERMAINTENANCEMODE_TIMEOUT, false)) {
               if (!this.icr.moveInto(this.prevOtherHostCluster,
                        new ManagedObjectReference[] { this.otherHostMor })) {
                  cleanUpDone &= false;
                  log.error("Can not move the host into the original "
                           + "cluster");
               } else {
                  log.info("Successfully moved the host into the original "
                           + "cluster");
                  if (this.ihs.isHostInMaintenanceMode(this.otherHostMor)) {
                     if (!this.ihs.exitMaintenanceMode(
                              this.otherHostMor,
                              TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS)) {
                        cleanUpDone &= false;
                        log.error("Can not move the host out of the "
                                 + "maintenance mode " + this.otherHostName);
                     }
                  }
               }
            } else {
               log.error("Can put the host into maintenance mode "
                        + this.otherHostName);
               cleanUpDone &= false;
            }
         } else {
            if (!this.icr.moveHostFromClusterToSAHost(this.clusterMor,
                     this.otherHostMor, this.otherHostFolder)) {
               cleanUpDone &= false;
               log.error("Can not move the host "
                        + this.otherHostName + " to be a standalone host");
            } else {
               log.info("Successfully moved the host as a standalone host "
                        + this.otherHostName);
            }
         }
      }
      if ((this.hostMor != null)
               && this.icr.getName(this.icr.getParentNode(this.hostMor)).equals(
                        this.clusterName)) {
         if (this.prevHostcluster != null) {
            if (!this.ihs.isHostInMaintenanceMode(hostMor)) {
               log.info("The host is not in maintenance mode, "
                        + " putting the host into maintenance mode");
               if (!this.ihs.enterMaintenanceMode(this.hostMor,
                        TestConstants.ENTERMAINTENANCEMODE_TIMEOUT, false)) {
                  cleanUpDone &= false;
                  log.error("Can not move the host into maintenance mode "
                           + this.hostName);
               }
            }
            if (this.ihs.isHostInMaintenanceMode(this.hostMor)) {
               if (!this.icr.moveInto(this.prevHostcluster,
                        new ManagedObjectReference[] { this.hostMor })) {
                  cleanUpDone &= false;
                  log.error("Can not move the host into the original "
                           + "cluster");
               } else {
                  log.info("Successfully moved the host into the original "
                           + "cluster");
                  if (this.ihs.isHostInMaintenanceMode(this.hostMor)) {
                     if (!this.ihs.exitMaintenanceMode(
                              this.hostMor,
                              TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS)) {
                        cleanUpDone &= false;
                        log.error("Can not move the host out of the "
                                 + "maintenance mode " + this.hostName);
                     } else {
                        log.info("Moved the host " + this.hostName
                                 + "out of the maintenance mode");
                     }
                  }
               }
            }
         } else {
            if (!this.icr.moveHostFromClusterToSAHost(this.clusterMor,
                     this.hostMor, this.hostFolder)) {
               cleanUpDone &= false;
               log.error("Can not move the host " + this.hostName
                        + " to be a standalone host");
            } else {
               log.info("Successfully moved the host back as a standalone"
                        + " host " + this.hostName);
            }
         }
      }
      if (this.icr.destroy(this.clusterMor)) {
         log.info("Successfully destroyed the cluster "
                  + this.clusterName);
      } else {
         cleanUpDone &= false;
         log.error("Can not destory the cluster" + this.clusterName);
      }
      if (this.otherHostOrgNetCfg != null) {
         if (!this.ins.updateNetworkConfig(this.otherNwSystemMor,
                  this.otherHostOrgNetCfg, TestConstants.CHANGEMODE_MODIFY)) {
            cleanUpDone &= false;
            log.error("Can not restore the original network config on the "
                     + " host " + this.otherHostName);
         } else {
            log.info("Restored the original network config on the host "
                     + this.otherHostName);
         }
      }
      if (!this.ivm.setVMsState(this.vmPowerMap, false)) {
         cleanUpDone &= false;
         log.error("Can not restore the original VM state");
      } else {
         log.info("Successfully restored the original VM state");
      }
      cleanUpDone &= super.testCleanUp();

      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}