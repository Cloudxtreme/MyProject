/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
import java.util.Vector;

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Reconfigure a late binding portgroup to an existing distributed virtual
 * switch with bindingOnHostAllowed set to true
 */
public class Pos039 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private VirtualMachineConfigSpec[] updatedDeltaConfigSpec = null;
   private ManagedObjectReference dcMor = null;
   private boolean isEESXHost = false;
   private HostConnectSpec hostConnectSpec = null;

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      Vector allVMs = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iVirtualMachine = new VirtualMachine(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         /*
          * Get a standalone host of version 4.0
          */
         this.hostMor = this.iHostSystem.getAllHost().get(0);
         if (hostMor != null) {
            hostConnectSpec = this.iHostSystem.getHostConnectSpec(hostMor);
            if (this.dcMor != null) {
               this.isEESXHost = this.iHostSystem.isEesxHost(hostMor);
               this.dvsConfigSpec = new DVSConfigSpec();
               this.dvsConfigSpec.setConfigVersion("");
               this.dvsConfigSpec.setName(dvsName);
               hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               hostConfigSpecElement.setHost(hostMor);
               hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               /*
                * TODO Check whether the pnic devices need to be
                * set in the DistributedVirtualSwitchHostMemberPnicSpec
                */
               pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
               hostConfigSpecElement.setBacking(pnicBacking);
               this.dvsConfigSpec.getHost().clear();
               this.dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
               dvsMor = this.iFolder.createDistributedVirtualSwitch(
                        this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
               if (dvsMor != null) {
                  log.info("Successfully created the distributed "
                           + "virtual switch");
                  hostNetworkConfig = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           this.dvsMor, this.hostMor);
                  this.nsMor = this.iNetworkSystem.getNetworkSystem(hostMor);
                  if (nsMor != null) {
                     this.iNetworkSystem.updateNetworkConfig(nsMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                     this.originalNetworkConfig = hostNetworkConfig[1];

                  } else {
                     log.error("Network system MOR is null");
                  }
                  allVMs = this.iHostSystem.getVMs(hostMor, null);
                  /*
                   * Get the first VM in the list of VMs.
                   */
                  if (allVMs != null) {
                     this.vmMor = (ManagedObjectReference) allVMs.get(0);
                  }
                  if (this.vmMor != null) {
                     this.vmPowerState = this.iVirtualMachine.getVMState(vmMor);
                     if (this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
                        log.info("Successfully powered off the"
                                 + " virtual machine");
                        this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                        this.dvPortgroupConfigSpec.setConfigVersion("");
                        this.dvPortgroupConfigSpec.setName(this.getTestId());
                        this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
                        this.dvPortgroupConfigSpec.setNumPorts(5);
                        dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                                 dvsMor,
                                 new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
                        if (dvPortgroupMorList != null
                                 && dvPortgroupMorList.get(0) != null) {
                           log.info("Successfully added the "
                                    + "portgroup");
                           status = true;
                        } else {
                           log.error("Failed to add the " + "portgroups");
                        }
                     }
                  } else {
                     log.error("Failed to find a virtual machine");
                  }
               } else {
                  log.error("Failed to create the distributed "
                           + "virtual switch");
               }
            } else {
               log.error("Failed to find a folder");
            }
         } else {
            log.error("Failed to login");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures an early binding portgroup with scope set to a
    * virtual machine MOR and reconfigures a VM-vnic to connect to this
    * portgroup
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure a late binding portgroup to an "
               + "existing distributed virtual switch with "
               + "bindingOnHostAllowed set to true")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVPortgroupPolicy portgroupPolicy = null;
      ConnectAnchor hostConnectAnchor = null;
      String hostIpAddress = null;
      String vmIpAddress = null;
      String vmName = null;
      try {
         hostIpAddress = this.iHostSystem.getIPAddress(hostMor);
         this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
         this.dvPortgroupConfigSpec.setConfigVersion("");
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  this.dvPortgroupMorList.get(0)).getConfigVersion());
         portgroupPolicy = new DVPortgroupPolicy();
         this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.info("Successfully reconfigured the portgroup");
            portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
            if (portgroupKey != null) {
               vmName = this.iVirtualMachine.getVMName(this.vmMor);
               portConnection = new DistributedVirtualSwitchPortConnection();
               portConnection.setPortgroupKey(portgroupKey);
               portConnection.setSwitchUuid(this.iDVSwitch.getConfig(
                        this.dvsMor).getUuid());
               updatedDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                        vmMor,
                        connectAnchor,
                        new DistributedVirtualSwitchPortConnection[] { portConnection });
               if (updatedDeltaConfigSpec != null) {
                  if (this.iVirtualMachine.reconfigVM(vmMor,
                           updatedDeltaConfigSpec[0])) {
                     log.info("Successfully reconfigured the VM"
                              + " to connect to a free port in the "
                              + "portgroup");
                     if (this.iHostSystem.disconnectHost(hostMor)) {
                        hostConnectAnchor = new ConnectAnchor(
                                 hostIpAddress,
                                 data.getInt(TestConstants.TESTINPUT_PORT));
                        if (DVSUtil.connectToHostdPowerOnVM(
                                 hostConnectAnchor, vmName)) {
                           if (this.iHostSystem.reconnectHost(hostMor,
                                    this.hostConnectSpec, null)) {
                              vmIpAddress =
                                       this.iVirtualMachine.getIPAddress(vmMor);
                              log.info("Successfully powered on " + "the VM");
                              if (vmIpAddress != null) {
                                 status =
                                          DVSUtil.checkNetworkConnectivity(
                                                   hostIpAddress, vmIpAddress);
                              }
                           }
                        } else {
                           log.error("Failed to power on "
                                    + "the VM");
                        }
                     } else {
                        log.error("Can not disconnect the host");
                     }
                  } else {
                     log.error("Could not reconfigure the VM"
                              + " to connect to a free port in the portgroup");
                  }
               }
            } else {
               log.error("Could not get the portgroup key");
            }
         } else {
            log.error("Coud not reconfigure the portgroup");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the portgroup, followed by the
    * distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (this.hostMor != null && !this.iHostSystem.isHostConnected(this.hostMor)) {
            Assert.assertTrue(this.iHostSystem.reconnectHost(hostMor,
                     this.hostConnectSpec, null), " Host not connected");
         }
         if (this.vmMor != null) {
            if (this.vmPowerState != null) {
               /*
                * Restore the power state of the virtual machine
                */
               status &= this.iVirtualMachine.setVMState(vmMor,
                        this.vmPowerState, false);
            }
            if (this.updatedDeltaConfigSpec != null
                     && this.updatedDeltaConfigSpec[1] != null) {
               /*
                * Restore the original config spec of the virtual machine
                */
               status &= this.iVirtualMachine.reconfigVM(vmMor,
                        updatedDeltaConfigSpec[1]);
            }
         }

         /*
          * Restore the original network config
          */
         if (this.originalNetworkConfig != null) {
            status &= this.iNetworkSystem.updateNetworkConfig(nsMor,
                     originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
            status &= this.iManagedEntity.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}