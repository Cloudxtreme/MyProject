/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * After a host leave(the host got disconnected/ the host was removed from the
 * DVSwitch), after a timeout to be determined, assign a standalone DVPort that
 * was previously used by a VM on the host to be used by another VM on another
 * host that was previously added to the DVSwitch. Power on the VM.
 */
public class Pos010 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference otherHostMor = null;
   private ManagedObjectReference otherHostNwMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference otherVMMor = null;
   private VirtualMachinePowerState otherVMOldPowerState = null;
   private VirtualMachineConfigSpec otherVMOriginalConfigSpec = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private HostNetworkConfig otherHostNetworkConfig = null;
   private String vmName = null;
   private String otherVMName = null;
   private String hostName = null;
   private String otherHostName = null;
   private Connection conn = null;
   private Vector<Object> hostConnectInfo = null;
   private ClusterComputeResource icr = null;
   private List<DistributedVirtualSwitchPortConnection> portConnectionList = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("After a host leave(the host got disconnected/ "
               + "the host was removed from the DVSwitch), after a "
               + "timeout to be determined, assign a standalone "
               + "DVPort that was previously used by a VM on the "
               + "host to be used by another VM on another host that"
               + " was previously added to the DVSwitch. Power on the" + " VM.");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setUpDone = false;
      int numCards = 0;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      List<ManagedObjectReference> allHosts = null;
      List<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<String> portKeys = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DVSConfigSpec configSpec = null;
      DVSConfigInfo configInfo = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      int numPorts = 0;

         setUpDone = super.testSetUp();
         if (setUpDone) {
            this.icr = new ClusterComputeResource(connectAnchor);
            hostName = this.ihs.getHostName(hostMor);
            this.hostConnectInfo = new Vector<Object>();
            this.hostConnectInfo.add(this.ihs.getHostConnectSpec(this.hostMor));
            if (this.ihs.isStandaloneHost(this.hostMor)) {
               this.hostConnectInfo.add(this.ihs.getHostFolder(this.hostMor));
               this.hostConnectInfo.add("SAH");
            } else {
               this.hostConnectInfo.add(this.ihs.getParentNode(this.hostMor));
               this.hostConnectInfo.add("CLH");
            }
            configInfo = this.iDVS.getConfig(this.dvsMor);
            allVms = this.ihs.getVMs(this.hostMor, null);
            if (allVms != null && allVms.size() > 0) {
               this.vmMor = allVms.get(0);
               if (this.vmMor != null) {
                  this.oldPowerState = this.ivm.getVMState(this.vmMor);
                  this.vmName = this.ivm.getVMName(this.vmMor);
                  setUpDone = this.ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                  if (setUpDone) {
                     log.info("Successfully powered off the VM "
                              + this.vmName);
                     vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                              this.vmMor, connectAnchor);
                     if (vdConfigSpec != null) {
                        numCards = vdConfigSpec.size();
                        if (numCards > 0) {
                           portCriteria = this.iDVS.getPortCriteria(false,
                                    null, null, null, null, false);
                           portKeys = this.iDVS.fetchPortKeys(this.dvsMor,
                                    portCriteria);
                           if (portKeys == null) {
                              numPorts = configInfo.getNumStandalonePorts()
                                       + numCards;
                           } else if (portKeys.size() < numCards) {
                              numPorts = configInfo.getNumStandalonePorts()
                                       + (numCards - portKeys.size());
                           }
                           if (numPorts > 0) {
                              configSpec = new DVSConfigSpec();
                              configSpec.setConfigVersion(configInfo.getConfigVersion());
                              configSpec.setNumStandalonePorts(numPorts);
                              setUpDone = this.iDVS.reconfigure(this.dvsMor,
                                       configSpec);
                              if (setUpDone) {
                                 portKeys = this.iDVS.fetchPortKeys(dvsMor,
                                          portCriteria);
                              } else {
                                 log.error("Cannot reconfigure the DVSwitch "
                                          + this.iDVS.getName(this.dvsMor));
                              }
                           }
                           if (setUpDone && portKeys != null
                                    && portKeys.size() >= numCards) {
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
                                 portConnection.setPortKey(portKeys.get(i));
                                 if (this.portConnectionList == null) {
                                    this.portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>();
                                 }
                                 this.portConnectionList.add(portConnection);
                              }
                              vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                       this.vmMor,
                                       connectAnchor,
                                       this.portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[this.portConnectionList.size()]));
                              if (vmConfigSpec != null
                                       && vmConfigSpec.length == 2
                                       && vmConfigSpec[0] != null
                                       && vmConfigSpec[1] != null) {
                                 this.originalVMConfigSpec = vmConfigSpec[1];
                                 setUpDone = this.ivm.reconfigVM(this.vmMor,
                                          vmConfigSpec[0]);
                                 if (setUpDone) {
                                    log.info("Succesfully reconigured the VM "
                                             + this.vmName);

                                 } else {
                                    log.error("Can not reconfigure the VM "
                                             + this.vmName);
                                    assertTrue(setUpDone, "Setup failed");
                                    return setUpDone;
                                 }
                              }
                           }
                        } else {
                           setUpDone = false;
                           log.error("There are no ethernet cards configured"
                                    + " on the VM");
                        }
                     } else {
                        setUpDone = false;
                        log.error("The VM does not have any ethernet cards"
                                 + " configured");
                     }
                  }
               } else {
                  setUpDone = false;
                  log.error("The VM mor object is null");
               }
            } else {
               setUpDone = false;
               log.error("Can not find any VM's on the host");
            }
            if (setUpDone) {
               allHosts = this.ihs.getAllHost();
               if (allHosts != null && allHosts.size() > 1) {
                  for (ManagedObjectReference mor : allHosts) {
                     if (mor != null
                              && !this.hostName.equals(this.ihs.getHostName(mor))) {
                        this.otherHostMor = mor;
                        break;
                     }
                  }
                  if (this.otherHostMor != null) {
                     this.otherHostName = this.ihs.getHostName(this.otherHostMor);
                     this.otherHostNwMor = this.ins.getNetworkSystem(this.otherHostMor);
                     if (this.otherHostNwMor != null) {
                        configInfo = this.iDVS.getConfig(this.dvsMor);
                        configSpec = new DVSConfigSpec();
                        configSpec.setConfigVersion(configInfo.getConfigVersion());
                        hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                        hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                        hostConfigSpecElement.setHost(this.otherHostMor);
                        pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                        pnicBacking.getPnicSpec().clear();
                        pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                        hostConfigSpecElement.setBacking(pnicBacking);
                        configSpec.getHost().clear();
                        configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                        setUpDone = this.iDVS.reconfigure(this.dvsMor,
                                 configSpec);
                        if (setUpDone && this.ins.refresh(this.otherHostNwMor)) {
                           log.info("Succesfully reconfigured the DVS ");
                           hostNetworkConfig = this.iDVS.getHostNetworkConfigMigrateToDVS(
                                    this.dvsMor, this.otherHostMor);
                           if (hostNetworkConfig != null
                                    && hostNetworkConfig.length == 2
                                    && hostNetworkConfig[0] != null
                                    && hostNetworkConfig[1] != null) {
                              log.info("Successfully got the update network "
                                       + "config for the second host");
                              this.otherHostNetworkConfig = hostNetworkConfig[1];
                              setUpDone = this.ins.updateNetworkConfig(
                                       this.otherHostNwMor,
                                       hostNetworkConfig[0],
                                       TestConstants.CHANGEMODE_MODIFY);
                              if (setUpDone) {
                                 log.info("Successfully updated the network "
                                          + "config on the host "
                                          + this.otherHostName);
                                 allVms = this.ihs.getAllVirtualMachine(this.otherHostMor);
                                 if (allVms != null && allVms.size() > 0) {
                                    for (ManagedObjectReference mor : allVms) {
                                       if (mor != null) {
                                          this.otherVMMor = mor;
                                          break;
                                       }
                                    }
                                 }
                                 if (this.otherVMMor != null) {
                                    log.info("Found a VM on the host "
                                             + this.otherHostName);
                                    this.otherVMName = this.ivm.getVMName(this.otherVMMor);
                                    vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                                             this.otherVMMor, connectAnchor);
                                    if (vdConfigSpec != null
                                             && vdConfigSpec.size() > 0) {
                                       log.info("Found valid ethernet "
                                                + "adapters on the VM "
                                                + this.otherVMName);
                                    } else {
                                       setUpDone = false;
                                       log.error("Can not find valid ethernet"
                                                + " adapters on the VM "
                                                + this.otherVMName);
                                    }
                                 } else {
                                    setUpDone = false;
                                    log.error("Can not get a valid vm on the "
                                             + "other host "
                                             + this.otherHostName);
                                 }
                              } else {
                                 log.error("Can not update the network config");
                              }
                           } else {
                              setUpDone = false;
                              log.error("Can not get the update network config");
                           }
                        } else {
                           log.error("Cannot reconfigure the DVS");
                        }
                     } else {
                        setUpDone = false;
                        log.error("Can not get the network sytem for the host");
                     }

                  } else {
                     setUpDone = false;
                     log.error("Can not find another host in the VC inventory");
                  }
               } else {
                  setUpDone = false;
                  log.error("Can not find enough hosts in the VC inventory");
               }
            }
         }

      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Method that performs the test.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "After a host leave(the host got disconnected/ "
               + "the host was removed from the DVSwitch), after a "
               + "timeout to be determined, assign a standalone "
               + "DVPort that was previously used by a VM on the "
               + "host to be used by another VM on another host that"
               + " was previously added to the DVSwitch. Power on the" + " VM.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      boolean checkGuest = false;
      if (this.ihs.disconnectHost(this.hostMor)
               && this.ihs.destroy(this.hostMor)) {
         log.info("Successfullr removed the host from the VC" + " inventory");

         vmConfigSpec =
                  DVSUtil
                           .getVMConfigSpecForDVSPort(
                                    this.otherVMMor,
                                    connectAnchor,
                                    portConnectionList
                                             .toArray(new DistributedVirtualSwitchPortConnection[portConnectionList
                                                      .size()]));
         if (vmConfigSpec != null && vmConfigSpec.length == 2
                  && vmConfigSpec[0] != null && vmConfigSpec[1] != null) {
            this.otherVMOldPowerState = this.ivm.getVMState(this.otherVMMor);
            testDone =
                     this.ivm.setVMState(this.otherVMMor, VirtualMachinePowerState.POWERED_OFF, false);
            if (testDone) {
               testDone = this.ivm.reconfigVM(this.otherVMMor, vmConfigSpec[0]);
               if (testDone) {
                  log.info("Succesfully reconfigured the VM to use"
                           + " the DV port " + this.otherVMName);
                  this.otherVMOriginalConfigSpec = vmConfigSpec[1];
                  if (DVSTestConstants.CHECK_GUEST) {
                     checkGuest = true;
                  }
                  testDone =
                           this.ivm.setVMState(this.otherVMMor, VirtualMachinePowerState.POWERED_ON, checkGuest);
                  if (testDone && checkGuest) {
                     log.info("Successfully powered on the VM "
                              + this.otherVMName);
                     testDone =
                              DVSUtil.checkNetworkConnectivity(this.ihs
                                       .getIPAddress(this.otherHostMor),
                                       this.ivm.getIPAddress(this.otherVMMor),
                                       true);
                     assertTrue(testDone, "Test Failed");
                  } else {
                     log.error("Can not power on the VM " + this.otherVMName);
                  }
               } else {
                  log.error("Can not reconfigure to use the DVPort");
               }
            }
         } else {
            testDone = false;
            log.error("Can not retrieve the updated and original"
                     + " vm config spec");
         }
      } else {
         log.error("Can not remove the disconnected host " + this.hostName);
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
      boolean cleanUpDone1 = true;
      boolean cleanUpDone2 = true;
      boolean cleanUpDone = false;
      ManagedObjectReference tempMor = null;

      try {
         if (this.otherVMMor != null) {
            cleanUpDone2 = this.ivm.setVMState(this.otherVMMor, VirtualMachinePowerState.POWERED_OFF, false);
            if (cleanUpDone2) {
               log.info("Successfully powered off the VM "
                        + this.otherVMName);
               if (this.originalVMConfigSpec != null) {
                  cleanUpDone2 &= this.ivm.reconfigVM(this.otherVMMor,
                           this.otherVMOriginalConfigSpec);
                  if (cleanUpDone2) {
                     log.info("Reconfigured the VM to the original "
                              + "configuration");
                  } else {
                     log.error("Can not restore the VM to the original "
                              + "configuration");
                  }
               }
               if (cleanUpDone2 && this.otherVMOldPowerState != null) {
                  cleanUpDone2 &= this.ivm.setVMState(this.otherVMMor,
                           this.otherVMOldPowerState, false);
                  if (cleanUpDone2) {
                     log.info("Successfully restored the original power state"
                              + " for the VM " + this.otherVMName);
                  } else {
                     log.error("Can not restore the original power state for"
                              + " the VM " + this.otherVMName);
                  }
               }
            } else {
               log.error("Can not power off the VM " + this.otherVMName);
            }
         }
         if (cleanUpDone2 && this.otherHostNetworkConfig != null) {
            cleanUpDone2 = this.ins.updateNetworkConfig(this.otherHostNwMor,
                     this.otherHostNetworkConfig,
                     TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         cleanUpDone2 &= false;
      }
      try {
         if (this.hostName != null) {
            tempMor = this.ihs.getHost(this.hostName);
            if (tempMor == null && this.hostConnectInfo != null) {
               if (this.hostConnectInfo.get(2) != null
                        && this.hostConnectInfo.get(2).equals("SAH")) {
                  this.hostMor = this.ihs.addStandaloneHost(
                           (ManagedObjectReference) this.hostConnectInfo.get(1),
                           (HostConnectSpec) this.hostConnectInfo.get(0), null,
                           true);
               } else {
                  this.hostMor = this.icr.addHost(
                           (ManagedObjectReference) this.hostConnectInfo.get(1),
                           (HostConnectSpec) this.hostConnectInfo.get(0), true,
                           null);
               }
               if (this.hostMor != null) {
                  log.info("Successfully added the host back to the VC "
                           + this.hostName);
                  this.vmMor = this.ivm.getVM(this.vmName);
                  if (this.vmMor != null) {
                     log.info("Got the updated reference for the VM "
                              + this.vmName);
                  } else {
                     cleanUpDone1 &= false;
                     log.error("Can not get the VM by name "
                              + this.vmName);
                  }
               } else {
                  cleanUpDone1 = false;
                  log.error("Can not add the host back to the VC "
                           + this.hostName);
               }
            }
         }

         if (cleanUpDone1 && this.vmMor != null) {
            cleanUpDone1 &= this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false);
            if (cleanUpDone1) {
               log.info("Successfully powered off the VM " + this.vmName);
               if (this.originalVMConfigSpec != null) {
                  cleanUpDone1 &= this.ivm.reconfigVM(this.vmMor,
                           this.originalVMConfigSpec);
                  if (cleanUpDone1) {
                     log.info("Reconfigured the VM to the original "
                              + "configuration");
                  } else {
                     log.error("Can not restore the VM to the original "
                              + "configuration");
                  }
               }
               if (cleanUpDone1) {
                  cleanUpDone1 &= this.ivm.setVMState(this.vmMor,
                           this.oldPowerState, false);
                  if (cleanUpDone1) {
                     log.info("Successfully restored the original power state"
                              + " for the VM " + this.vmName);
                  } else {
                     log.error("Can not restore the original power state for"
                              + " the VM " + this.vmName);
                  }
               }
            } else {
               log.error("Can not power off the VM " + this.vmName);
            }
         }

         cleanUpDone = cleanUpDone1 && cleanUpDone2;
         if (cleanUpDone) {
            assertTrue(this.iManagedEntity.destroy(dvsMor),
                     "Destroyed the vDS...");
         } else {
            log.error("Can not update the other host network config to "
                     + "the original host network");
         }
      } catch (Exception e) {
         cleanUpDone = false;
         TestUtil.handleException(e);
      } finally {
         try {
            if (this.conn != null) {
               cleanUpDone &= SSHUtil.closeSSHConnection(this.conn);
            }
         } catch (Exception ex) {
            TestUtil.handleException(ex);
            cleanUpDone = false;
         }
      }
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}
