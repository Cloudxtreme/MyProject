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
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.ArrayList;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Clone a VM from a powered off VM(VM1) that is connected to an late binding
 * port group, that has twice the number of ports than those used by the VM(VM1)
 * connected to the DVSwitch. The VM can be powered on. The VM will have network
 * connectivity.
 */
public class Pos026 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference vmPoolMor = null;
   private ManagedObjectReference cloneVMMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private String cloneVMName = null;
   private String pgKey = null;
   private static final boolean checkGuest = DVSTestConstants.CHECK_GUEST;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Clone a VM from a powered off VM(VM1) that is "
               + "connected to an late binding port group, that has "
               + "twice the number of ports than those used by the "
               + "VM(VM1) connected to the DVSwitch. The VM can be "
               + "powered on. The VM will have network connectivity.");
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
      int numCards = 0;
      String ipAddress = null;
      boolean setUpDone = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<ManagedObjectReference> allVms = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;

     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            allVms = this.ihs.getVMs(this.hostMor, null);
            if (allVms != null && allVms.size() > 0) {
               this.vmMor = allVms.get(0);
               if (this.vmMor != null) {
                  this.oldPowerState = this.ivm.getVMState(this.vmMor);
                  this.vmName = this.ivm.getVMName(this.vmMor);
                  this.vmPoolMor = this.ivm.getResourcePool(vmMor);
                  setUpDone = this.ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                  if (setUpDone) {
                     log.info("Succesfully powered off the vm "
                              + this.vmName);
                     vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                              this.vmMor, connectAnchor);
                     if (vdConfigSpec != null) {
                        numCards = vdConfigSpec.size();
                        if (numCards > 0) {
                           this.pgKey = this.iDVS.addPortGroup(this.dvsMor,
                                    DVPORTGROUP_TYPE_LATE_BINDING, numCards,
                                    this.getTestId() + "-pg1");
                           if (this.pgKey != null) {
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setPortgroupKey(this.pgKey);
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
                                 if (portConnectionList == null) {
                                    portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>();
                                 }
                                 portConnectionList.add(portConnection);
                              }
                              vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                       this.vmMor,
                                       connectAnchor,
                                       portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                              if (vmConfigSpec != null
                                       && vmConfigSpec.length == 2
                                       && vmConfigSpec[0] != null
                                       && vmConfigSpec[1] != null) {
                                 this.originalVMConfigSpec = vmConfigSpec[1];
                                 setUpDone = this.ivm.reconfigVM(this.vmMor,
                                          vmConfigSpec[0]);
                                 if (setUpDone) {
                                    log.info("Successfully "
                                             + "reconfigured"
                                             + " the VM to use the "
                                             + "DV Ports");
                                    setUpDone = this.ivm.setVMState(this.vmMor, POWERED_ON, checkGuest);
                                    if (setUpDone) {
                                       log.info("Succesfully powered on the "
                                                + "VM " + this.vmName);
                                       if (checkGuest) {
                                          ipAddress = this.ivm.getIPAddress(this.vmMor);
                                          if (ipAddress != null) {
                                             setUpDone = DVSUtil.checkNetworkConnectivity(
                                                      this.ihs.getIPAddress(this.hostMor),
                                                      ipAddress, true);
                                             if (setUpDone) {
                                                log.info("Successfully verified"
                                                         + " that the VM has "
                                                         + "network connectivity");
                                             } else {
                                                log.error("Can not verify the "
                                                         + "network connectivity"
                                                         + " on the VM "
                                                         + this.vmName);
                                             }
                                          } else {
                                             setUpDone = false;
                                             log.error("Can not retrieve the ip"
                                                      + "address for the VM");
                                          }
                                       }
                                       if (setUpDone) {
                                          setUpDone = this.ivm.setVMState(
                                                   this.vmMor, POWERED_OFF, false);
                                          if (setUpDone) {
                                             log.info("Powered off the VM "
                                                      + this.vmName);
                                          } else {
                                             log.error("Can not power off"
                                                      + " the VM "
                                                      + this.vmName);
                                          }
                                       }
                                    } else {
                                       log.error("Can not power on the VM "
                                                + this.vmName);
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
                              log.error("Can not add the port group to the DVS");
                           }
                        } else {
                           setUpDone = false;
                           log.error("There are no ethernet cards"
                                    + " configured on the vm");
                        }
                     } else {
                        setUpDone = false;
                        log.error("The vm does not have any ethernet"
                                 + " cards configured");
                     }
                  }
               } else {
                  setUpDone = false;
                  log.error("The vm mor object is null");
               }
            } else {
               setUpDone = false;
               log.error("Can not find any vm's on the host");
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
   @Test(description = "Clone a VM from a powered off VM(VM1) that is "
               + "connected to an late binding port group, that has "
               + "twice the number of ports than those used by the "
               + "VM(VM1) connected to the DVSwitch. The VM can be "
               + "powered on. The VM will have network connectivity.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking = null;
      VirtualMachineCloneSpec cloneSpec = null;
      VirtualMachineRelocateSpec relocateSpec = null;
      String ipAddress = null;
     
         cloneSpec = new VirtualMachineCloneSpec();
         cloneSpec.setTemplate(false);
         cloneSpec.setPowerOn(false);
         cloneSpec.setCustomization(null);
         relocateSpec = new VirtualMachineRelocateSpec();
         relocateSpec.setHost(this.hostMor);
         relocateSpec.setPool(this.vmPoolMor);
         relocateSpec.setDatastore(this.ihs.getDatastoresInfo(this.hostMor).get(
                  0).getDatastoreMor());
         cloneSpec.setLocation(relocateSpec);
         this.cloneVMMor = this.ivm.cloneVM(this.vmMor, this.ivm.getVMFolder(),
                  this.vmName + "-Clone1", cloneSpec);
         if (this.cloneVMMor != null) {
            testDone = true;
            this.cloneVMName = this.ivm.getVMName(this.cloneVMMor);
            vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                     this.cloneVMMor, connectAnchor);
            if (vdConfigSpec != null && vdConfigSpec.size() > 0) {
               for (VirtualDeviceConfigSpec config : vdConfigSpec) {
                  if (config != null && config.getDevice() != null
                           && config.getDevice().getBacking() != null) {
                     if (config.getDevice().getBacking() instanceof VirtualEthernetCardDistributedVirtualPortBackingInfo) {
                        dvPortBacking = (VirtualEthernetCardDistributedVirtualPortBackingInfo) config.getDevice().getBacking();
                        if (dvPortBacking.getPort() != null
                                 && this.pgKey.equals(dvPortBacking.getPort().getPortgroupKey())) {
                           testDone = true;
                           log.info("Successfully verified the port "
                                    + "connection has the late binding "
                                    + "portgroup key");
                           break;
                        }
                     }
                  }
               }
            }
            if (testDone) {
               testDone = this.ivm.setVMState(this.cloneVMMor, POWERED_ON, checkGuest);
               if (testDone) {
                  log.info("Successfully powered on the VM "
                           + this.cloneVMName);
                  ConnectAnchor hostConnectAnchor = new ConnectAnchor(
                           this.ihs.getHostName(hostMor),
                           data.getInt(TestConstants.TESTINPUT_PORT));
                  assertTrue(
                           InternalDVSHelper.verifyPortPersistenceLocation(
                                    hostConnectAnchor,
                                    this.ivm.getName(this.cloneVMMor),
                                    this.dvSwitchUUID),
                           "Verification for PortPersistenceLocation failed");
                  DVSUtil.reconfigureWithTrafficShapingPolicy(connectAnchor,
                           this.dvsMor);
                  hostConnectAnchor = new ConnectAnchor(
                           this.ihs.getHostName(hostMor),
                           data.getInt(TestConstants.TESTINPUT_PORT));
                  assertTrue(
                           InternalDVSHelper.verifyPortPersistenceLocation(
                                    hostConnectAnchor,
                                    this.ivm.getName(this.cloneVMMor),
                                    this.dvSwitchUUID),
                           "Verification for PortPersistenceLocation failed");
                  if (checkGuest) {
                     ipAddress = this.ivm.getIPAddress(this.cloneVMMor);
                     if (ipAddress != null) {
                        log.info("the VM has a valid ip "
                                 + this.cloneVMName);
                        testDone = DVSUtil.checkNetworkConnectivity(
                                 this.ihs.getIPAddress(this.hostMor),
                                 ipAddress, true);
                        assertTrue(testDone, "Test Failed");
                     } else {
                        log.error("The VM doesnot have a valid ip "
                                 + this.cloneVMName);
                     }
                  }
               } else {
                  log.error("Can not power on the VM "
                           + this.cloneVMName);
               }
            }
         } else {
            testDone = false;
            log.error("Can not clone a VM from the VM " + this.vmName);
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
     
         if (this.vmMor != null) {
            cleanUpDone &= this.ivm.setVMState(this.vmMor, POWERED_OFF, false);
            if (cleanUpDone) {
               log.info("Successfully powered off the vm " + this.vmName);
               if (this.originalVMConfigSpec != null) {
                  cleanUpDone &= this.ivm.reconfigVM(this.vmMor,
                           this.originalVMConfigSpec);
                  if (cleanUpDone) {
                     log.info("Reconfigured the VM to the original "
                              + "configuration");
                  } else {
                     log.error("Can not restore the VM to the original"
                              + " configuration");
                  }
               }
               if (cleanUpDone) {
                  if (this.oldPowerState != null) {
                     cleanUpDone &= this.ivm.setVMState(this.vmMor,
                              this.oldPowerState, false);
                     if (cleanUpDone) {
                        log.info("Successfully restored the original power "
                                 + "state for the vm " + this.vmName);
                     } else {
                        log.error("Can not restore the original power "
                                 + "state for the VM " + this.vmName);
                     }
                  }
               }
            } else {
               log.error("Can not power off the VM " + this.vmName);
            }
         }
         if (this.cloneVMMor != null && cleanUpDone) {
            cleanUpDone &= this.ivm.setVMState(this.cloneVMMor, POWERED_OFF, false);
            if (cleanUpDone) {
               cleanUpDone &= this.ivm.destroy(this.cloneVMMor);
               if (cleanUpDone) {
                  log.info("Successfully destroyed the VM "
                           + this.cloneVMName);
               } else {
                  log.error("Can not destroy the VM " + this.cloneVMName);
               }
            } else {
               log.error("Can not set the VM power state to powered off");
            }
         }
         if (cleanUpDone) {
            cleanUpDone &= super.testCleanUp();
         }
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}