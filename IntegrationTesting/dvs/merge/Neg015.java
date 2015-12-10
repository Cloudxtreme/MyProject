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
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotSupported;
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
 * Merge two dv switches with the following properties set. a. The destination
 * DVS has a pvlan map with a promiscuous map entry of 10, and an community map
 * entry of 20. b. The source DVS has a pvlan map entry with a promiscuous map
 * entry of 10, and an community map entry of 30. A late binding portgroup on
 * the DVS is configured to use this in the default port config.
 */
public class Neg015 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
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
      setTestDescription("Merge two dvswitch's with the follwoing properties:"
               + "a. The destination DVS has a  pvlan map with a "
               + "promiscuous map entry of 10, and an community map "
               + "entry of 20. b. The source DVS has a pvlan map "
               + "entry with a promiscuous map entry of 10, and an"
               + " community map entry of 30. A late binding portgroup"
               + " on the DVS is configured to use this in the default"
               + " port config.");
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
      ManagedObjectReference networkFolder = null;
      VMwareDVSPortSetting portSetting = null;
      log.info("Test setup Begin:");
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      DVPortgroupConfigSpec pgConfigSpec = null;
      Map<String, Object> settingsMap = null;
     
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitchHelper(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            networkFolder = this.iFolder.getNetworkFolder(this.dcMor);
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(this.getTestId() + "_src");
            srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     networkFolder, configSpec);
            if (srcDvsMor != null) {
               log.info("Successfully created the source "
                        + "distributed virtual switch");
               if (this.iDVSwitch.addSecondaryPvlan(this.srcDvsMor,
                        DVSTestConstants.PVLAN_TYPE_COMMINITY, 10, 30, true)) {
                  pgConfigSpec = new DVPortgroupConfigSpec();
                  pgConfigSpec.setConfigVersion("");
                  pgConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
                  pgConfigSpec.setName(this.getTestId() + "-lpg");
                  pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
                  pvlanSpec.setPvlanId(30);
                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanSpec);
                  portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                  pgConfigSpec.setDefaultPortConfig(portSetting);
                  if (this.iDVSwitch.addPortGroups(this.srcDvsMor,
                           new DVPortgroupConfigSpec[] { pgConfigSpec }) != null) {
                     this.configSpec.setName(this.getTestId() + "_dest");
                     this.destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                              networkFolder, this.configSpec);
                     if (this.destDvsMor != null) {
                        log.info("Succesfully created the destination dvswitch");
                        if (this.iDVSwitch.addSecondaryPvlan(this.destDvsMor,
                                 DVSTestConstants.PVLAN_TYPE_COMMINITY, 10, 20,
                                 true)) {
                           log.info("Successfully configured the destination "
                                    + "DVS");
                           status = true;
                        } else {
                           log.error("Can not configure the pvlan map entry "
                                    + "on the destination dvs");
                        }
                     } else {
                        log.error("Can not create the destination dvs");
                     }
                  } else {
                     log.error("successfully added the portgroup with the "
                              + "pvlan id in the default port setting");
                  }
               } else {
                  log.error("Can not conmfigure the pvlan mpa entry on "
                           + "the DVS");
               }
            } else {
               log.error("Could not create the source "
                        + "distributed virtual switch");
            }
         } else {
            log.error("There is no datacenter in the vc inventory");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge two dvswitch's with the follwoing properties:"
               + "a. The destination DVS has a  pvlan map with a "
               + "promiscuous map entry of 10, and an community map "
               + "entry of 20. b. The source DVS has a pvlan map "
               + "entry with a promiscuous map entry of 10, and an"
               + " community map entry of 30. A late binding portgroup"
               + " on the DVS is configured to use this in the default"
               + " port config.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.error("Successfully merged the switches but the API "
                     + "did not throw an exception");
         } else {
            log.error("Failed to merge the switches but the API "
                     + "did not throw an exception");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         MethodFault expectedMethodFault = new NotSupported();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
     
         if (this.srcDvsMor != null && this.iDVSwitch.isExists(this.srcDvsMor)) {
            status &= this.iManagedEntity.destroy(srcDvsMor);
         }
         if (this.destDvsMor != null) {
            status &= this.iManagedEntity.destroy(this.destDvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}