/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.ArrayList;
import java.util.List;

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Disconnect the host from the VC, Power on the VM that is previously
 * configured to connect to a late binding portgroup.
 */
public class Pos022 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachinePowerState oldPowerState = null;
   private VirtualMachineConfigSpec originalVMConfigSpec = null;
   private String vmName = null;
   private Connection conn = null;
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
      List<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      int numCards = 0;
      DVPortgroupConfigSpec pgConfigSpec = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      VMwareDVSPortgroupPolicy pgPolicy = null;
      List<ManagedObjectReference> portgroups = null;
      ManagedObjectReference portgroup = null;
      String pgKey = null;

         setUpDone = super.testSetUp();
         if (setUpDone) {
            hostConnectSpec = this.ihs.getHostConnectSpec(this.hostMor);
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
                           pgPolicy = new VMwareDVSPortgroupPolicy();
                           pgConfigSpec = new DVPortgroupConfigSpec();
                           pgConfigSpec.setConfigVersion("");
                           pgConfigSpec.setNumPorts(numCards);
                           pgConfigSpec.setType(DVPORTGROUP_TYPE_LATE_BINDING);
                           pgConfigSpec.setName(this.getTestId() + "-pg1");
                           pgConfigSpec.setPolicy(pgPolicy);
                           portgroups = this.iDVS.addPortGroups(
                                    this.dvsMor,
                                    new DVPortgroupConfigSpec[] { pgConfigSpec });
                           if (portgroups != null && portgroups.size() > 0
                                    && portgroups.get(0) != null) {
                              portgroup = portgroups.get(0);
                              pgKey = this.iDVPortgroup.getKey(portgroup);
                              if (pgKey != null) {
                                 portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                          numCards);
                                 for (int i = 0; i < numCards; i++) {
                                    portConnection = new DistributedVirtualSwitchPortConnection();
                                    portConnection.setPortgroupKey(pgKey);
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
                                 log.error("The port key is null");
                              }
                           } else {
                              setUpDone = false;
                              log.error("Cannot add the portgroup to the "
                                       + "DVSwitch ");
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
   @Test(description = "Disconnect the host from the VC, Power on the VM "
               + "that is previously configured to connect to a late"
               + " binding portgroup.")
   public void test()
      throws Exception
   {

      assertTrue(
               (this.ihs.disconnectHost(hostMor))
                        && DVSUtil
                                 .connectToHostdPowerOnVM(
                                          new ConnectAnchor(
                                                   this.ihs
                                                            .getHostName(this.hostMor),
                                                   data
                                                            .getInt(TestConstants.TESTINPUT_PORT)),
                                          this.vmName),
               " Successfully disconnected the host from the VC and  Powered on the VM "
                        + "that is previously configured to connect to a late binding portgroup.",
               " Failed to  disconnect host from the VC and/or  Powere on the VM "
                        + "that is previously configured to connect to a late binding portgroup.");

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
         if (this.hostMor != null
                  && !this.ihs.isHostConnected(this.hostMor)) {
            Assert.assertTrue(this.ihs.reconnectHost(hostMor,
                     this.hostConnectSpec, null), " Host not connected");
         }
         if (this.vmMor != null && cleanUpDone) {
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
      } catch (Exception e) {
         cleanUpDone = false;
         TestUtil.handleException(e);
      } finally {
         try {
            if (this.conn != null) {
               cleanUpDone &= SSHUtil.closeSSHConnection(this.conn);
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