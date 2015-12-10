/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.vmsnapshot;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.ArrayList;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.vm.Snapshot;

import dvs.functional.FunctionalTestBase;

/**
 * Base class for the vmsnapshot tests for the ithe
 */
public abstract class VMSFunctionalTestBase extends FunctionalTestBase
{
   protected ManagedObjectReference snapshotMor = null;
   protected VirtualMachinePowerState oldPowerState = null;
   protected VirtualMachinePowerState otherVMOldPowerState = null;
   protected VirtualMachineConfigSpec originalVMConfigSpec = null;
   protected VirtualMachineConfigSpec otherVMOriginalConfigSpec = null;
   protected ManagedObjectReference vmMor = null;
   protected ManagedObjectReference otherVMMor = null;
   protected String vmName = null;
   protected String otherVMName = null;
   protected String pgKey = null;
   protected boolean reusePorts = false;
   protected boolean leaveFreePorts = false;
   protected String portgroupType = null;
   private List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
   protected boolean isVMCreated = false;;
   protected boolean isOtherVMCreated = false;;

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
      DVSConfigSpec configSpec = null;
      DVSConfigInfo configInfo = null;
      List<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      int numCards = 0;
      int numPorts = 0;
      List<String> freePorts = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      VirtualMachineConfigSpec tempVmConfigSpec = null;
      int portsAdded = 0;

         setUpDone = super.testSetUp();
         if (setUpDone) {
            configInfo = this.iDVS.getConfig(this.dvsMor);
            allVms = this.ihs.getVMs(this.hostMor, null);
            if (allVms == null) {
               tempVmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor,
                        hostMor,
                        TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                        this.getTestId() + "-VM");
               if (tempVmConfigSpec != null) {
                  this.vmMor = new Folder(super.getConnectAnchor()).createVM(
                           this.ivm.getVMFolder(), tempVmConfigSpec,
                           this.ihs.getResourcePool(this.hostMor).get(0),
                           this.hostMor);
                  if (this.vmMor != null) {
                     this.isVMCreated = true;

                  }
               }
               if (this.reusePorts) {
                  tempVmConfigSpec = DVSUtil.buildDefaultSpec(connectAnchor,
                           hostMor,
                           TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                           this.getTestId() + "-OTHERVM");
                  this.otherVMMor = new Folder(super.getConnectAnchor()).createVM(
                           this.ivm.getVMFolder(), tempVmConfigSpec,
                           this.ihs.getResourcePool(this.hostMor).get(0),
                           this.hostMor);
                  if (this.otherVMMor != null) {
                     this.isOtherVMCreated = true;
                     this.otherVMName = this.ivm.getVMName(this.otherVMMor);
                     this.otherVMOldPowerState = this.ivm.getVMState(this.otherVMMor);
                  }

               }
            } else if (allVms != null
                     && ((reusePorts && allVms.size() > 1) || allVms.size() > 0)) {
               this.vmMor = allVms.get(0);
               if (this.reusePorts) {
                  this.otherVMMor = allVms.get(1);
                  this.otherVMName = this.ivm.getVMName(this.otherVMMor);
                  this.otherVMOldPowerState = this.ivm.getVMState(this.otherVMMor);
               }
            } else {
               setUpDone = false;
               log.error("Can not find any vm's on the host");
            }

            if (this.vmMor != null
                     && (!this.reusePorts || this.otherVMMor != null)) {
               this.oldPowerState = this.ivm.getVMState(this.vmMor);
               this.vmName = this.ivm.getVMName(this.vmMor);
               setUpDone = this.ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
               if (setUpDone) {
                  log.info("Succesfully powered off the vm "
                           + this.vmName);
                  vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                           this.vmMor, connectAnchor);
                  if (vdConfigSpec != null) {
                     numCards = vdConfigSpec.size();
                     if (numCards > 0) {
                        if (this.leaveFreePorts) {
                           numPorts = 2 * numCards;
                        } else {
                           numPorts = numCards;
                        }
                        if (this.portgroupType != null) {
                           this.pgKey = this.iDVS.addPortGroup(this.dvsMor,
                                    this.portgroupType, numPorts,
                                    this.getTestId() + "-pg1");
                           if (this.pgKey != null) {
                              log.info("Successfully added the portgroup to "
                                       + "the DVS");
                              portCriteria = new DistributedVirtualSwitchPortCriteria();
                              portCriteria.setConnected(false);
                              portCriteria.setInside(true);
                              portCriteria.getPortgroupKey().clear();
                              portCriteria.getPortgroupKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { this.pgKey }));
                              freePorts = this.iDVS.fetchPortKeys(this.dvsMor,
                                       portCriteria);
                           } else {
                              setUpDone = false;
                              log.error("Can not add the portgroup to the"
                                       + " DVS");
                           }
                        } else {
                           portCriteria = new DistributedVirtualSwitchPortCriteria();
                           portCriteria.setConnected(false);
                           portCriteria.setInside(false);
                           freePorts = this.iDVS.fetchPortKeys(this.dvsMor,
                                    portCriteria);
                           if (freePorts == null || freePorts.size() < numPorts) {
                              if (freePorts == null) {
                                 portsAdded = numPorts;
                              } else {
                                 portsAdded = numPorts - freePorts.size();
                              }
                              configSpec = new DVSConfigSpec();
                              configSpec.setNumStandalonePorts(configInfo.getNumStandalonePorts()
                                       + portsAdded);
                              configSpec.setConfigVersion(configInfo.getConfigVersion());
                              setUpDone = this.iDVS.reconfigure(this.dvsMor,
                                       configSpec);
                              if (setUpDone) {
                                 freePorts = this.iDVS.fetchPortKeys(
                                          this.dvsMor, portCriteria);
                              } else {
                                 log.error("Cnn not reconfigure the DVS");
                              }
                           }
                        }
                        if (setUpDone) {
                           if ((freePorts != null && freePorts.size() >= numPorts)
                                    || (this.portgroupType != null && this.portgroupType.equals(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL))) {
                              this.portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                       numCards);
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 if (this.pgKey != null) {
                                    portConnection.setPortgroupKey(this.pgKey);
                                 }
                                 if ((this.portgroupType != null && !this.portgroupType.equals(DVPORTGROUP_TYPE_EPHEMERAL))
                                          || this.portgroupType == null) {
                                    portConnection.setPortKey(freePorts.get(i));
                                 }
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
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
                                    log.info("Successfully reconfigured"
                                             + " the VM to use the DV Ports");
                                    if (this.portgroupType != null
                                             && (this.portgroupType.equals(DVPORTGROUP_TYPE_LATE_BINDING) || this.portgroupType.equals(DVPORTGROUP_TYPE_EPHEMERAL))) {
                                       setUpDone = this.ivm.setVMState(
                                                this.vmMor, POWERED_ON, false);
                                       if (this.otherVMMor != null) {
                                          setUpDone = this.ivm.setVMState(
                                                   this.otherVMMor, POWERED_ON, false);
                                       }
                                    }
                                 } else {
                                    log.error("Can not reconfigure"
                                             + " the VM to use the"
                                             + " DV Ports");
                                 }
                              } else {
                                 setUpDone = false;
                                 log.error("Can not generate the VM config"
                                          + " spec to connect to the DVPort");
                              }
                           } else {
                              setUpDone = false;
                              log.error("Can not find enough free "
                                       + "standalone ports to reconfigure"
                                       + " the VM");
                           }
                        } else {
                           log.error("Cannot reconfigure the DVSwitch with"
                                    + " the required number of ports");
                        }
                     } else {
                        setUpDone = false;
                        log.error("There are no ethernet cards configured"
                                 + " on the vm");
                     }
                  } else {
                     setUpDone = false;
                     log.error("The vm does not have any ethernet cards"
                              + " configured");
                  }
               }
            } else {
               setUpDone = false;
               log.error("The vm mor object is null");
            }

         }

      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Test Method.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      boolean otherVMConfigured = false;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      String ipAddress = null;

         this.snapshotMor = this.ivm.createSnapshot(this.vmMor, this.vmName
                  + "-snapshot1", null, false, false);
         if (this.snapshotMor != null) {
            log.info("Successfully took the snapshot of the VM current "
                     + "state " + this.vmName);
            if (this.ivm.reconfigVM(this.vmMor, this.originalVMConfigSpec)) {
               log.info("Successfully reconfigured the VM to disconnect from"
                        + " the DVS " + this.vmName);
               if (this.reusePorts) {
                  vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                           this.otherVMMor,
                           connectAnchor,
                           this.portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                  if (vmConfigSpec != null && vmConfigSpec.length == 2
                           && vmConfigSpec[0] != null
                           && vmConfigSpec[1] != null) {
                     this.otherVMOriginalConfigSpec = vmConfigSpec[1];
                     if (this.ivm.reconfigVM(this.otherVMMor, vmConfigSpec[0])) {
                        log.info("Successfully reconfigured the VM to connect to "
                                 + "the used ports " + this.otherVMName);
                        if (this.portgroupType != null
                                 && (this.portgroupType.equals(DVPORTGROUP_TYPE_LATE_BINDING) || this.portgroupType.equals(DVPORTGROUP_TYPE_EPHEMERAL))) {
                           otherVMConfigured = this.ivm.setVMState(
                                    this.otherVMMor, POWERED_ON, false);
                        } else {
                           otherVMConfigured = true;
                        }
                     } else {
                        log.error("Can not reconfigure the VM to connect to "
                                 + "the used ports " + this.otherVMName);
                     }
                  } else {
                     log.error("Can not get the delta config spec for the other "
                              + "VM to connect to the used ports "
                              + this.otherVMName);
                  }
               }
               if ((this.reusePorts && otherVMConfigured) || !this.reusePorts) {
                  if (new com.vmware.vcqa.vim.vm.Snapshot(
                           super.getConnectAnchor()).revertToSnapshot(
                           snapshotMor, null, false)) {
                     log.info("Reverted the VM to its snapshot taken earlier "
                              + this.vmName);
                     testDone = this.ivm.verifyPowerOps(vmMor, false);
                     if (testDone) {
                        log.info("Successfully verified the power ops of the VM "
                                 + this.vmName);
                        if (this.ivm.setVMState(this.vmMor, POWERED_ON, false)) {
                           log.info("Successfully powered on the VM "
                                    + this.vmName);
                           if (!isVMCreated) {
                              ipAddress = this.ivm.getIPAddress(this.vmMor);
                              if (((this.reusePorts && this.leaveFreePorts) || !this.reusePorts)
                                       && ipAddress != null) {
                                 testDone = DVSUtil.checkNetworkConnectivity(
                                          this.ihs.getIPAddress(this.hostMor),
                                          ipAddress);
                              } else if (ipAddress == null
                                       && !this.leaveFreePorts
                                       && this.reusePorts) {
                                 log.info("The VM does not get any network "
                                          + "connectivity " + this.vmName);
                              } else {
                                 testDone = false;
                                 log.error("The VM is in an invalid state "
                                          + this.vmName);
                              }
                           } else {
                              testDone = true;
                           }

                        } else {
                           testDone = false;
                           log.error("Can not power on the VM "
                                    + this.vmName);
                        }
                     } else {
                        log.error("Can not verify the power ops of the VM "
                                 + this.vmName);
                     }
                  } else {
                     log.error("Can not restore the vm to its snapshot state");
                  }
               }
            } else {
               log.error("Can not reconfigure the VM back to its original "
                        + "configuration " + this.vmName);
            }
         } else {
            log.error("Can not take the snap host for the VM "
                     + this.vmName);
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

         if (this.isVMCreated && vmMor != null
                  && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            cleanUpDone &= this.ivm.destroy(this.vmMor);
         } else {
            if (this.vmMor != null) {
               cleanUpDone &= restoreVM(this.vmMor, this.originalVMConfigSpec,
                        this.oldPowerState, this.vmName);
               if (this.snapshotMor != null) {
                  cleanUpDone &= new Snapshot(super.getConnectAnchor()).removeSnapshot(
                           this.snapshotMor, false, false);
               }
            }
         }
         if (this.isOtherVMCreated && otherVMMor != null
                  && ivm.setVMState(otherVMMor, POWERED_OFF, false)) {
            cleanUpDone &= this.ivm.destroy(this.otherVMMor);
         } else {
            if (this.otherVMMor != null) {
               cleanUpDone &= restoreVM(this.otherVMMor,
                        this.otherVMOriginalConfigSpec,
                        this.otherVMOldPowerState, this.otherVMName);
            }
         }
         cleanUpDone &= super.testCleanUp();

      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }

   /**
    * Restores the VM config spec and the power state to the values passed.
    *
    * @param virtualMachineMor ManagedObjectReference of the VM.
    * @param vmConfigSpec VirtualMachineConfigSpec of the VM.
    * @param vmPowerState VirtualMachinePowerState of the VM.
    * @param virtualMachineName String VM name.
    * @return boolean true if successful, false otherwise
    * @throws MethodFault, Exception
    */
   private boolean restoreVM(ManagedObjectReference virtualMachineMor,
                             VirtualMachineConfigSpec vmConfigSpec,
                             VirtualMachinePowerState vmPowerState,
                             String virtualMachineName)
      throws Exception
   {
      boolean rval = true;
      if (vmConfigSpec != null) {
         if (this.ivm.reconfigVM(virtualMachineMor, vmConfigSpec)) {
            log.info("Reconfigured the VM to the original configuration"
                     + virtualMachineName);
         } else {
            rval = false;
            log.error("Can not restore the VM to the original"
                     + " configuration " + virtualMachineName);
         }
      }
      if (vmPowerState != null) {
         if (this.ivm.setVMState(virtualMachineMor, vmPowerState, false)) {
            log.info("Successfully restored the original "
                     + "power state for the vm " + virtualMachineName);
         } else {
            rval = false;
            log.error("Can not restore the original power state for"
                     + " the VM " + virtualMachineName);
         }
      }
      return rval;
   }
}
