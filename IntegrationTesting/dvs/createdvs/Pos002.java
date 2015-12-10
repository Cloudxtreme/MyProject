/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid nested folder with the following parameters set
 * in the config spec. DVSConfigSpec.configVersion is set to an empty string.
 */
public class Pos002 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private ManagedObjectReference nestedFolder = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid nested "
               + "folder");
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
      String folderName = this.getTestId()
               + DVSTestConstants.DVS_NESTED_FOLDER_NAME_SUFFIX;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.nestedFolder = this.iFolder.createFolder(
                        this.networkFolderMor, folderName);
               if (this.nestedFolder != null) {
                  this.configSpec = new DVSConfigSpec();
                  this.configSpec.setConfigVersion("");
                  this.configSpec.setName(this.getClass().getName());
                  status = true;
               } else {
                  log.error("Failed to create the nested folder");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         } else {
            log.error("Test setup failed.");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a DVSwitch inside a valid nested "
               + "folder")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.nestedFolder, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               if (iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
                        this.configSpec, null)) {
                  status = true;
               } else {
                  log.info("The config spec of the Distributed Virtual Switch"
                           + "is not created as per specifications");
               }
            } else {
               log.error("Cannot create the distributed "
                        + "virtual switch with the config spec passed");
            }
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
     
         status &= super.testCleanUp();
         if (status) {
            if (this.nestedFolder != null) {
               status &= this.iManagedEntity.destroy(this.nestedFolder);
               if (status) {
                  log.info("Successfully destroyed the created "
                           + "nested folder");
               } else {
                  log.error("Cannot destroy the created nested "
                           + "folder");
               }
            }
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}