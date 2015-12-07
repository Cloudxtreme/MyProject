/*
 * *****************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * *****************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertFalse;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
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
 * DESCRIPTION:<br>
 * Reconfigure an early binding portgroup to an existing distributed virtual<br>
 * switch and reconfigure a VM to connect its VNIC to this portgroup with<br>
 * blocked property set to true<br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1. Create a vDS with host<br>
 * 2. Power off a VM on this host<br>
 * 3. Add a portgroup<br>
 * TEST:<br>
 * 4. Reconfigure dvportgroup to set blocked property to true<br>
 * 5. Reconfigure VM vnic to connect to the portgroup<br>
 * CLEANUP:<br>
 * <br>
 * 6. Restore power state of the VM<br>
 * 7. Reconfigure the VM with its original settings<br>
 * 8. Restore the original network settings on the host<br>
 * 9. Destroy the vDs<br>
 */
public class Pos027 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
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
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private ManagedObjectReference dcMor = null;
   private int numEthernetCards = 0;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add an early binding portgroup to an existing "
               + "distributed virtual switch and reconfigure"
               + " a VMvnic to connect to this portgroup with blocked "
               + "property set to true");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    * @throws Exception
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      final String dvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      Vector allVMs = null;
      log.info("Test setup Begin:");
      this.iFolder = new Folder(connectAnchor);
      this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.iVirtualMachine = new VirtualMachine(connectAnchor);
      this.iHostSystem = new HostSystem(connectAnchor);
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.iNetworkSystem = new NetworkSystem(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      /*
       * Get a host in the inventory
       */
      this.hostMor = this.iHostSystem.getConnectedHost(null);
      assertNotNull(this.hostMor, "No host was found in the inventory");
      this.dvsConfigSpec = DVSUtil.addHostsToDVSConfigSpec(
               DVSUtil.createDefaultDVSConfigSpec(dvsName),
               Arrays.asList(this.hostMor));
      dvsMor = this.iFolder.createDistributedVirtualSwitch(
               this.iFolder.getNetworkFolder(dcMor), this.dvsConfigSpec);
      assertNotNull(dvsMor, "The virtual distributed switch could not be "
               + "created in the inventory");
      this.nsMor = this.iNetworkSystem.getNetworkSystem(hostMor);
      assertNotNull(this.nsMor, "The network system mor is null");
      this.iNetworkSystem.refresh(nsMor);
      hostNetworkConfig = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
               this.dvsMor, this.hostMor);
      this.iNetworkSystem.updateNetworkConfig(nsMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY);
      this.originalNetworkConfig = hostNetworkConfig[1];
      allVMs = this.iHostSystem.getVMs(hostMor, null);
      assertNotEmpty(allVMs, "The list of vms on the chosen host is empty");
      this.vmMor = (ManagedObjectReference) allVMs.get(0);
      this.vmPowerState = this.iVirtualMachine.getVMState(vmMor);
      this.numEthernetCards = DVSUtil.getAllVirtualEthernetCardDevices(vmMor,
               connectAnchor).size();
      assertTrue(this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false),
               "Successfully powered " + "off the virtual machine",
               "Failed to power off the virtual " + "machine");
      log.info("Successfully powered off the virtual machine");
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setConfigVersion("");
      this.dvPortgroupConfigSpec.setName(this.getTestId());
      this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      this.dvPortgroupConfigSpec.setNumPorts(this.numEthernetCards);
      this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
      assertTrue(this.dvPortgroupMorList != null
               && this.dvPortgroupMorList.size() == 1,
               "Successfully added the portgroup",
               "Failed to add the portgroup");
      return true;
   }

   /**
    * Method that reconfigures an early binding portgroup and reconfigures
    * VM-vnic(s) to connect to this portgroup
    * 
    * @param connectAnchor ConnectAnchor object
    * @throws Exception
    */
   @Test(description = "Add an early binding portgroup to an existing "
               + "distributed virtual switch and reconfigure"
               + " a VMvnic to connect to this portgroup with blocked "
               + "property set to true")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      DVPortSetting portSetting = null;
      DistributedVirtualSwitchPortConnection[] portConn = new DistributedVirtualSwitchPortConnection[this.numEthernetCards];
      portSetting = this.iDVSwitch.getConfig(dvsMor).getDefaultPortConfig();
      portSetting.setBlocked(DVSUtil.getBoolPolicy(false, true));
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setDefaultPortConfig(portSetting);
      this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
               dvPortgroupMorList.get(0)).getConfigVersion());
      assertTrue(this.iDVPortgroup.reconfigure(this.dvPortgroupMorList.get(0),
               this.dvPortgroupConfigSpec),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");
      portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
      assertNotNull(portgroupKey, "The portgroup key is null");
      for (int i = 0; i < this.numEthernetCards; i++) {
         portConn[i] = DVSUtil.buildDistributedVirtualSwitchPortConnection(
                  this.iDVSwitch.getConfig(dvsMor).getUuid(), null,
                  portgroupKey);
      }
      vmDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(vmMor,
               connectAnchor, portConn);
      assertTrue(
               this.vmDeltaConfigSpec != null
                        && this.vmDeltaConfigSpec.length == 2,
               "Could not get the original "
                        + "and the updated delta config specs for the virtual machine");
      assertTrue(this.iVirtualMachine.reconfigVM(vmMor, vmDeltaConfigSpec[0]),
               "Successfully reconfigured the virtual machine vnics to connect to "
                        + "the portgroup", "Failed to reconfigure the virtual "
                        + "machine vnics to connect to the portgroup");
      assertTrue(this.iVirtualMachine.resetGuestInformation(vmMor),
               "Successfully reset the guest information",
               "Failed to reset the " + "guest information");
      assertTrue(this.iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, true),
               "Successfully powered on " + "the virtual machine",
               "Failed to power on the virtual machine");
      final String guestIp = iVirtualMachine.getIPAddress(vmMor);
      if (guestIp != null) {
         log.info("In some cases we may get old IP, so check for reachability.");
         final String hostIp = iHostSystem.getIPAddress(hostMor);
         assertFalse(DVSUtil.checkNetworkConnectivity(hostIp, guestIp),
                  "IP should not have been reachable!");
      } else {
         log.info("Didn't get DHCP IP as expected");
      }
   }

   /**
    * Method to restore the state as it was before the test was started. Restore
    * the original state of the VM.Destroy the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      /*
       * Restore the power state of the virtual machine
       */
      status &= this.iVirtualMachine.setVMState(vmMor, this.vmPowerState, false);
      /*
       * Restore the original config spec of the virtual machine
       */
      status &= this.iVirtualMachine.reconfigVM(vmMor, vmDeltaConfigSpec[1]);
      /*
       * Restore the original network configuration on the host
       */
      if (this.originalNetworkConfig != null) {
         status &= this.iNetworkSystem.updateNetworkConfig(nsMor,
                  originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
      }
      if (this.dvsMor != null) {
         assertTrue(this.iManagedEntity.destroy(dvsMor), "Successfully "
                  + "deleted the vds", "Failed to delete the vds");
      }
      return true;
   }
}
