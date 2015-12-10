/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigInfo;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkTrafficShapingPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareDVSPortgroupPolicy;
import com.vmware.vc.VMwareDVSPvlanConfigSpec;
import com.vmware.vc.VMwareDVSPvlanMapEntry;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestBase;
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
 * Reconfigure an early binding portgroup to an existing distributed virtual
 * switch with settingUplinkTeamingOverrideAllowed set to true
 */
public class Pos047 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private VMwareDVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private VirtualMachine iVirtualMachine = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private String portgroupKey = null;
   private Map<String, List<String>> usedPorts = null;
   private VirtualMachineConfigSpec[] vmDeltaConfigSpec = null;
   private DistributedVirtualSwitchHostMemberPnicSpec[] dvsHostMemberPnicSpec = null;
   private String portKey = null;
   private ManagedObjectReference dcMor = null;
   private VMwareDVSPvlanConfigSpec[] pvlanConfigSpec = null;
   private VMwareDVSPortSetting dvsPortSetting = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Reconfigure an early binding portgroup to an "
               + "existing distributed virtual switch with "
               + "settingUplinkTeamingOverrideAllowed set to true");
   }

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
      String className = null;
      String nameParts[] = null;
      String portgroupName = null;
      final String dvsName = super.getTestId();
      String[] physicalNics = null;
      VMwareDVSPortSetting dvPortgroupSetting = null;
      DVPortConfigSpec portConfigSpec = null;
      VMwareDVSPvlanMapEntry mapEntry = null;
      HostNetworkTrafficShapingPolicy dvsInshapingPolicy = null;
      HostNetworkTrafficShapingPolicy dvPortgroupInshapingPolicy = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanspec = null;
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      int len = 0;
      int i = 0;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      VirtualMachineConfigInfo vmConfigInfo = null;
      VirtualDevice[] vds = null;
      Vector allVMs = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iHostSystem = new HostSystem(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.rootFolderMor = this.iFolder.getRootFolder();
         this.dcMor = this.iFolder.getDataCenter();
         if (this.rootFolderMor != null) {
            this.dvsConfigSpec = new VMwareDVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(dvsName);
            this.dvsConfigSpec.setNumStandalonePorts(9);
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               portKey = iDVSwitch.getFreeStandaloneDVPortKey(dvsMor, null);
               dvsPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(null);
               portConfigSpec = new DVPortConfigSpec();
               portConfigSpec.setOperation(ConfigSpecOperation.EDIT.value());
               portConfigSpec.setKey(portKey);
               dvsPortSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                        new Boolean(false)));
               dvsPortSetting.setLacpPolicy(null);
               portConfigSpec.setSetting(dvsPortSetting);
               if (this.iDVSwitch.reconfigurePort(dvsMor,
                        new DVPortConfigSpec[] { portConfigSpec })) {
                  log.info("Successfully reconfigured the port");

                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                  this.dvPortgroupConfigSpec.setConfigVersion("");
                  this.dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
                  this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
                  this.dvPortgroupConfigSpec.setNumPorts(1);
                  this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
                  this.dvPortgroupMorList = this.iDVSwitch.addPortGroups(
                           dvsMor,
                           new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
                  if (this.dvPortgroupMorList != null
                           && this.dvPortgroupMorList.size() == 1) {
                     log.info("Successfully added the portgroup");
                     status = true;
                  } else {
                     log.error("Failed to add the portgroup");
                  }
               } else {
                  log.error("Failed to reconfigure the port");
               }
            } else {
               log.error("Could not create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a folder");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * create DVPort ConfigSpec
    */
   private DVPortConfigSpec createPortConfigSpec(String key)
   {
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      DVPortConfigSpec configSpec = new DVPortConfigSpec();
      List<DistributedVirtualPort> dvPorts = null;
      DVPortSetting dvPortSetting = null;
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVPortConfigInfo dvPortConfigInfo = null;
      try {
         portCriteria = new DistributedVirtualSwitchPortCriteria();
         portCriteria.getPortKey().clear();
         portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { key }));
         dvPorts = this.iDVSwitch.fetchPorts(this.dvsMor, portCriteria);
         if (dvPorts != null && dvPorts.get(0) != null) {
            log.info("Successfully obtained the port");
            dvPortConfigInfo = dvPorts.get(0).getConfig();
            if (dvPortConfigInfo != null) {
               configSpec.setKey(key);
               configSpec.setOperation(ConfigSpecOperation.EDIT.value());
               dvPortSetting = dvPortConfigInfo.getSetting();
               if (dvPortSetting == null) {
                  dvPortSetting = (VMwareDVSPortSetting) DVSUtil.getDefaultVMwareDVSPortSetting(null);
               }
               dvPortSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                        new Boolean(false)));
               configSpec.setSetting(dvPortSetting);
            } else {
               log.error("Failed to obtain the DVPortConfigInfo");
               configSpec = null;
            }
         } else {
            log.error("Failed to obtain the port " + "config spec");
            configSpec = null;
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return configSpec;
   }

   /**
    * Method that reconfigures an early binding portgroup
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an early binding portgroup to an "
               + "existing distributed virtual switch with "
               + "settingUplinkTeamingOverrideAllowed set to true")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DistributedVirtualPort> dvsPort = null;
      VMwareDVSPortSetting actualPortSetting = null;
      VmwareUplinkPortTeamingPolicy portgroupUplinkTeamingPolicy = null;
      VMwareDVSPortgroupPolicy portgroupPolicy = null;
      VMwareDVSPortSetting dvPortgroupSetting = null;
      Map<String, Object> settingsMap = null;
      try {
         portgroupPolicy = new VMwareDVSPortgroupPolicy();
         portgroupPolicy.setUplinkTeamingOverrideAllowed(true);
         portgroupPolicy.setLivePortMovingAllowed(true);
         portgroupPolicy.setBlockOverrideAllowed(true);
         /*   dvPortgroupSetting = (VMwareDVSPortSetting) this.iDVSwitch.getConfig(this.dvsMor).
                                                      getDefaultPortConfig();*/
         portgroupUplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(
                  false, null, null, true, null, null, null);
         /*  portgroupUplinkTeamingPolicy.setNotifySwitches(
                    DVSUtil.getBoolPolicy(false, true));
           dvPortgroupSetting.setUplinkTeamingPolicy(
                                        portgroupUplinkTeamingPolicy);*/
         settingsMap = new HashMap<String, Object>();
         settingsMap.put(DVSTestConstants.UPLINK_TEAMING_POLICY_KEY,
                  portgroupUplinkTeamingPolicy);
         dvsPortSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
         this.dvPortgroupConfigSpec.setDefaultPortConfig(dvPortgroupSetting);
         this.dvPortgroupConfigSpec.setPolicy(portgroupPolicy);
         this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                  dvPortgroupMorList.get(0)).getConfigVersion());
         if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                  this.dvPortgroupConfigSpec)) {
            log.info("Successfully reconfigured the portgroup");
            portgroupKey = this.iDVPortgroup.getKey(dvPortgroupMorList.get(0));
            if (portgroupKey != null) {
               if (this.iDVSwitch.movePort(dvsMor, new String[] { portKey },
                        portgroupKey)) {
                  log.info("Successfully moved the port into "
                           + "the portgroup");
                  portCriteria = new DistributedVirtualSwitchPortCriteria();
                  portCriteria.setConnected(false);
                  portCriteria.getPortKey().clear();
                  portCriteria.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { portKey }));
                  dvsPort = this.iDVSwitch.fetchPorts(dvsMor, portCriteria);
                  if (dvsPort != null) {
                     log.info("Found the port");
                     if (dvsPort.get(0).getConfig().getSetting() instanceof VMwareDVSPortSetting) {
                        actualPortSetting = (VMwareDVSPortSetting) dvsPort.get(
                                 0).getConfig().getSetting();
                        status = TestUtil.compareObject(
                                 actualPortSetting.getUplinkTeamingPolicy(),
                                 dvsPortSetting.getUplinkTeamingPolicy(), null);
                        if (actualPortSetting.getUplinkTeamingPolicy().getNotifySwitches().isInherited()) {
                           status = true;
                        } else {
                           status = false;
                        }
                     }
                  } else {
                     log.error("Could not find the port");
                  }
               } else {
                  log.error("Failed to move the port into the "
                           + "portgroup");
               }
            } else {
               log.error("Could not get the portgroup key");
            }
         } else {
            log.error("Failed to reconfigure the portgroup");
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
         /*if(this.dvPortgroupMorList != null){
            for(ManagedObjectReference mor: dvPortgroupMorList){
               status &= this.iManagedEntity.destroy(mor);
            }
         }*/
         if (this.dvsMor != null) {
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
