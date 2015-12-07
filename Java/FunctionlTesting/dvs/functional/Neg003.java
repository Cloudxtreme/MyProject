/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vc.VirtualMachineMovePriority.DEFAULT_PRIORITY;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.List;

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
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Disconnect a host (H1) from the VC, and after a timeout assign a port (P1) on
 * an early binding portgroup that was previously used by a VM(VM1) on the
 * disconnected host to an entity on a host(H2) connected to the DVSwitch in the
 * VC inventory. After a timeout connect the host H1 back. The port that VM1 is
 * connecting to is marked as a conflict port. VMotion VM1 to the host H2.
 */
public class Neg003 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference otherHostMor = null;
   private ManagedObjectReference otherHostNwMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference otherVMMor = null;
   private List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
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

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Disconnect a host (H1) from the VC, and after a "
               + "timeout assign a port (P1) on an early binding "
               + "portgroup that was previously used by a VM(VM1) "
               + "on the disconnected host to an entity on a host(H2)"
               + " connected to the DVSwitch in the VC inventory. "
               + "After a timeout connect the host H1 back. The port"
               + " that VM1 is connecting to is marked as a conflict"
               + " port. VMotion VM1 to the host H2.");
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
      String pgKey = null;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            hostName = this.ihs.getHostName(hostMor);
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
                           pgKey = this.iDVS.addPortGroup(this.dvsMor,
                                    DVPORTGROUP_TYPE_EARLY_BINDING, numCards,
                                    this.getTestId() + "-pg");
                           portCriteria = this.iDVS.getPortCriteria(false,
                                    null, null, new String[] { pgKey }, null,
                                    true);
                           portKeys = this.iDVS.fetchPortKeys(this.dvsMor,
                                    portCriteria);
                           if (setUpDone && portKeys != null
                                    && portKeys.size() >= numCards) {
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
                                 portConnection.setPortKey(portKeys.get(i));
                                 portConnection.setPortgroupKey(pgKey);
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
                                    log.info("Succesfully reconfigured the VM "
                                             + this.vmName);

                                 } else {
                                    log.error("Can not reconfigure the VM "
                                             + this.vmName);
                                    assertTrue(setUpDone, "Setup failed");
                                    return setUpDone;
                                 }
                              }
                           } else {
                              setUpDone = false;
                              log.error("The DVS can not be reconifgured to "
                                       + "have the required number of standalone"
                                       + " ports " + numCards);
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
                        if (setUpDone) {
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
                                       otherHostNwMor, hostNetworkConfig[0],
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
    * Method to test if the the host DVSwitch will be merged onto the existing
    * DVSwitch on the VC, and all the confilcts will be resolved, After the host
    * gets disconnected from the VC.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Disconnect a host (H1) from the VC, and after a "
               + "timeout assign a port (P1) on an early binding "
               + "portgroup that was previously used by a VM(VM1) "
               + "on the disconnected host to an entity on a host(H2)"
               + " connected to the DVSwitch in the VC inventory. "
               + "After a timeout connect the host H1 back. The port"
               + " that VM1 is connecting to is marked as a conflict"
               + " port. VMotion VM1 to the host H2.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      String esxHostName = null;
      int timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      MethodFault expectedFault = new MethodFault();
     
         esxHostName = this.ihs.getHostName(this.hostMor);
         if (esxHostName != null) {
            conn = SSHUtil.getSSHConnection(esxHostName,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD);
            if (conn != null) {
               if (ihs.isEesxHost(this.hostMor)) {
                  testDone = SSHUtil.executeRemoteSSHCommand(conn,
                           TestConstants.EESX_SSHCOMMAND_KILLVPXA);
               } else {
                  testDone = SSHUtil.executeRemoteSSHCommand(conn,
                           TestConstants.SSHCOMMAND_KILLVPXA);
               }

               if (testDone) {
                  log.info("Sleeping for 180 seconds for the host to "
                           + "disconnect");
                  while (this.ihs.isHostConnected(this.hostMor) && timeout > 0) {
                     Thread.sleep(1500);
                     timeout--;
                  }
                  if (!this.ihs.isHostConnected(this.hostMor)) {
                     log.info("Successfully disconnected the host "
                              + this.hostName);
                     vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                              this.otherVMMor,
                              connectAnchor,
                              portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                     if (vmConfigSpec != null && vmConfigSpec.length == 2
                              && vmConfigSpec[0] != null
                              && vmConfigSpec[1] != null) {
                        this.otherVMOldPowerState = this.ivm.getVMState(this.otherVMMor);
                        testDone = this.ivm.setVMState(this.otherVMMor, POWERED_OFF, false);
                        if (testDone) {
                           testDone = this.ivm.reconfigVM(this.otherVMMor,
                                    vmConfigSpec[0]);
                           if (testDone) {
                              log.info("Succesfully reconfigured the VM to use"
                                       + " the DV port " + this.otherVMName);
                              this.otherVMOriginalConfigSpec = vmConfigSpec[1];
                              testDone = this.ivm.setVMState(this.otherVMMor, VirtualMachinePowerState.POWERED_ON, true);
                              if (testDone) {
                                 log.info("Successfully powered on the VM "
                                          + this.otherVMName);
                                 testDone = DVSUtil.checkNetworkConnectivity(
                                          this.ihs.getIPAddress(this.otherHostMor),
                                          this.ivm.getIPAddress(this.otherVMMor));
                                 if (testDone) {
                                    log.info("Successfully verified the network "
                                             + "connectivity to the VM "
                                             + this.otherVMName);
                                    testDone = this.ivm.setVMState(
                                             this.otherVMMor, POWERED_OFF, false);
                                    if (testDone) {
                                       log.info("Succesfully power off the VM "
                                                + this.otherVMName);
                                    } else {
                                       log.error("Can not power off the VM "
                                                + this.otherVMName);
                                       assertTrue(testDone, "Test Failed");
                                       return;
                                    }
                                 } else {
                                    log.error("Can not verify that there is"
                                             + " network connectivity to the VM "
                                             + this.otherVMName);
                                 }
                              } else {
                                 log.error("Can not power on the VM "
                                          + this.otherVMName);
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
                     testDone = false;
                     log.error("The host is still connected");
                  }
               } else {
                  log.error("Can not execute the command on the host");
               }
               if (testDone) {
                  if (!this.ihs.isHostConnected(this.hostMor)) {
                     if (ihs.isEesxHost(this.hostMor)) {
                        testDone = SSHUtil.executeRemoteSSHCommand(conn,
                                 TestConstants.EESX_SSHCOMMAND_STARTVPXA);
                     } else {
                        testDone = SSHUtil.executeRemoteSSHCommand(conn,
                                 TestConstants.SSHCOMMAND_STARTVPXA);
                     }
                     timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;
                     if (testDone) {
                        log.info("Sleeping for 180 seconds for the host to "
                                 + "disconnect");
                        while (!this.ihs.isHostConnected(this.hostMor)
                                 && timeout > 0) {
                           Thread.sleep(1500);
                           timeout--;
                        }
                        if (this.ihs.isHostConnected(hostMor)) {
                           log.info("Successfully reconected the host back to "
                                    + "the VC" + this.hostName);
                           testDone = this.ivm.setVMState(this.vmMor, POWERED_ON, false);
                           if (testDone) {
                              log.info("Successfully powered on the VM "
                                       + this.vmName);
                              try {
                                 testDone = this.ivm.migrateVM(this.vmMor, this.ihs.getResourcePool(
                                                   this.otherHostMor).get(0), this.otherHostMor, DEFAULT_PRIORITY, null);
                                 testDone = false;
                              } catch (Exception mfExcep) {
                                 MethodFault mf = com.vmware.vcqa.util.TestUtil.getFault(mfExcep);
                                 testDone = TestUtil.checkMethodFault(mf,
                                          expectedFault);
                              }
                           } else {
                              log.error("Can not set the VM state to power on "
                                       + this.vmName);
                           }
                        } else {
                           log.error("Can not connect the host back to the VC "
                                    + this.hostName);
                           testDone = false;
                        }
                     } else {
                        log.error("Can not execute the remote command on the "
                                 + "host " + this.hostName);
                     }
                  } else {
                     log.error("The host is still connected "
                              + this.hostName);
                     testDone = false;
                  }
               }
            } else {
               log.error("Can not get the connection to the host "
                        + esxHostName);
            }
         } else {
            log.error("The host name is null");
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
      int timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;
      try {
         if (this.otherVMMor != null) {
            cleanUpDone2 = this.ivm.setVMState(this.otherVMMor, POWERED_OFF, false);
            if (cleanUpDone2) {
               log.info("Successfully powered off the VM "
                        + this.otherVMName);
               if (this.otherVMOriginalConfigSpec != null) {
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
         if (cleanUpDone2) {
            cleanUpDone2 = this.ins.updateNetworkConfig(this.otherHostNwMor,
                     this.otherHostNetworkConfig,
                     TestConstants.CHANGEMODE_MODIFY);
         }
         if (!this.ihs.isHostConnected(this.hostMor)) {
            if (this.conn != null) {
               if (ihs.isEesxHost(this.hostMor)) {
                  cleanUpDone1 = SSHUtil.executeRemoteSSHCommand(conn,
                           TestConstants.EESX_SSHCOMMAND_STARTVPXA);
               } else {
                  cleanUpDone1 = SSHUtil.executeRemoteSSHCommand(conn,
                           TestConstants.SSHCOMMAND_STARTVPXA);
               }

               if (cleanUpDone1) {
                  log.info("Sleeping for 180 seconds for the host to "
                           + "disconnect");
                  while (!this.ihs.isHostConnected(this.hostMor) && timeout > 0) {
                     Thread.sleep(1500);
                     timeout--;
                  }
                  if (this.ihs.isHostConnected(hostMor)) {
                     log.info("Successfully reconected the host back to the VC"
                              + this.hostName);
                  } else {
                     log.error("Can not connect the host back to the VC "
                              + this.hostName);
                     cleanUpDone1 = false;
                  }
               }
            }
         }
         if (this.vmMor != null) {
            cleanUpDone1 &= this.ivm.setVMState(this.vmMor, POWERED_OFF, false);
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
            cleanUpDone &= super.testCleanUp();
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