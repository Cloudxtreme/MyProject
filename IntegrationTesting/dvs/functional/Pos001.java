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
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnecteeConnecteeType;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Suspend and resume VM that is connected to an standalone DVPort of the
 * DVSwitch.
 */
public class Pos001 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private String[] usedPorts = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Suspend and resume a VM that is connected to an "
               + "standalone DVPort of the DVSwitch.");
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
      DVSConfigSpec configSpec = null;
      DVSConfigInfo configInfo = null;
      List<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      int numCards = 0;
      List<String> freePorts = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      int portsAdded = 0;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            configInfo = this.iDVS.getConfig(this.dvsMor);
            allVms = this.ihs.getVMs(this.hostMor, null);
            if (allVms != null && allVms.size() > 0) {
               this.vmMor = allVms.get(0);
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
                           portCriteria = new DistributedVirtualSwitchPortCriteria();
                           portCriteria.setConnected(false);
                           portCriteria.setInside(false);
                           freePorts = this.iDVS.fetchPortKeys(this.dvsMor,
                                    portCriteria);
                           if (freePorts == null || freePorts.size() < numCards) {
                              if (freePorts == null) {
                                 portsAdded = numCards;
                              } else {
                                 portsAdded = numCards - freePorts.size();
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
                              }
                           }
                           if (setUpDone) {
                              if (freePorts != null
                                       && freePorts.size() >= numCards) {
                                 this.usedPorts = freePorts.subList(0, numCards).toArray(
                                          new String[freePorts.subList(0,
                                                   numCards).size()]);
                                 portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                          numCards);
                                 for (int i = 0; i < numCards; i++) {
                                    portConnection = new DistributedVirtualSwitchPortConnection();
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
                                    this.originalVMConfigSpec = vmConfigSpec[1];
                                    setUpDone = this.ivm.reconfigVM(this.vmMor,
                                             vmConfigSpec[0]);
                                    if (setUpDone) {
                                       log.info("Successfully reconfigured"
                                                + " the VM to use the DV Ports");
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
            } else {
               setUpDone = false;
               log.error("Can not find any vm's on the host");
            }
         }
     
      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Method that tests if the state of the standalone port connected to a VM is
    * retained when the VM is suspended and resumed.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Suspend and resume a VM that is connected to an "
               + "standalone DVPort of the DVSwitch.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      String ipAddress = null;
      List<DistributedVirtualPort> oldDVPorts = null;
      List<DistributedVirtualPort> newDVPorts = null;
      boolean testDone = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      Comparator<DistributedVirtualPort> comparator = this.iDVS.getPortComparator();
      boolean checkGuest = DVSTestConstants.CHECK_GUEST;
      final int SLEEP_MULTIPLIER = 120;
 
         testDone = this.ivm.setVMState(this.vmMor, POWERED_ON, checkGuest);
         if (testDone) {
            if (checkGuest) {
               ipAddress = this.ivm.getIPAddress(this.vmMor);
            }

            if (ipAddress != null || checkGuest == false) {
               /*
                * Sleep for a little while to populate the port statistics
                */
               log.info("Sleeping for 120 secs to populate some port "
                        + "statistics");
               Thread.sleep(1000 * SLEEP_MULTIPLIER);
               log.info("Refresh the port state ");
               if (this.iDVS.refreshPortState(dvsMor, this.usedPorts)) {
                  portCriteria = this.iDVS.getPortCriteria(true, null, null,
                           null, this.usedPorts, false);
                  log.info("Retrieve the port state");
                  oldDVPorts = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
                  if (oldDVPorts != null) {
                     testDone = this.ivm.suspendVM(vmMor);
                     if (testDone) {
                        /*
                         * Sleep for a little while to populate the port 
                         * statistics
                         */
                        log.info("Sleeping for a sec to populate some port "
                                 + "statistics");
                        Thread.sleep(1000);

                        testDone = this.ivm.setVMState(this.vmMor, POWERED_ON, checkGuest);
                        if (testDone) {
                           if (checkGuest) {
                              ipAddress = this.ivm.getIPAddress(this.vmMor);
                           }
                           if (ipAddress != null || checkGuest == false) {
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
                                             log.error("The port state is not"
                                                      + " retained");
                                             testDone = false;
                                             break;
                                          }
                                       }
                                    }
                                 } else {
                                    testDone = false;
                                    log.error("Can not retrieve the ports");
                                 }
                              } else {
                                 testDone = false;
                                 log.error("Can not refresh the port state of"
                                          + " the used ports");
                              }
                           } else {
                              log.error("Can not obtain a valid ip Address for"
                                       + " the VM, there is no network "
                                       + "connectivity");
                              testDone = false;
                           }
                        } else {
                           log.error("Can not power on the VM "
                                    + this.vmName);
                        }
                     } else {
                        log.error("Can not suspend the VM "
                                 + this.vmName);
                     }
                  } else {
                     testDone = false;
                  }
               } else {
                  testDone = false;
                  log.error("Can not refresh the port state of the port keys "
                           + "passed");
               }
            } else {
               log.error("Can not obtain a valid ip Address for the VM, "
                        + "there is no network connectivity");
               testDone = false;
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
                        log.info("Successfully restored the original "
                                 + "power state for the vm " + this.vmName);
                     } else {
                        log.error("Can not restore the original power state for"
                                 + " the VM " + this.vmName);
                     }
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
