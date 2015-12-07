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

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;

/**
 * Create a dvswitch and pass the same dvswitch MORs as parameters, i.e., Merge
 * the switch with itself
 */
public class Pos041 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dcMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Create a dvswitch and pass the same dvswitch "
               + "MORs as parameters, i.e., Merge the switch with " + "itself");
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
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(this.getClass().getName());
            this.srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(this.dcMor), configSpec);
            if (this.srcDvsMor != null) {
               log.info("Successfully created the destination "
                        + "distributed virtual switch");
               status = true;
            } else {
               log.error("Could not create the destination "
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
   @Test(description = "Create a dvswitch and pass the same dvswitch "
               + "MORs as parameters, i.e., Merge the switch with " + "itself")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(this.srcDvsMor, this.srcDvsMor)) {
            log.info("Successfully merged the switches");
            if (this.iDVSwitch.isExists(this.srcDvsMor)) {
               log.info("The source DVS still exists");
               status = true;
            } else {
               log.error("The source DVS is deleted");
            }
         } else {
            log.error("Failed to merge the switches but the API "
                     + "did not throw an exception");
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
     
         if (this.srcDvsMor != null
                  && this.iManagedEntity.isExists(this.srcDvsMor)) {
            status = this.iManagedEntity.destroy(srcDvsMor);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}