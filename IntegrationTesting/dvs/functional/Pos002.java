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
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnecteeConnecteeType;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Suspend and resume a VM that is connected to a early binding DVPort of the
 * DVSwitch.
 */
public class Pos002 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private String[] usedPorts = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private ManagedObjectReference pgMor = null;
   private String portgroupKey = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Suspend and resume a VM that is connected to a "
               + "early binding DVPort of the DVSwitch.");
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
      Map<String, List<String>> excludedPorts = new HashMap<String, List<String>>();
      String portKey = null;
      List<String> freePorts = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DVPortgroupConfigSpec configSpec = null;
      List<ManagedObjectReference> pgMorList = null;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
            allVms = this.ihs.getVMs(this.hostMor, null);
            if (allVms != null && allVms.size() > 0) {
               this.vmMor = allVms.get(0);
               if (this.vmMor != null) {
                  this.oldPowerState = this.ivm.getVMState(this.vmMor);
                  this.vmName = this.ivm.getVMName(this.vmMor);
                  setUpDone = this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                  if (setUpDone) {
                     log.info("Succesfully powered off the vm "
                              + this.vmName);
                     vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                              this.vmMor, connectAnchor);
                     if (vdConfigSpec != null) {
                        numCards = vdConfigSpec.size();
                        if (numCards > 0) {
                           configSpec = new DVPortgroupConfigSpec();
                           configSpec.setName(getTestId() + "-pg1");
                           configSpec.setNumPorts(numCards);
                           configSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                           pgMorList = this.iDVS.addPortGroups(dvsMor,
                                    new DVPortgroupConfigSpec[] { configSpec });
                           if (pgMorList != null && pgMorList.size() == 1) {
                              this.pgMor = pgMorList.get(0);
                              if (this.pgMor != null) {
                                 this.portgroupKey = this.iDVPortgroup.getKey(pgMor);
                                 for (int i = 0; i < numCards; i++) {
                                    portKey = this.iDVS.getFreePortInPortgroup(
                                             dvsMor, portgroupKey,
                                             excludedPorts);
                                    if (portKey != null) {
                                       if (freePorts == null) {
                                          freePorts = new ArrayList<String>();
                                       }
                                       freePorts.add(portKey);
                                    }
                                 }
                                 if (freePorts != null
                                          && freePorts.size() == numCards) {
                                    this.usedPorts = freePorts.toArray(new String[freePorts.size()]);
                                    portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                             numCards);
                                    for (int i = 0; i < numCards; i++) {
                                       portConnection = new DistributedVirtualSwitchPortConnection();
                                       portConnection.setPortgroupKey(portgroupKey);
                                       portConnection.setPortKey(freePorts.get(i));
                                       portConnection.setSwitchUuid(this.dvSwitchUUID);
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
                                       setUpDone = this.ivm.reconfigVM(
                                                this.vmMor, vmConfigSpec[0]);
                                       if (setUpDone) {
                                          log.info("Successfully reconfigured"
                                                   + " the VM to use the DV "
                                                   + "Ports");
                                          this.originalVMConfigSpec = vmConfigSpec[1];
                                       } else {
                                          log.error("Can not reconfigure the "
                                                   + "VM to use the DV Ports");
                                       }
                                    } else {
                                       setUpDone = false;
                                       log.error("Can not get the VM config "
                                                + "spec to update to");
                                    }
                                 } else {
                                    setUpDone = false;
                                    log.error("Can not find enough free "
                                             + "standalone  ports to "
                                             + "reconfigure the VM");
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
                  } else {
                     log.error("Can not set the VM state to powered off "
                              + this.vmName);
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
    * Methos that performs the test.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Suspend and resume a VM that is connected to a "
               + "early binding DVPort of the DVSwitch.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      List<DistributedVirtualPort> oldDVPorts = null;
      List<DistributedVirtualPort> newDVPorts = null;
      boolean testDone = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      Comparator<DistributedVirtualPort> comparator = this.iDVS.getPortComparator();
      boolean checkGuest = DVSTestConstants.CHECK_GUEST;
     
         testDone = this.ivm.setVMState(this.vmMor, POWERED_ON, checkGuest);
         /*
          * Sleep for a little while to populate the port statistics
          */
         log.info("Sleeping for a sec to populate some port "
                  + "statistics");
         Thread.sleep(1000);
         if (testDone) {
            portCriteria = this.iDVS.getPortCriteria(true, null, null,
                     new String[] { this.portgroupKey }, this.usedPorts, true);
            if (this.iDVS.refreshPortState(this.dvsMor, this.usedPorts)) {
               oldDVPorts = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
               if (oldDVPorts != null) {
                  testDone = this.ivm.suspendVM(vmMor);
                  if (testDone) {
                     // Sleep for a little while to populate the port
                     // statistics.
                     log.info("Sleeping for a sec to populate some "
                              + "port statistics");
                     Thread.sleep(1000);
                     testDone = this.ivm.powerOnVM(this.vmMor, null, checkGuest);
                     if (testDone) {
                        if (this.iDVS.refreshPortState(this.dvsMor,
                                 this.usedPorts)) {
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
                                                   newDVPorts.get(i), DistributedVirtualSwitchPortConnecteeConnecteeType.VM_VNIC.value())
                                          && newDVPorts.get(i).getState() != null) {
                                    if (!this.iDVS.comparePortState(
                                             oldDVPorts.get(i).getState(),
                                             newDVPorts.get(i).getState())) {
                                       log.error("The port state is not "
                                                + "retained");
                                       testDone = false;
                                       break;
                                    }
                                 }
                              }
                           } else {
                              testDone = false;
                              log.error("Can not retrieve all the ports used by "
                                       + "the VM");
                           }
                        } else {
                           testDone = false;
                           log.error("Can not refresh the port state");
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
               log.error("Can not refresh the port state");
            }
         } else {
            log.error("Can not power on the VM " + this.vmName);
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
            cleanUpDone &= this.ivm.setVMState(vmMor, POWERED_OFF, false);
            if (cleanUpDone) {
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
            } else {
               log.error("Can not power off the VM " + this.vmName);
            }
         }
         if (cleanUpDone) {
            cleanUpDone &= super.testCleanUp();
         }
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}