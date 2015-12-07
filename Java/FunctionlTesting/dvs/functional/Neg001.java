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

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Reconfig a VM (VM1) connect it to standalone DVPort and then unregister the
 * VM from the VC inventory. Create another Reconfig (VM2) that connects to the
 * same DVPort, register VM1 back to the VC inventory. Power on the VM's both
 * the VM's should power on. Vmotion VM1 to another host.
 */
public class Neg001 extends FunctionalTestBase
{

   // Private member variable variables
   private ManagedObjectReference otherHostMor = null;
   private ManagedObjectReference otherhostNetworkMor = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState vmPowerState = null;
   private VirtualMachinePowerState otherVMPowerState = null;
   private ManagedObjectReference otherVMMor = null;
   private Datacenter idc = null;
   private VirtualMachineConfigSpec vmOrgConfigSpec = null;
   private VirtualMachineConfigSpec otherVMOrgConfigSpec = null;
   private HostNetworkConfig otherhostOrgNetCfg = null;
   private String hostName = null;
   private String otherHostName = null;
   private String vmName = null;
   private String otherVMName = null;
   private String vmPath = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a VM (VM1) connect it to standalone "
               + "DVPort and then unregister the VM from the VC "
               + "inventory. Reconfigure another VM (VM2) that "
               + "connects to the same DVPort, register VM1 back to "
               + "the VC inventory. Power on the VM's both the VM's "
               + "should power on. Vmotion VM1 to another host.");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return true if setup is successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;
      DVSConfigSpec reconfigSpec = null;
      DVSConfigInfo configInfo = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpec = null;
      Vector<ManagedObjectReference> allHosts = null;
      HostNetworkConfig[] hostNetworkConfig = null;
      List<DistributedVirtualSwitchPortConnection> ports = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      Vector<ManagedObjectReference> hostVMs = null;
      List<VirtualDeviceConfigSpec> vmDeviceConfigSpec = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      int numberOfEthernetCards = 0;
      List<String> freePortKeys = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      int numPorts = 0;

         setupDone = super.testSetUp();
         if (setupDone) {
            this.hostName = this.ihs.getName(this.hostMor);
            allHosts = this.ihs.getAllHost();
            if (allHosts != null && allHosts.size() > 1) {
               for (ManagedObjectReference hostMor : allHosts) {
                  if (hostMor != null
                           && !this.ihs.getName(hostMor).equals(this.hostName)) {
                     this.otherHostMor = hostMor;
                     break;
                  }
               }
               if (this.otherHostMor != null) {
                  this.otherHostName = this.ihs.getName(this.otherHostMor);
                  this.otherhostNetworkMor = this.ins.getNetworkSystem(this.otherHostMor);
                  configInfo = this.iDVS.getConfig(this.dvsMor);
                  reconfigSpec = new DVSConfigSpec();
                  reconfigSpec.setConfigVersion(configInfo.getConfigVersion());
                  hostConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpec.setBacking(new DistributedVirtualSwitchHostMemberPnicBacking());
                  hostConfigSpec.setHost(this.otherHostMor);
                  hostConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  reconfigSpec.getHost().clear();
                  reconfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpec }));
                  setupDone = this.iDVS.reconfigure(this.dvsMor, reconfigSpec);
                  if (setupDone) {
                     configInfo = this.iDVS.getConfig(this.dvsMor);
                     hostNetworkConfig = this.iDVS.getHostNetworkConfigMigrateToDVS(
                              this.dvsMor, this.otherHostMor);
                     if (hostNetworkConfig != null
                              && hostNetworkConfig.length == 2
                              && hostNetworkConfig[0] != null
                              && hostNetworkConfig[1] != null) {
                        this.otherhostOrgNetCfg = hostNetworkConfig[1];
                        setupDone = this.ins.updateNetworkConfig(
                                 this.otherhostNetworkMor,
                                 hostNetworkConfig[0],
                                 TestConstants.CHANGEMODE_MODIFY);
                        if (setupDone) {
                           log.info("successfully updated the host network with"
                                    + " the new configuration "
                                    + this.otherHostName);
                           hostVMs = this.ihs.getAllVirtualMachine(hostMor);
                           if (hostVMs != null && hostVMs.size() >= 2) {
                              this.vmMor = hostVMs.get(0);
                              this.otherVMMor = hostVMs.get(1);
                              this.vmPowerState = this.ivm.getVMState(this.vmMor);
                              this.otherVMPowerState = this.ivm.getVMState(this.otherVMMor);
                              this.vmName = this.ivm.getName(this.vmMor);
                              this.otherVMName = this.ivm.getName(this.otherVMMor);
                              setupDone = this.ivm.setVMState(vmMor, POWERED_OFF, false);
                              if (setupDone) {
                                 log.info("Successfully set the VM "
                                          + this.vmName + " to " + POWERED_OFF);
                                 vmDeviceConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                                          this.vmMor, connectAnchor);
                                 if (vmDeviceConfigSpec != null
                                          && vmDeviceConfigSpec.size() != 0) {
                                    numberOfEthernetCards = vmDeviceConfigSpec.size();
                                    portCriteria = this.iDVS.getPortCriteria(
                                             false, null, null, null, null,
                                             false);
                                    freePortKeys = this.iDVS.fetchPortKeys(
                                             dvsMor, portCriteria);
                                    if (freePortKeys == null
                                             || freePortKeys.size() < numberOfEthernetCards) {
                                       if (freePortKeys == null) {
                                          numPorts = numberOfEthernetCards;
                                       } else {
                                          numPorts = numberOfEthernetCards
                                                   - freePortKeys.size();
                                       }
                                    }
                                    if (numPorts > 0) {
                                       reconfigSpec = new DVSConfigSpec();
                                       reconfigSpec.setConfigVersion( this.iDVS.getConfig(this.dvsMor).getConfigVersion());
                                       reconfigSpec.setNumStandalonePorts(configInfo.getNumStandalonePorts()
                                                + numPorts);
                                       setupDone = this.iDVS.reconfigure(
                                                this.dvsMor, reconfigSpec);
                                       if (setupDone) {
                                          log.info("Successfully reconfigured"
                                                   + " the DVS to have the "
                                                   + "required number of "
                                                   + "standalone ports "
                                                   + numberOfEthernetCards);
                                       } else {
                                          log.error("Can not reconfigure the "
                                                   + "DVS to have the required"
                                                   + " number of standalone "
                                                   + "ports "
                                                   + numberOfEthernetCards);
                                       }
                                       freePortKeys = this.iDVS.fetchPortKeys(
                                                this.dvsMor, portCriteria);
                                    }
                                    if (freePortKeys != null
                                             && freePortKeys.size() >= numberOfEthernetCards) {
                                       ports = new ArrayList<DistributedVirtualSwitchPortConnection>();
                                       for (int i = 0; i < numberOfEthernetCards; i++) {
                                          portConnection = new DistributedVirtualSwitchPortConnection();
                                          portConnection.setPortgroupKey(null);
                                          portConnection.setPortKey(freePortKeys.get(i));
                                          portConnection.setSwitchUuid(this.dvSwitchUUID);
                                          ports.add(portConnection);
                                       }
                                    }
                                    if (ports != null
                                             && ports.size() == numberOfEthernetCards) {
                                       vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                                this.vmMor,
                                                connectAnchor,
                                                ports.toArray(new DistributedVirtualSwitchPortConnection[ports.size()]));
                                       if (vmConfigSpec != null
                                                && vmConfigSpec.length == 2) {
                                          this.vmOrgConfigSpec = vmConfigSpec[1];
                                          setupDone = this.ivm.reconfigVM(
                                                   this.vmMor, vmConfigSpec[0]);
                                          if (setupDone) {
                                             log.info("Successfully reconfgured"
                                                      + " the VM "
                                                      + this.vmName);
                                             this.vmPath = this.ivm.getVMConfigInfo(
                                                      this.vmMor).getFiles().getVmPathName();
                                             setupDone = this.ivm.unregisterVM(this.vmMor);
                                             if (setupDone) {
                                                log.info("Successfully "
                                                         + "unregistered the VM "
                                                         + this.vmName
                                                         + " from the VC inventory");
                                             } else {
                                                setupDone = false;
                                                log.error("Can not unregister the"
                                                         + " VM "
                                                         + this.vmName
                                                         + " from the VC "
                                                         + "inventory");
                                                assertTrue(setupDone, "Setup failed");
                                                return setupDone;
                                             }
                                          } else {
                                             setupDone = false;
                                             log.error("Can not reconfigure the "
                                                      + "VM "
                                                      + this.otherVMName);
                                          }
                                       } else {
                                          log.error("Can not determine the vm "
                                                   + "config spec");
                                       }
                                    } else {
                                       setupDone = false;
                                    }
                                 }
                              } else {
                                 log.error("Can not power off the VM "
                                          + this.vmName);
                              }
                           } else {
                              setupDone = false;
                              log.error("Can not find the required number "
                                       + "of VM's on the host " + this.hostName);
                           }
                        } else {
                           setupDone = false;
                           log.error("Can not update the host with the new "
                                    + "host network configuration "
                                    + this.otherHostName);
                        }
                     } else {
                        setupDone = false;
                        log.error("Can not retrieve the host network config "
                                 + "to update to connect to DVS");
                     }
                  } else {
                     setupDone = false;
                     log.error("Can not add the host to the DVSwitch "
                              + configInfo.getName());
                  }
               }
            } else {
               setupDone = false;
               log.error("Can not find other host in the setup");
            }
            if (setupDone) {
               setupDone = this.ivm.setVMState(this.otherVMMor, POWERED_OFF, false);
               if (setupDone) {
                  log.info("Successfully set the VM " + this.otherVMName
                           + "to " + POWERED_OFF);
                  vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                           this.otherVMMor,
                           connectAnchor,
                           ports.toArray(new DistributedVirtualSwitchPortConnection[ports.size()]));
                  if (vmConfigSpec != null && vmConfigSpec.length == 2) {
                     this.otherVMOrgConfigSpec = vmConfigSpec[1];
                     setupDone = this.ivm.reconfigVM(this.otherVMMor,
                              vmConfigSpec[0]);
                     if (setupDone) {
                        idc = new Datacenter(connectAnchor);
                        this.vmMor = new com.vmware.vcqa.vim.Folder(
                                 super.getConnectAnchor()).registerVm(
                                 this.ivm.getParentNode(this.otherVMMor),
                                 this.vmPath, this.vmName, false,
                                 this.ivm.getResourcePool(this.otherVMMor),
                                 this.hostMor);
                        if (this.vmMor != null) {
                           log.info("Successfully registered the VM back");
                           setupDone = this.ivm.powerOnVMs(
                                    TestUtil.arrayToVector(new ManagedObjectReference[] {
                                             this.vmMor, this.otherVMMor }),
                                    false);
                           if (setupDone) {
                              log.info("Successfully powered on the VM's "
                                       + this.vmName + ", " + this.otherVMName);
                           } else {
                              setupDone = false;
                              log.error("Can not power on the VM's "
                                       + this.vmName + ", " + this.otherVMName);
                           }
                        } else {
                           log.error("Can not register the VM"
                                    + this.vmName + "back to the inventory");
                           setupDone = false;
                        }
                     } else {
                        setupDone = false;
                        log.error("Can not reconfigure the VM "
                                 + this.otherVMName);
                     }
                  } else {
                     setupDone = false;
                     log.error("Can not determine the VM config spec for the VM "
                              + this.otherVMName);
                  }
               } else {
                  setupDone = false;
                  log.error("Can not set the VM " + this.otherVMName
                           + "to " + POWERED_OFF);
               }
            } else {
               setupDone = false;
            }
         }

      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   /**
    * Test method.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Reconfigure a VM (VM1) connect it to standalone "
               + "DVPort and then unregister the VM from the VC "
               + "inventory. Reconfigure another VM (VM2) that "
               + "connects to the same DVPort, register VM1 back to "
               + "the VC inventory. Power on the VM's both the VM's "
               + "should power on. Vmotion VM1 to another host.")
   public void test()
      throws Exception
   {
      boolean testDone = false;
      /*
       * TODO determine the actual method fault
       */
      MethodFault expectedFault = new InvalidArgument();
      try {
         testDone = this.ivm.migrateVM(this.vmMor, null, this.otherHostMor, DEFAULT_PRIORITY, POWERED_ON);
         if (testDone) {
            log.error("Was able to migrate the VM " + this.vmName
                     + "to the other host " + this.otherHostName);
            testDone = false;
         } else {
            log.error("Expecting an exception to be thrown in this case");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         testDone = TestUtil.checkMethodFault(actualMethodFault, expectedFault);
      }
      assertTrue(testDone, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    * @return true if cleanup is successful, false otherwise.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanupDone = true;

         if (this.vmMor != null) {
            if (this.ivm.getHostName(vmMor).equals(this.otherHostMor)) {
               if (this.ivm.migrateVM(vmMor, null, this.hostMor, DEFAULT_PRIORITY, null)) {
                  log.info("Migrated the vm back to the original host "
                           + this.hostName);
               } else {
                  cleanupDone = false;
                  log.error("Can not migrate the vm back to the original host "
                           + this.hostName);
               }
            }
            if (this.ivm.setVMState(this.vmMor, POWERED_OFF, false)) {
               if (this.vmOrgConfigSpec != null && this.vmMor != null) {
                  if (this.ivm.reconfigVM(this.vmMor, this.vmOrgConfigSpec)) {
                     log.info("Successfully reconfigured the VM back to its "
                              + "original config spec " + this.vmName);
                     if (this.ivm.setVMState(this.vmMor, this.vmPowerState,
                              false)) {
                        log.info("Successfully reset the VM "
                                 + this.vmName + "state to "
                                 + this.vmPowerState);
                     } else {
                        cleanupDone &= false;
                        log.error("Can not reset the VM " + this.vmName
                                 + " state" + " to " + this.vmPowerState);
                     }
                  } else {
                     cleanupDone &= false;
                     log.error("Can not reconfigure the VM back to its original"
                              + " config spec " + this.vmName);
                  }
               }
            } else {
               log.error("Can not power off the VM " + this.vmName);
               cleanupDone &= false;
            }
         }

         if (this.otherVMMor != null) {
            if (this.ivm.setVMState(this.otherVMMor, POWERED_OFF, false)) {
               if (this.otherVMOrgConfigSpec != null) {
                  if (this.ivm.reconfigVM(this.otherVMMor,
                           this.otherVMOrgConfigSpec)) {
                     log.info("Successfully reconfigured the VM back to its "
                              + "original config spec " + this.vmName);
                     if (this.ivm.setVMState(this.otherVMMor,
                              this.otherVMPowerState, false)) {
                        log.info("Successfully reset the VM "
                                 + this.otherVMName + "state to "
                                 + this.otherVMPowerState);
                     } else {
                        cleanupDone &= false;
                        log.error("Can not reset the VM "
                                 + this.otherVMName + " state" + " to "
                                 + this.otherVMPowerState);
                     }
                  } else {
                     cleanupDone &= false;
                     log.error("Can not reconfigure the VM back to its original"
                              + " config spec " + this.otherVMName);
                  }
               }
            } else {
               cleanupDone &= false;
               log.error("Can not power off the VM " + this.otherVMName);
            }
         }
         if (this.otherhostOrgNetCfg != null) {
            if (this.ins.updateNetworkConfig(this.otherhostNetworkMor,
                     this.otherhostOrgNetCfg, TestConstants.CHANGEMODE_MODIFY)) {
               log.info("Successfully updated the network Config to its "
                        + "original state " + this.otherHostName);
            } else {
               cleanupDone &= false;
               log.error("Can not update the network config to its original "
                        + "state " + this.otherHostName);
            }
         }
         cleanupDone &= super.testCleanUp();

      assertTrue(cleanupDone, "Cleanup failed");
      return cleanupDone;
   }
}