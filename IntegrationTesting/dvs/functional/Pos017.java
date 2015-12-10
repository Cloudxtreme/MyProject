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

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Create a VM (VM1) connect it to early binding DVPort and then unregister the
 * VM from the VC inventory. Create another VM (VM2) that connects to the same
 * DVPort, register VM1 back to the VC inventory. Power on the VM's. Power cycle
 * the powered on VM's.
 */
public class Pos017 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachinePowerState otherVMOldPowerState = null;
   private String vmName = null;
   private String hostIpAdress = null;
   private String ipAddress = null;
   private List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
   private VirtualMachineConfigSpec vmOrgConfigSpec = null;
   private VirtualMachineConfigSpec otherVMOrgConfigSpec = null;
   private String vmPath = null;
   private ManagedObjectReference vmParent = null;
   private ManagedObjectReference vmResourcePool = null;
   private ManagedObjectReference otherVMMor = null;
   private String otherVMName = null;
   private static final boolean checkGuest = DVSTestConstants.CHECK_GUEST;
   private Datacenter idc = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Create a VM (VM1) connect it to early binding "
               + "DVPort and then unregister the VM from the VC"
               + " inventory. Create another VM (VM2) that connects"
               + " to the same DVPort, register VM1 back to the VC"
               + " inventory. Power on the VM's. Power cycle the "
               + "powered on VM's.");
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
      Vector<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      int numCards = 0;
      String pgKey = null;
      List<String> freePorts = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            allVms = this.ihs.getAllVirtualMachine(this.hostMor);
            if (allVms != null && allVms.size() > 0) {
               this.vmMor = allVms.get(0);
               if (this.vmMor != null) {
                  this.oldPowerState = this.ivm.getVMState(this.vmMor);
                  this.idc = new Datacenter(connectAnchor);
                  this.vmName = this.ivm.getVMName(this.vmMor);
                  this.vmPath = this.ivm.getVMConfigInfo(this.vmMor).getFiles().getVmPathName();
                  this.vmResourcePool = this.ivm.getResourcePool(this.vmMor);
                  this.vmParent = this.ivm.getParentNode(this.vmMor);
                  setUpDone = this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                  if (setUpDone) {
                     log.info("Succesfully powered off the vm "
                              + this.vmName);
                     vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                              this.vmMor, connectAnchor);
                     if (vdConfigSpec != null) {
                        numCards = vdConfigSpec.size();
                        if (numCards > 0) {
                           pgKey = this.iDVS.addPortGroup(this.dvsMor,
                                    DVPORTGROUP_TYPE_EARLY_BINDING, numCards,
                                    this.getTestId() + "-pg1");
                           portCriteria = this.iDVS.getPortCriteria(false,
                                    null, null, new String[] { pgKey }, null,
                                    true);
                           freePorts = this.iDVS.fetchPortKeys(this.dvsMor,
                                    portCriteria);
                           if (freePorts != null
                                    && freePorts.size() == numCards) {
                              this.portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                       numCards);
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setPortKey(freePorts.get(i));
                                 portConnection.setPortgroupKey(pgKey);
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
                                 this.portConnectionList.add(portConnection);
                              }
                              vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                       this.vmMor,
                                       connectAnchor,
                                       this.portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[this.portConnectionList.size()]));
                              if (vmConfigSpec != null
                                       && vmConfigSpec.length == 2
                                       && vmConfigSpec[0] != null) {
                                 setUpDone = this.ivm.reconfigVM(this.vmMor,
                                          vmConfigSpec[0]);
                                 if (setUpDone) {
                                    log.info("Successfully "
                                             + "reconfigured the VM"
                                             + " to use the DV " + "Ports");
                                    this.vmOrgConfigSpec = vmConfigSpec[1];
                                    setUpDone = this.ivm.powerOnVM(this.vmMor,
                                             null, checkGuest);
                                    if (setUpDone) {
                                       log.info("successfully powered on"
                                                + " the VM " + this.vmName);
                                    } else {
                                       log.error("can not power on the VM"
                                                + this.vmName);
                                       assertTrue(setUpDone, "Setup failed");
                                       return setUpDone;
                                    }
                                 } else {
                                    log.error("Can not reconfigure the VM"
                                             + " to use the DV Ports");
                                 }
                              }
                           } else {
                              setUpDone = false;
                              log.error("Can not find enough free "
                                       + "standalone ports to "
                                       + "reconfigure the VM");
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
                  } else {
                     log.error("Can not power off the VM " + this.vmName);
                  }
               } else {
                  setUpDone = false;
                  log.error("The vm mor object is null");
               }
            } else {
               setUpDone = false;
               log.error("Can not find any vm's on the host");
            }

            if (setUpDone && checkGuest) {
               this.ipAddress = this.ivm.getIPAddress(this.vmMor);
               if (this.ipAddress != null) {
                  this.hostIpAdress = this.ihs.getIPAddress(this.hostMor);
                  if (this.hostIpAdress != null) {
                     setUpDone = DVSUtil.checkNetworkConnectivity(
                              this.hostIpAdress, this.ipAddress, true);
                     if (setUpDone) {
                        log.info("The vm has the network connectivity");
                     } else {
                        log.error("The VM does not have network connectivity");
                     }
                  } else {
                     setUpDone = false;
                     log.error("Can not get the host ip address ");
                  }
               } else {
                  setUpDone = false;
                  log.error("Can not get the host ipaddress "
                           + this.ihs.getHostName(this.hostMor));
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
   @Test(description = "Create a VM (VM1) connect it to early binding "
               + "DVPort and then unregister the VM from the VC"
               + " inventory. Create another VM (VM2) that connects"
               + " to the same DVPort, register VM1 back to the VC"
               + " inventory. Power on the VM's. Power cycle the "
               + "powered on VM's.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      Vector<ManagedObjectReference> allVMs = null;
     
         testDone = this.ivm.setVMState(this.vmMor, POWERED_OFF, false);
         if (testDone) {
            log.info("Successfully powered off the VM " + this.vmName);
            testDone = this.ivm.unregisterVM(this.vmMor);
            if (testDone) {
               log.info("Succesfully unregisterd the VM " + this.vmName);
               if (portConnectionList != null && portConnectionList.size() > 0) {
                  allVMs = this.ihs.getVMs(this.hostMor, null);
                  if (allVMs != null && allVMs.size() > 0) {
                     for (ManagedObjectReference temp : allVMs) {
                        this.otherVMMor = temp;
                        if (this.otherVMMor != null) {
                           break;
                        }
                     }
                  }
                  if (this.otherVMMor != null) {
                     this.otherVMName = this.ivm.getVMName(this.otherVMMor);
                     this.otherVMOldPowerState = this.ivm.getVMState(this.otherVMMor);
                     testDone = this.ivm.setVMState(this.otherVMMor, POWERED_OFF, false);
                     if (testDone) {
                        vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                 this.otherVMMor,
                                 connectAnchor,
                                 portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                        if (vmConfigSpec != null && vmConfigSpec.length == 2
                                 && vmConfigSpec[0] != null
                                 && vmConfigSpec[1] != null) {
                           this.otherVMOrgConfigSpec = vmConfigSpec[1];
                           testDone = this.ivm.reconfigVM(this.otherVMMor,
                                    vmConfigSpec[0]);
                           if (testDone) {
                              this.otherVMOrgConfigSpec = vmConfigSpec[1];
                              log.info("Successfully reconfigured the VM to"
                                       + " use the previously used ports in "
                                       + "the early binding port group");
                              testDone = this.ivm.setVMState(this.otherVMMor, POWERED_ON, checkGuest);
                              if (testDone) {
                                 log.info("Successfully powered on the VM "
                                          + this.vmName);
                                 this.ipAddress = this.ivm.getIPAddress(this.otherVMMor);
                                 if (this.ipAddress != null) {
                                    log.info("Got the Ip address for the VM "
                                             + this.vmName);
                                    this.vmMor = new com.vmware.vcqa.vim.Folder(
                                             super.getConnectAnchor()).registerVm(
                                             this.vmParent, this.vmPath,
                                             this.vmName, false,
                                             this.vmResourcePool, this.hostMor);
                                    if (this.vmMor != null) {
                                       testDone = this.ivm.powerOnVM(
                                                this.vmMor, null, checkGuest);
                                       if (testDone) {
                                          if (checkGuest) {
                                             this.ipAddress = this.ivm.getIPAddress(this.vmMor);
                                             if (this.ipAddress == null) {
                                                log.info("Successfully powered "
                                                         + "on the VM "
                                                         + this.vmName);
                                             } else {
                                                testDone = false;
                                                log.error("The vm got a valid ip"
                                                         + " address"
                                                         + this.vmName);
                                             }
                                          }
                                       } else {
                                          testDone = false;
                                          log.error("Can not power on the VM "
                                                   + this.vmName);
                                       }
                                    } else {
                                       testDone = false;
                                       log.error("Can not register back the "
                                                + "unregistered VM "
                                                + this.vmName);
                                    }
                                 } else {
                                    testDone = false;
                                    log.error("Can not retrieve the ip address "
                                             + "for the VM " + this.vmName);
                                 }
                              } else {
                                 log.error("Can not power on the VM "
                                          + this.vmName);
                              }
                           } else {
                              testDone = false;
                              log.error("Can not power on the VM "
                                       + this.vmName);
                           }
                        } else {
                           log.error("Cannot set the VM state to powered off "
                                    + this.otherVMName);
                        }
                     } else {
                        testDone = false;
                        log.error("Can not reconfigure the DVS "
                                 + this.iDVS.getName(this.dvsMor));
                     }
                  } else {
                     testDone = false;
                     log.error("Can not find another valid vm on the host "
                              + this.ihs.getHostName(this.hostMor));
                  }
               } else {
                  testDone = false;
                  log.error("The port connection list is null");
               }
            } else {
               log.error("Can not unregister the VM " + this.vmName);
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
      boolean cleanUp1Done = true;
      boolean cleanUp2Done = true;
      boolean cleanUpDone = true;
     
         if (this.vmMor != null && this.vmName != null
                  && this.ivm.getVM(this.vmName) == null) {
            this.vmMor = null;
            if (this.vmPath != null && this.vmParent != null
                     && this.vmResourcePool != null) {
               this.vmMor = new com.vmware.vcqa.vim.Folder(
                        super.getConnectAnchor()).registerVm(this.vmParent,
                        this.vmPath, this.vmName, false, this.vmResourcePool,
                        this.hostMor);
               if (this.vmMor != null) {
                  log.info("Succesfully registered the VM "
                           + this.vmName);
               } else {
                  cleanUp1Done &= false;
                  log.error("Can not register the VM into the VC inventory "
                           + this.vmName);
               }
            }
         }

         if (this.vmMor != null && this.vmOrgConfigSpec != null) {
            cleanUp1Done &= this.ivm.setVMState(this.vmMor, POWERED_OFF, false);
            if (cleanUp1Done) {
               log.info("Successfully powered off the VM " + this.vmName);
               cleanUp1Done &= this.ivm.reconfigVM(this.vmMor,
                        this.vmOrgConfigSpec);
               if (cleanUp1Done) {
                  log.info("Succesfully reconfigured the VM "
                           + this.vmName);
                  if (this.oldPowerState != null) {
                     cleanUp1Done &= this.ivm.setVMState(this.vmMor,
                              this.oldPowerState, false);
                     if (!this.oldPowerState.equals(this.ivm.getVMState(this.vmMor))) {
                        log.error("Can not set the VM " + this.vmName
                                 + "to " + this.oldPowerState);
                     } else {
                        log.info("Successfully set the VM "
                                 + this.vmName + "to " + this.oldPowerState);
                     }
                  }
               } else {
                  log.error("Can not reconfigure the VM " + this.vmName);
               }
            } else {
               log.error("Can not power off the VM " + this.vmName);
            }
         }
         if (this.otherVMMor != null) {
            if (this.otherVMOrgConfigSpec != null) {
               if (this.ivm.setVMState(this.otherVMMor, POWERED_OFF, false)) {
                  log.info("Successfully powered off the VM "
                           + this.otherVMName);
                  if (this.ivm.reconfigVM(this.otherVMMor,
                           this.otherVMOrgConfigSpec)) {
                     log.info("Successfully reconfigured the VM to it's original"
                              + " state " + this.otherVMName);
                     if (this.otherVMOldPowerState != null) {
                        cleanUp2Done &= this.ivm.setVMState(this.otherVMMor,
                                 this.otherVMOldPowerState, false);
                        if (cleanUp2Done) {
                           log.info("Succesfully restored the power state of"
                                    + " the VM " + this.otherVMName);
                        } else {
                           log.error("Can not power off the VM "
                                    + this.otherVMName);
                        }
                     }
                  } else {
                     cleanUp2Done &= false;
                     log.error("Can not reconfigure the VM to it's original "
                              + "state " + this.otherVMName);
                  }
               } else {
                  log.error("Can not set the VM state to powered off "
                           + this.otherVMName);
                  cleanUp2Done &= false;
               }
            }
         }
         cleanUp1Done &= cleanUp1Done & cleanUp2Done;
         cleanUpDone &= super.testCleanUp();
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}