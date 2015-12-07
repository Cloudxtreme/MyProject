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

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Disconnect and reconnect the host on which resides a powered off VM that is
 * connected to a late binding DVPort of the DVSwitch.
 */
public class Pos007 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private Connection connection = null;
   private String hostName = null;
   private String pgKey = null;
   private static final boolean checkGuest = DVSTestConstants.CHECK_GUEST;
   private HostConnectSpec hostConnectSpec = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Disconnect and reconnect the host on which resides"
               + " a powered on VM that is connected to a late "
               + "binding DVPort of the DVSwitch.");
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
      DVPortgroupConfigSpec pgConfigSpec = null;
      List<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      int numCards = 0;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      ManagedObjectReference pgMor = null;
      DVPortgroupPolicy pgPolicy = null;


         setUpDone = super.testSetUp();
         if (setUpDone) {
            this.hostName = this.ihs.getHostName(this.hostMor);
            hostConnectSpec = this.ihs.getHostConnectSpec(hostMor);
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
                           pgConfigSpec = new DVPortgroupConfigSpec();
                           pgConfigSpec.setConfigVersion("");
                           pgConfigSpec.setNumPorts(numCards);
                           pgConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
                           pgConfigSpec.setName(this.getTestId() + "-pg1");
                           pgPolicy = new DVPortgroupPolicy();
                           pgPolicy.setPortConfigResetAtDisconnect(false);
                           pgConfigSpec.setPolicy(pgPolicy);
                           pgMor = this.iDVS.addPortGroups(
                                    this.dvsMor,
                                    new DVPortgroupConfigSpec[] { pgConfigSpec }).get(
                                    0);
                           if (pgMor != null) {
                              this.pgKey = this.iDVPortgroup.getKey(pgMor);
                              portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                       numCards);
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setPortgroupKey(this.pgKey);
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
                                    log.info("Successfully "
                                             + "reconfigured"
                                             + " the VM to use the "
                                             + "late binding dv " + "portgroup");
                                    setUpDone = this.ivm.setVMState(this.vmMor, POWERED_ON, checkGuest);
                                    if (setUpDone) {
                                       log.info("Succesfully powered off the "
                                                + "VM " + this.vmName);
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
                              log.error("Cannot add the portgroup with the "
                                       + "required number of ports");
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
         }

      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Method that performs the test.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Disconnect and reconnect the host on which resides"
               + " a powered on VM that is connected to a late "
               + "binding DVPort of the DVSwitch.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      List<DistributedVirtualPort> oldDVPorts = null;
      List<DistributedVirtualPort> newDVPorts = null;
      List<String> usedPorts = null;
      boolean testDone = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      Comparator<DistributedVirtualPort> comparator = this.iDVS.getPortComparator();

         portCriteria = this.iDVS.getPortCriteria(true, null, null,
                  new String[] { this.pgKey }, null, true);
         usedPorts = this.iDVS.fetchPortKeys(this.dvsMor, portCriteria);
         if (usedPorts != null && usedPorts.size() > 0) {
            if (this.iDVS.refreshPortState(this.dvsMor,
                     usedPorts.toArray(new String[usedPorts.size()]))) {
               oldDVPorts = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
               if (oldDVPorts != null) {
                      log.info("Successfully executed the remote ssh command");
                      if (this.ihs.disconnectHost(hostMor)
                               && (this.ihs.reconnectHost(hostMor, hostConnectSpec, null))) {
                              if (this.iDVS.refreshPortState(
                                       this.dvsMor,
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
                                                && newDVPorts.get(i).getState() != null) {
                                          if (!this.iDVS.comparePortState(
                                                   oldDVPorts.get(i).getState(),
                                                   newDVPorts.get(i).getState())) {
                                             log.error("The port state is not"
                                                      + " retained");
                                             break;
                                          } else {
                                             testDone = true;
                                          }
                                       }
                                    }
                                 } else {
                                    testDone = false;
                                    log.error("Can not retrieve the ports");
                                 }
                              } else {
                                 testDone = false;
                                 log.error("Can not refresh the port state");
                              }
                           } else {
                              testDone = false;
                              log.error("the host is still disconnected "
                                       + this.hostName);
                           }
               } else {
                  log.error("Can not retrieve the port state based on the "
                           + "port criteria passed");
                  testDone = false;
               }
            } else {
               testDone = false;
               log.error("Can not retrieve the used ports on the DVS");
            }
         } else {
            testDone = false;
            log.error("Can not retrieve the used ports");
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
      try {
         if (!this.ihs.isHostConnected(this.hostMor)) {
            if (!this.ihs.isHostConnected(this.hostMor)) {
               Assert.assertTrue(this.ihs.reconnectHost(hostMor,
                        this.hostConnectSpec, null), " Host not connected");
            }
         }
         if (cleanUpDone) {
            if (this.ihs.isHostConnected(this.hostMor)) {
               log.info("Successfully connected the host back to the VC "
                        + this.hostName);
               if (this.vmMor != null) {
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
                           log.error("Can not restore the VM to the "
                                    + "original configuration");
                        }
                     }
                     if (cleanUpDone) {
                        if (this.oldPowerState != null) {
                           cleanUpDone &= this.ivm.setVMState(this.vmMor,
                                    this.oldPowerState, false);
                           if (cleanUpDone) {
                              log.info("Successfully restored the original "
                                       + "power state for the vm "
                                       + this.vmName);
                           } else {
                              log.error("Can not restore the original power"
                                       + " state for the VM " + this.vmName);
                           }
                        }
                     }
                  } else {
                     log.error("Can not power off the VM " + this.vmName);
                  }
               }
            } else {
               cleanUpDone = false;
               log.error("The host is still disconnected "
                        + this.hostName);
            }
         }
         if (cleanUpDone) {
            cleanUpDone &= super.testCleanUp();
         }
      } catch (Exception e) {
         cleanUpDone = false;
         TestUtil.handleException(e);
      } finally {
         try {
            if (this.connection != null) {
               SSHUtil.closeSSHConnection(this.connection);
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
