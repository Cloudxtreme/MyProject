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
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.Datastore;

/**
 * Convert a VM that connects to a standalone DVPort into template. The template
 * will not contain any DVPort information to connect to. Clone two VM's from
 * the template and power on the two VM's. The VM's will not have any network
 * connectivity.
 */
public class Pos012 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference vmPoolMor = null;
   private ManagedObjectReference cloneVMMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private String cloneVMName = null;
   private static final boolean checkGuest = DVSTestConstants.CHECK_GUEST;
   private ConnectAnchor hostConnectAnchor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Convert a VM that connects to a standalone DVPort "
               + "into template. The template will not contain any"
               + " DVPort information to connect to. Clone two VM's"
               + " from the template and power on the two VM's. "
               + "The VM's will not have any network connectivity.");
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
      List<String> freePorts = null;
      DVSConfigSpec configSpec = null;
      DVSConfigInfo configInfo = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<ManagedObjectReference> allVms = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            configInfo = this.iDVS.getConfig(this.dvsMor);
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
                           portCriteria = this.iDVS.getPortCriteria(false,
                                    null, null, null, null, false);
                           freePorts = this.iDVS.fetchPortKeys(this.dvsMor,
                                    portCriteria);
                           if (freePorts != null) {
                              if (freePorts.size() < numCards) {
                                 configSpec = new DVSConfigSpec();
                                 configSpec.setNumStandalonePorts(configInfo.getNumStandalonePorts()
                                          + (numCards - freePorts.size()));
                                 configSpec.setConfigVersion(configInfo.getConfigVersion());
                              }
                           } else {
                              configSpec = new DVSConfigSpec();
                              configSpec.setNumStandalonePorts(configInfo.getNumStandalonePorts()
                                       + numCards);
                              configSpec.setConfigVersion(configInfo.getConfigVersion());
                           }
                           if (configSpec != null) {
                              setUpDone &= this.iDVS.reconfigure(this.dvsMor,
                                       configSpec);
                              if (setUpDone) {
                                 freePorts = this.iDVS.fetchPortKeys(dvsMor,
                                          portCriteria);
                              }
                           }
                           if (setUpDone && freePorts != null
                                    && freePorts.size() >= numCards) {

                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setPortKey(freePorts.get(i));
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
                                 if (portConnectionList == null) {
                                    portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                             numCards);
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
                                          }
                                       }
                                       if (setUpDone) {
                                          setUpDone = this.ivm.setVMState(
                                                   this.vmMor, POWERED_OFF, false);
                                          if (setUpDone) {
                                             log.info("Succesfully powered "
                                                      + "off the VM "
                                                      + this.vmName);
                                          } else {
                                             log.error("Can not power off the "
                                                      + "VM " + this.vmName);
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
                              log.error("Cannot reconfigure the DVSwitch with"
                                       + " the required number of ports");
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
   @Test(description = "Convert a VM that connects to a standalone DVPort "
               + "into template. The template will not contain any"
               + " DVPort information to connect to. Clone two VM's"
               + " from the template and power on the two VM's. "
               + "The VM's will not have any network connectivity.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      VirtualEthernetCardDistributedVirtualPortBackingInfo dvPortBacking = null;
      VirtualMachineCloneSpec cloneSpec = null;
      VirtualMachineRelocateSpec relocateSpec = null;
      List<DatastoreInformation> hostDatastores = null;
      String ipAddress = null;
      testDone = this.ivm.markAsTemplate(this.vmMor);
      if (testDone) {
            if (!this.ivm.isTemplate(this.vmMor)) {
               testDone = false;
               log.error("Can not convert the VM into template");
            } else {
               log.info("Succesfully converted the VM into template");
            }
            if (testDone) {
               cloneSpec = new VirtualMachineCloneSpec();
               cloneSpec.setTemplate(false);
               cloneSpec.setPowerOn(false);
               cloneSpec.setCustomization(null);
               relocateSpec = new VirtualMachineRelocateSpec();
               relocateSpec.setHost(this.hostMor);
               relocateSpec.setPool(this.vmPoolMor);
               hostDatastores = this.ihs.getDatastoresInfo(this.hostMor);
               if(hostDatastores != null)
               {
                   Datastore ds = new Datastore(this.connectAnchor);
                   String hostName = this.ihs.getHostName(this.hostMor);
                   for (DatastoreInformation datastoreInfo : hostDatastores)
                   {
                       if( datastoreInfo.isAccessible() && ds.isDsWritable(datastoreInfo, hostName, ihs) )
                       {
                           relocateSpec.setDatastore(datastoreInfo.getDatastoreMor());
                           break;
                       }
                   }
               }
               if(relocateSpec.getDatastore() != null)
               {
	               cloneSpec.setLocation(relocateSpec);
	               this.cloneVMMor = this.ivm.cloneVM(this.vmMor,
	                        this.ivm.getVMFolder(), this.vmName + "-Clone1",
	                        cloneSpec);
	               if (this.cloneVMMor != null) {
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
	                                       && dvPortBacking.getPort().getPortKey() != null) {
	                                 testDone = false;
	                                 break;
	                              }
	                           }
	                        }
	                     }
	                  }
               }
               else {
                     testDone = false;
                     log.error("Can not find a accessible and writeble datastore for VM clone: " + this.vmName);
               }
               if (testDone) {
                     testDone = this.ivm.setVMState(this.cloneVMMor, POWERED_ON, checkGuest);
                     if (testDone) {
                        log.info("Successfully powered on the VM "
                                 + this.cloneVMName);
                        this.hostConnectAnchor = new ConnectAnchor(
                                 this.ihs.getHostName(hostMor),
                                 data.getInt(TestConstants.TESTINPUT_PORT));
                        assertTrue(InternalDVSHelper.verifyPortPersistenceLocation(
                                 hostConnectAnchor,
                                 this.ivm.getName(this.cloneVMMor),
                                 this.dvSwitchUUID),
                                 "Verification for PortPersistenceLocation failed");
                        DVSUtil.reconfigureWithTrafficShapingPolicy(
                                 connectAnchor, this.dvsMor);
                        this.hostConnectAnchor = new ConnectAnchor(
                                 this.ihs.getHostName(hostMor),
                                 data.getInt(TestConstants.TESTINPUT_PORT));
                        assertTrue(InternalDVSHelper.verifyPortPersistenceLocation(
                                 hostConnectAnchor,
                                 this.ivm.getName(this.cloneVMMor),
                                 this.dvSwitchUUID),
                                 "Verification for PortPersistenceLocation failed");
                        if (checkGuest) {
                           ipAddress = this.ivm.getIPAddress(this.cloneVMMor);
                           if (ipAddress != null) {
                              log.error("The VM has a valid IP");
                              testDone = false;
                           } else {
                              log.info("The VM doesnot have network "
                                       + "connectivity");
                           }
                        }
                     } else {
                        log.error("Can not power on the VM "
                                 + this.cloneVMName);
                     }
                  }
               } else {
                  testDone = false;
                  log.error("Can not clone a VM from the template"
                           + this.vmName);
               }
            }
         } else {
            log.error("Can not mark the VM as template " + this.vmName);
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
      VirtualMachineConfigInfo vmConfigInfo = null;
     
         if (this.vmMor != null) {
            if (this.ivm.isTemplate(this.vmMor)) {
               this.ivm.markAsVirtualMachine(this.vmMor, this.vmPoolMor,
                        this.hostMor);
               vmConfigInfo = this.ivm.getVMConfigInfo(this.vmMor);
               if (vmConfigInfo != null && !vmConfigInfo.isTemplate()) {
                  log.info("Successfully marked the VM as Virtual Machine "
                           + this.vmName);
               } else {
                  cleanUpDone &= false;
                  log.error("Can not convert the VM back to virtual machine "
                           + this.vmName);
               }
            }
            if (cleanUpDone) {
               cleanUpDone &= this.ivm.setVMState(this.vmMor, POWERED_OFF, false);
               if (cleanUpDone) {
                  log.info("Successfully powered off the vm "
                           + this.vmName);
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
                           log.info("Successfully restored the original "
                                    + "power state for the vm " + this.vmName);
                        } else {
                           log.error("Can not restore the original power state"
                                    + " for the VM " + this.vmName);
                        }
                     }
                  }
               } else {
                  log.error("Can not power off the VM " + this.vmName);
               }
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
