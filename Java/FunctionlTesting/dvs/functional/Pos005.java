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

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnecteeConnecteeType;
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
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Disconnect and reconnect the host on which resides a powered off VM that is
 * connected to a standalone DVPort of the DVSwitch.
 */
public class Pos005 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private String[] usedPorts = null;
   private Connection connection = null;
   private String hostName = null;
   private HostConnectSpec hostConnectSpec = null;


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
      Map<String, List<String>> excludedPorts = new HashMap<String, List<String>>();
      String portKey = null;
      List<String> freePorts = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;

         setUpDone = super.testSetUp();
         if (setUpDone) {
            this.hostName = this.ihs.getHostName(this.hostMor);
            hostConnectSpec = this.ihs.getHostConnectSpec(hostMor);
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
                           configSpec = new DVSConfigSpec();
                           configSpec.setNumStandalonePorts(numCards
                                    + configInfo.getNumStandalonePorts());
                           configSpec.setConfigVersion(configInfo.getConfigVersion());
                           setUpDone = this.iDVS.reconfigure(this.dvsMor,
                                    configSpec);
                           if (setUpDone) {
                              for (int i = 0; i < numCards; i++) {
                                 portKey = this.iDVS.getFreeStandaloneDVPortKey(
                                          this.dvsMor, excludedPorts);
                                 if (portKey != null) {
                                    if (freePorts == null) {
                                       freePorts = new ArrayList<String>();
                                    }
                                    freePorts.add(portKey);
                                 }
                              }
                              if (freePorts != null
                                       && freePorts.size() >= numCards) {
                                 this.usedPorts = freePorts.toArray(new String[freePorts.size()]);
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
                                       log.info("Successfully "
                                                + "reconfigured"
                                                + " the VM to use the "
                                                + "DV Ports");
                                       setUpDone = this.ivm.setVMState(vmMor, POWERED_ON, false);
                                       if (setUpDone) {
                                          log.info("Succesfully powered off the "
                                                   + "VM " + this.vmName);
                                          setUpDone = this.ivm.setVMState(
                                                   vmMor, POWERED_OFF, false);
                                          if (setUpDone) {
                                             log.info("Successfully powered"
                                                      + " off the VM "
                                                      + this.vmName);
                                          } else {
                                             log.error("Can not power off the"
                                                      + " VM " + this.vmName);
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
                                 log.error("Can not find enough free "
                                          + "standalone ports to "
                                          + "reconfigure the VM");
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
   @Test(description = "Disconnect and reconnect the host on which resides"
               + " a powered off VM that is connected to a "
               + "standalone DVPort of the DVSwitch. ")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      List<DistributedVirtualPort> oldDVPorts = null;
      List<DistributedVirtualPort> newDVPorts = null;
      boolean testDone = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      Comparator<DistributedVirtualPort> comparator = this.iDVS.getPortComparator();
      String ssh_cmd = null;
      int timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;

         portCriteria = this.iDVS.getPortCriteria(true, null, null, null,
                  this.usedPorts, false);
         if (this.iDVS.refreshPortState(this.dvsMor, this.usedPorts)) {
            oldDVPorts = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
            if (oldDVPorts != null) {
            if (this.ihs.disconnectHost(hostMor)
                     && (this.ihs.reconnectHost(hostMor, hostConnectSpec, null))) {
               if (this.iDVS.refreshPortState(this.dvsMor, this.usedPorts)) {
                  newDVPorts = this.iDVS.fetchPorts(this.dvsMor, portCriteria);
                  if (newDVPorts != null
                           && newDVPorts.size() == oldDVPorts.size()) {
                     Collections.sort(oldDVPorts, comparator);
                     Collections.sort(newDVPorts, comparator);
                     for (int i = 0; i < oldDVPorts.size(); i++) {
                        if (oldDVPorts.get(i) != null
                                 && newDVPorts.get(i) != null
                                 && this.iDVS
                                          .comparePortConnecteeNicType(
                                                   newDVPorts.get(i), DistributedVirtualSwitchPortConnecteeConnecteeType.VM_VNIC.value())
                                 && newDVPorts.get(i).getState() != null) {
                           if (!this.iDVS.comparePortState(oldDVPorts.get(i)
                                    .getState(), newDVPorts.get(i).getState())) {
                              log.error("The port state " + "is not retained");
                              testDone = false;
                              break;
                           } else {
                              testDone = true;
                           }
                        }
                     }
                  } else {
                     testDone = false;
                  }
               }
            } else {
               log.error("Can not suspend the VM");
            }

            } else {
               testDone = false;
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
      try {
         if (!this.ihs.isHostConnected(this.hostMor)) {
            Assert.assertTrue(this.ihs.reconnectHost(hostMor,
                     this.hostConnectSpec, null), " Host not connected");
         }
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

         if (cleanUpDone) {
            cleanUpDone &= super.testCleanUp();
         }
      } catch (Exception e) {
         cleanUpDone = false;
         TestUtil.handleException(e);
      } finally {
         try {
            if (this.connection != null) {
               cleanUpDone &= SSHUtil.closeSSHConnection(this.connection);
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
