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

import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.util.TestUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS with network folder set to a stale folder MOR
 */
public class Neg004 extends CreateDVSTestBase
{
   ManagedObjectReference folderMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS with network folder set to a "
               + "stale folder MOR");
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
     
         if (super.testSetUp()) {
            String folderName = this.getClass().getName() + "Folder";
            this.folderMor = iFolder.createFolder(iFolder.getRootFolder(),
                     folderName);
            if (this.folderMor != null) {
               log.info("Successfully created Folder " + folderName);
               boolean destroy = false;
               destroy = this.iFolder.destroy(folderMor);
               if (destroy) {
                  this.configSpec = new VMwareDVSConfigSpec();
                  this.configSpec.setConfigVersion("");
                  this.configSpec.setName(this.getClass().getName());
                  status = true;
               }
            }
         } else {
            log.error("Failed to login");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a DVS with network folder set to a "
               + "stale folder MOR")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                  this.folderMor, this.configSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         ManagedObjectNotFound expectedMethodFault = new ManagedObjectNotFound();
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
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}