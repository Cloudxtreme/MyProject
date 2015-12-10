/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vc.DistributedVirtualSwitchPortConnecteeConnecteeType.VM_VNIC;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Suspend and resume a VM that is connected to a late binding portgroup of the
 * DVSwitch.
 */
public class Pos004 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private ManagedObjectReference pgMor = null;
   private String portgroupKey = null;
   private boolean isVMCreated = false;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Suspend and resume a VM that is connected to a "
               + "late binding portgroup of the DVSwitch.");
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
      List<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      int numCards = 0;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DVPortgroupConfigSpec configSpec = null;
      List<ManagedObjectReference> pgMorList = null;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
            allVms = this.ihs.getVMs(this.hostMor, null);
            if (allVms == null || allVms.size() <= 0) {
               this.originalVMConfigSpec = DVSUtil.buildDefaultSpec(
                        connectAnchor, hostMor,
                        TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
                        this.getTestId() + "-VM");
               if (this.originalVMConfigSpec != null) {
                  this.vmMor = new Folder(super.getConnectAnchor()).createVM(
                           this.ivm.getVMFolder(), this.originalVMConfigSpec,
                           this.ihs.getResourcePool(this.hostMor).get(0),
                           this.hostMor);
                  if (this.vmMor != null) {
                     this.isVMCreated = true;
                  }
               }
            } else if (allVms != null && allVms.size() > 0) {
               this.vmMor = allVms.get(0);
            } else {
               setUpDone = false;
               log.error("Can not find any vm's on the host");
            }
            if (this.vmMor != null) {
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
                        configSpec = new DVPortgroupConfigSpec();
                        configSpec.setName(DVSTestConstants.DVS_MISC_NAME_PREFIX
                                 + getTestId() + "-pg1");
                        configSpec.setNumPorts(numCards);
                        configSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
                        pgMorList = this.iDVS.addPortGroups(dvsMor,
                                 new DVPortgroupConfigSpec[] { configSpec });
                        if (pgMorList != null && pgMorList.size() == 1) {
                           this.pgMor = pgMorList.get(0);
                           if (this.pgMor != null) {
                              this.portgroupKey = this.iDVPortgroup.getKey(pgMor);
                              portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                       numCards);
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setPortgroupKey(portgroupKey);
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
                                 portConnectionList.add(portConnection);
                              }
                              vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                       this.vmMor,
                                       connectAnchor,
                                       portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                              if (vmConfigSpec != null
                                       && vmConfigSpec.length >= 2
                                       && vmConfigSpec[0] != null
                                       && vmConfigSpec[1] != null) {
                                 this.originalVMConfigSpec = vmConfigSpec[1];
                                 setUpDone = this.ivm.reconfigVM(this.vmMor,
                                          vmConfigSpec[0]);
                                 if (setUpDone) {
                                    log.info("Successfully reconfigured "
                                             + "the VM to use the DV Ports");
                                 } else {
                                    log.error("Can not reconfigure the "
                                             + "VM to use the DV Ports");
                                 }
                              }
                           } else {
                              setUpDone = false;
                              log.error("Can not add the port group");
                           }
                        } else {
                           setUpDone = false;
                           log.error("Can not add the port group");
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
    * Method that performs the test.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Suspend and resume a VM that is connected to a "
               + "late binding portgroup of the DVSwitch.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      List<String> usedPorts = null;
      List<DistributedVirtualPort> oldDVPorts = null;
      List<DistributedVirtualPort> newDVPorts = null;
      boolean testDone = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      Comparator<DistributedVirtualPort> comparator = this.iDVS.getPortComparator();
      boolean checkGuest = DVSTestConstants.CHECK_GUEST;
     
         testDone = this.ivm.powerOnVM(this.vmMor, null, checkGuest);
         /*
          * Sleep for a little while to populate the port statistics
          */
         log.info("Sleeping for a sec to populate some port "
                  + "statistics");
         Thread.sleep(1000);
         if (testDone) {
            portCriteria = this.iDVS.getPortCriteria(true, null, null,
                     new String[] { this.portgroupKey }, null, true);
            usedPorts = this.iDVS.fetchPortKeys(dvsMor, portCriteria);
            if (usedPorts != null
                     && usedPorts.size() > 0
                     && this.iDVS.refreshPortState(dvsMor,
                              usedPorts.toArray(new String[usedPorts.size()]))) {
               oldDVPorts = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
               if (oldDVPorts != null) {
                  testDone = this.ivm.suspendVM(vmMor);
                  if (testDone) {
                     // Sleep for a little while to populate the port
                     // statistics.
                     log.info("Sleeping for a sec to populate some port "
                              + "statistics");
                     Thread.sleep(1000);
                     testDone = this.ivm.powerOnVM(this.vmMor, null, checkGuest);
                     if (testDone
                              && this.iDVS.refreshPortState(
                                       dvsMor,
                                       usedPorts.toArray(new String[usedPorts.size()]))) {
                        newDVPorts = this.iDVS.fetchPorts(this.dvsMor,
                                 portCriteria);
                        if (newDVPorts != null
                                 && newDVPorts.size() == oldDVPorts.size()) {
                           Collections.sort(oldDVPorts, comparator);
                           Collections.sort(newDVPorts, comparator);
                           for (int i = 0; i < oldDVPorts.size(); i++) {
                              if (oldDVPorts.get(i) != null
                                       && newDVPorts.get(i) != null
                                       && this.iDVS.comparePortConnecteeNicType(
                                                newDVPorts.get(i), VM_VNIC.value())
                                       && newDVPorts.get(i).getState() != null) {
                                 if (!this.iDVS.comparePortState(
                                          oldDVPorts.get(i).getState(),
                                          newDVPorts.get(i).getState())) {
                                    log.error("The port state is not retained");
                                    testDone = false;
                                    break;
                                 }
                              }
                           }
                        } else {
                           testDone = false;
                           log.error("Can not retrieve all the ports used by the"
                                    + " VM");
                        }
                     } else {
                        log.error("Can not suspend the VM");
                     }
                  } else {
                     log.error("Can not suspend the VM");
                  }
               } else {
                  testDone = false;
               }
            } else {
               testDone = false;
               log.error("Can not retreive the port keys of the portgroup");
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
     
         if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            log.info("Successfully powered off the vm " + this.vmName);
            if (this.isVMCreated) {
               cleanUpDone &= this.ivm.destroy(this.vmMor);
            } else {
               log.info("Successfully powered off the vm " + this.vmName);
               if (this.originalVMConfigSpec != null) {
                  cleanUpDone &= this.ivm.reconfigVM(this.vmMor,
                           this.originalVMConfigSpec);
                  if (cleanUpDone) {
                     log.info("Reconfigured the VM to the original "
                              + "configuration");
                  } else {
                     log.error("Can not restore the VM to the original "
                              + "configuration");
                  }
               }
               if (cleanUpDone) {
                  cleanUpDone &= this.ivm.setVMState(this.vmMor,
                           this.oldPowerState, false);
                  if (cleanUpDone) {
                     log.info("Successfully restored the original power state"
                              + " for the vm " + this.vmName);
                  } else {
                     log.error("Can not restore the original power state for"
                              + " the VM " + this.vmName);
                  }
               }

            }
         } else {
            log.error("Can not power off the VM " + this.vmName);
         }
         if (cleanUpDone) {
            cleanUpDone &= super.testCleanUp();
         }
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}