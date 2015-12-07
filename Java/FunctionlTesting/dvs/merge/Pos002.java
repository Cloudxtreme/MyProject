/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Create two dvswitches with the following configuration: a. dest_description =
 * Valid String b. src_description = Valid String Merge the two dvswitches.
 */
public class Pos002 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolder = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dcMor = null;
   private DVSConfigInfo destDvsConfigInfo = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Create two dvswitches with the following "
               + "configuration: a. dest_description = Valid String "
               + "b. src_description = Valid String. Merge the two dvswitches.");
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
      String destDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_DESTINATION_SUFFIX;
      String srcDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_SOURCE_SUFFIX;
      String destDvsDesc = DVSTestConstants.DVS_DESC + this.getTestId()
               + DVSTestConstants.DVS_DESTINATION_SUFFIX;
      String srcDvsDesc = DVSTestConstants.DVS_DESC + this.getTestId()
               + DVSTestConstants.DVS_SOURCE_SUFFIX;

      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         this.rootFolder = this.iFolder.getRootFolder();
         if (this.rootFolder != null) {
            // create the destination dvs
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(destDvsName);
            this.configSpec.setDescription(destDvsDesc);
            destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            // create the src dvs
            this.configSpec.setName(srcDvsName);
            this.configSpec.setDescription(srcDvsDesc);
            srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            // store the destn dvs config info for matching description
            // property
            if (srcDvsMor != null && destDvsMor != null) {
               log.info("Successfully created the source "
                        + "and destination distributed virtual " + "switches");
               this.destDvsConfigInfo = this.iDVSwitch.getConfig(this.destDvsMor);
               status = true;
            } else {
               log.error("Could not create the source or "
                        + "destination distributed virtual " + "switches");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create two dvswitches with the following "
               + "configuration: a. dest_description = Valid String "
               + "b. src_description = Valid String. Merge the two dvswitches.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the switches");
            if (this.iManagedEntity.isExists(srcDvsMor)) {
               log.error("Source DVS still exists.");
            } else {
               if (this.iDVSwitch.isExists(this.destDvsMor)) {
                  DVSConfigInfo mergedDVSConfigInfo = this.iDVSwitch.getConfig(destDvsMor);
                  if (mergedDVSConfigInfo != null) {
                     status = mergedDVSConfigInfo.getDescription().equals(
                              destDvsConfigInfo.getDescription());
                     log.info("Config info verified:" + status);
                  } else {
                     log.error("Merged DVS config info is null.");
                  }
               } else {
                  log.error("Destn DVS does not exist.");
               }
            }
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
      boolean status = false;
     
         // check if src dvs exists
         if (this.iManagedEntity.isExists(this.srcDvsMor)) {
            // check if able to destroy it
            status = this.iManagedEntity.destroy(this.srcDvsMor);
         } else {
            status = true; // src does not exist, so set status as true
         }
         // check if destn dvs exists
         if (this.iManagedEntity.isExists(this.destDvsMor)) {
            // destroy the destn
            status &= this.iManagedEntity.destroy(this.destDvsMor);
         } else {
            status &= true; // the clean up is still true if destn is not
            // present
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}