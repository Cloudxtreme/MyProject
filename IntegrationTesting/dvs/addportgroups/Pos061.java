/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Add an late binding portgroup to the DVSwitch with an community pvlan id in
 * the default port config.
 */
public class Pos061 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private NetworkSystem ins = null;
   private HostSystem ihs = null;
   private VirtualMachine ivm = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference nwSystemMor = null;
   private DistributedVirtualSwitchHelper iDVSwitch = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private List<DVPortgroupConfigSpec> dvPortgroupConfigSpec = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private Vector vmMors = null;
   private static final int PROMISCUOUS_PVLAN_ID = 10;
   private static final int COMMUNITY_PVLAN_ID = 20;
   private Map<ManagedObjectReference, VirtualMachineConfigSpec> originalVMConfigMap = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add an late binding portgroup to the DVSwitch with "
               + "an community pvlan id in the default port config.");
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
      boolean status = false;
      log.info("Test setup Begin:");
      Map allHosts = null;
      ManagedObjectReference tempMor = null;
      DVPortgroupConfigSpec portgroupConfigSpec = null;
      VMwareDVSPortSetting portSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      Map<String, Object> settingsMap = null;
      Iterator it = null;
     
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitchHelper(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.ins = new NetworkSystem(connectAnchor);
         this.ihs = new HostSystem(connectAnchor);
         this.ivm = new VirtualMachine(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         if (this.rootFolderMor != null) {
            log.info("Successfully created the distributed "
                     + "virtual switch");
            allHosts = this.ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            if (allHosts != null && allHosts.keySet() != null) {
               while (allHosts.keySet().iterator().hasNext()) {
                  tempMor = (ManagedObjectReference) allHosts.keySet().iterator().next();
                  if (tempMor != null) {
                     this.vmMors = this.ihs.getVMs(tempMor, null);
                     if (this.vmMors != null && this.vmMors.size() >= 2) {
                        this.hostMor = tempMor;
                        if (this.vmMors.size() > 2) {
                           it = this.vmMors.iterator();
                           it.next();
                           it.next();
                           while (it.hasNext()) {
                              it.next();
                              it.remove();
                           }
                        }
                        break;
                     }
                  }
               }
            }
            if (this.hostMor != null) {
               log.info("Using the host "
                        + this.ihs.getHostName(this.hostMor));
               this.nwSystemMor = this.ins.getNetworkSystem(this.hostMor);
               this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
                        this.getTestId(), this.hostMor);
               if (this.dvsMor != null) {
                  log.info("Successfully created the dv switch");
                  this.hostNetworkConfig = this.iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           this.dvsMor, this.hostMor);
                  if (this.hostNetworkConfig != null
                           && this.hostNetworkConfig[0] != null
                           && this.hostNetworkConfig[1] != null) {
                     if (this.ins.updateNetworkConfig(this.nwSystemMor,
                              this.hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY)) {
                        log.info("Successfully updated the network "
                                 + "configuration of the host to the DVS");
                        if (this.iDVSwitch.addSecondaryPvlan(this.dvsMor,
                                 DVSTestConstants.PVLAN_TYPE_COMMINITY,
                                 PROMISCUOUS_PVLAN_ID, COMMUNITY_PVLAN_ID, true)) {
                           log.info("Successfully added the pvlan id to "
                                    + "the DVSwitch");
                           pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
                           pvlanSpec.setPvlanId(COMMUNITY_PVLAN_ID);
                           settingsMap = new HashMap<String, Object>();
                           settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanSpec);
                           portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                           this.dvPortgroupConfigSpec = new ArrayList<DVPortgroupConfigSpec>(
                                    1);
                           portgroupConfigSpec = new DVPortgroupConfigSpec();
                           portgroupConfigSpec.setConfigVersion("");
                           portgroupConfigSpec.setName(this.getTestId()
                                    + "-pg1");
                           portgroupConfigSpec.setNumPorts(2);
                           portgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
                           portgroupConfigSpec.setDefaultPortConfig(portSetting);
                           this.dvPortgroupConfigSpec.add(portgroupConfigSpec);
                           status = true;
                        } else {
                           log.error("Can not add the pvlan id to the DVS");
                        }
                     } else {
                        log.error("Can not modify the network configuration "
                                 + "of the host");
                     }
                  } else {
                     log.error("Can not get the host network config to "
                              + "update to");
                  }
               } else {
                  log.error("Failed to create the distributed virtual "
                           + "switch");
               }
            } else {
               log.error("Can not find a valid host in the setup");
            }
         } else {
            log.error("Failed to find a folder");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test method.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add an late binding portgroup to the DVSwitch with "
               + "an community pvlan id in the default port config.")
   public void test()
      throws Exception
   {
      boolean status = false;
      log.info("Test Begin:");
      ManagedObjectReference vm1Mor = null;
      ManagedObjectReference vm2Mor = null;
      String vm1IP = null;
      String vm2PvlanIP = null;
      boolean isSrcWindows = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      VirtualMachineConfigSpec originalVMConfigSpec = null;
      VirtualMachineConfigInfo vm1ConfigInfo = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      String portgroupKey = null;
      String switchUUID = null;
     
         this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                  this.dvsMor,
                  this.dvPortgroupConfigSpec.toArray(new DVPortgroupConfigSpec[this.dvPortgroupConfigSpec.size()]));
         if (this.dvPortgroupMorList != null
                  && this.dvPortgroupMorList.size() == 1
                  && this.dvPortgroupMorList.get(0) != null) {
            portConnection = new DistributedVirtualSwitchPortConnection();
            switchUUID = this.iDVSwitch.getConfig(this.dvsMor).getUuid();
            portConnection.setSwitchUuid(switchUUID);
            portgroupKey = this.iDVPortgroup.getConfigInfo(
                     this.dvPortgroupMorList.get(0)).getKey();
            portConnection.setPortgroupKey(portgroupKey);
            vm1Mor = (ManagedObjectReference) this.vmMors.get(0);
            vm1ConfigInfo = this.ivm.getVMConfigInfo(vm1Mor);
            if (vm1ConfigInfo != null
                     && vm1ConfigInfo.getGuestFullName().indexOf("Windows") != -1) {
               isSrcWindows = true;
            }
            originalVMConfigSpec = DVSUtil.configureVM(connectAnchor, vm1Mor,
                     this.hostMor, portConnection);
            if (originalVMConfigSpec != null) {
               if (this.originalVMConfigMap == null) {
                  this.originalVMConfigMap = new HashMap<ManagedObjectReference, VirtualMachineConfigSpec>();
               }
               this.originalVMConfigMap.put(vm1Mor, originalVMConfigSpec);
            }
            vm2Mor = (ManagedObjectReference) this.vmMors.get(1);
            vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                     vm2Mor,
                     connectAnchor,
                     new DistributedVirtualSwitchPortConnection[] { portConnection });
            if (vmConfigSpec != null && vmConfigSpec[0] != null
                     && vmConfigSpec[1] != null) {
               originalVMConfigSpec = vmConfigSpec[1];
               if (originalVMConfigSpec != null) {
                  if (this.originalVMConfigMap == null) {
                     this.originalVMConfigMap = new HashMap<ManagedObjectReference, VirtualMachineConfigSpec>();
                  }
                  this.originalVMConfigMap.put(vm2Mor, originalVMConfigSpec);
               }
               if (this.ivm.reconfigVM(vm2Mor, vmConfigSpec[0])) {
                  log.info("Successfully reconfigured the VM's");
                  if (this.ivm.powerOnVMs(this.vmMors, false)) {
                     log.info("Successfully powered on the VM's");
                     DVSUtil.WaitForIpaddress();
                     vm1IP = this.ivm.getIPAddress(vm1Mor);
                     if (vm1IP != null) {
                        log.info("Successfully got the IP");
                        vm2PvlanIP = this.ivm.getAllIPAddresses(vm2Mor).remove(
                                 DVSUtil.getMac(originalVMConfigSpec));
                        if (vm2PvlanIP != null) {
                           status = DVSUtil.checkNetworkConnectivity(vm1IP,
                                    vm2PvlanIP, !isSrcWindows);
                        } else {
                           log.error("Can not get a valid pvlan ip for the"
                                    + " VM " + this.ivm.getVMName(vm2Mor));
                        }
                     } else {
                        log.error("Can not get a valid IP for the VM "
                                 + this.ivm.getVMName(vm1Mor));
                     }
                  } else {
                     log.error("Can not power on the VM's");
                  }
               }
            } else {
               log.error("Can not obtain the original and updated config "
                        + "spec for the VM");
            }
         } else {
            log.error("Failed to add the portgroups to the DVS "
                     + this.getTestId());
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      Iterator<ManagedObjectReference> it = null;
      ManagedObjectReference vmMor = null;
     
         if (this.vmMors != null) {
            status &= this.ivm.setVMsState(this.vmMors, VirtualMachinePowerState.POWERED_OFF, false);
            if (this.originalVMConfigMap != null) {
               it = this.originalVMConfigMap.keySet().iterator();
               while (it.hasNext()) {
                  vmMor = it.next();
                  status &= this.ivm.reconfigVM(vmMor,
                           this.originalVMConfigMap.get(vmMor));
               }
            }
         }
         if (this.dvPortgroupMorList != null) {
            for (ManagedObjectReference mor : dvPortgroupMorList) {
               status &= this.iManagedEntity.destroy(mor);
            }
         }
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}