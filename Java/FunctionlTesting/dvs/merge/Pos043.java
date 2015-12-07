/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * Merge two dv switches with the following configuration set. a. The soruce DVS
 * mor has pvlan map that contains a promiscuous pvlan map entry of 10, a
 * community map entry of 20, and an isolated map entry of 30. b. The
 * destination dvs mor has the pvlan map as the same as the source dvs mor.
 */
public class Pos043 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference srcDvsMor = null;
   private ManagedObjectReference destDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitchHelper iDVSwitch = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Merge two dv switches with the following "
               + "configuration set. a. The soruce DVS mor has pvlan "
               + "map that contains a promiscuous pvlan map entry of "
               + "10, and an community map entry of 20, and an isolated"
               + " map entry of 30. b. The destination dvs mor has "
               + "the pvlan map as the same as the source dvs mor.");
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
     
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitchHelper(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(this.getTestId() + "_SRC");
            this.srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(this.dcMor), configSpec);
            if (this.srcDvsMor != null) {
               log.info("Successfully created the source "
                        + "distributed virtual switch");
               if (configurePvlan(this.srcDvsMor)) {
                  this.configSpec = new DVSConfigSpec();
                  this.configSpec.setConfigVersion("");
                  this.configSpec.setName(this.getTestId() + "_DEST");
                  this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                           this.iFolder.getNetworkFolder(this.dcMor),
                           configSpec);
                  if (this.destDvsMor != null) {
                     log.info("Successfully created the source "
                              + "distributed virtual switch");
                     if (configurePvlan(this.destDvsMor)) {
                        status = true;
                     }
                  } else {
                     log.error("Could not create the destination"
                              + "distributed virtual switch");
                  }
               }
            } else {
               log.error("Could not create the source "
                        + "distributed virtual switch");
            }
         } else {
            log.error("Can not find a datacenter in the setup");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge two dv switches with the following "
               + "configuration set. a. The soruce DVS mor has pvlan "
               + "map that contains a promiscuous pvlan map entry of "
               + "10, and an community map entry of 20, and an isolated"
               + " map entry of 30. b. The destination dvs mor has "
               + "the pvlan map as the same as the source dvs mor.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(this.destDvsMor, this.srcDvsMor)) {
            log.info("Successfully merged the switches");
            status = true;
         } else {
            log.error("Failed to merge the switches");
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
     
         if (this.srcDvsMor != null
                  && this.iManagedEntity.isExists(this.srcDvsMor)) {
            status &= this.iManagedEntity.destroy(srcDvsMor);
         }
         if (this.destDvsMor != null) {
            status &= this.iManagedEntity.destroy(this.destDvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }

   private boolean configurePvlan(ManagedObjectReference dvsMor)
      throws Exception
   {
      boolean rval = false;
      DVSConfigInfo configInfo = null;
      VMwareDVSPortSetting portSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      DVPortgroupConfigSpec pgConfigSpec = null;
      Map<String, Object> settingsMap = null;
      DVSConfigInfo dvsConfigInfo = null;
      if (this.iDVSwitch.addPvlan(dvsMor,
               DVSTestConstants.PVLAN_TYPE_PROMISCUOUS, 10, 10)
               && this.iDVSwitch.addPvlan(dvsMor,
                        DVSTestConstants.PVLAN_TYPE_COMMINITY, 10, 20)
               && this.iDVSwitch.addPvlan(dvsMor,
                        DVSTestConstants.PVLAN_TYPE_ISOLATED, 10, 30)) {
         dvsConfigInfo = this.iDVSwitch.getConfig(dvsMor);
         this.configSpec = new DVSConfigSpec();
         configInfo = this.iDVSwitch.getConfig(dvsMor);
         this.configSpec.setConfigVersion(configInfo.getConfigVersion());
         pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
         pvlanSpec.setPvlanId(10);
         pvlanSpec.setInherited(false);
         portSetting = (VMwareDVSPortSetting) dvsConfigInfo.getDefaultPortConfig();
         this.configSpec.setDefaultPortConfig(portSetting);
         if (this.iDVSwitch.reconfigure(dvsMor, this.configSpec)) {
            log.info("Successfully set the default port config");
            pgConfigSpec = new DVPortgroupConfigSpec();
            pgConfigSpec.setConfigVersion("");
            pgConfigSpec.setName(this.iDVSwitch.getName(dvsMor) + "-epg");
            pgConfigSpec.setNumPorts(0);
            pgConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
            pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
            pvlanSpec.setPvlanId(20);
            portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
            pgConfigSpec.setDefaultPortConfig(portSetting);
            if (this.iDVSwitch.addPortGroups(dvsMor,
                     new DVPortgroupConfigSpec[] { pgConfigSpec }) != null) {
               pgConfigSpec = new DVPortgroupConfigSpec();
               pgConfigSpec.setConfigVersion("");
               pgConfigSpec.setName(this.iDVSwitch.getName(dvsMor) + "-lpg");
               pgConfigSpec.setNumPorts(0);
               pgConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
               pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
               pvlanSpec.setPvlanId(30);
               settingsMap = new HashMap<String, Object>();
               settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanSpec);
               portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
               pgConfigSpec.setDefaultPortConfig(portSetting);
               if (this.iDVSwitch.addPortGroups(dvsMor,
                        new DVPortgroupConfigSpec[] { pgConfigSpec }) != null) {
                  rval = true;
               } else {

               }
            } else {
               log.error("Can not add the portgroups to the DVS");
            }
         } else {
            log.error("Can not set the pvlan id in the default port setting");
         }
      } else {
         log.error("Can add the pvlan map entry to the DVS");
      }
      return rval;
   }
}