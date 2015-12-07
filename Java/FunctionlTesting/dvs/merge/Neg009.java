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

import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;

/**
 * Merge two dvswitches with both the dvswitches MOR set to an empty object
 */
public class Neg009 extends TestBase
{
   private DistributedVirtualSwitch iDVSwitch = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Merge two dvswitches with both the dvswitches MOR"
               + " set to an empty object");
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
     
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         status = true;
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge two dvswitches with both the dvswitches MOR"
               + " set to an empty object")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      MethodFault expectedMethodFault = new ManagedObjectNotFound();
      try {
         if (this.iDVSwitch.merge(new ManagedObjectReference(),
                  new ManagedObjectReference())) {
            log.error("Successfully merged the switches but the API "
                     + "did not throw an exception");
         } else {
            log.error("Failed to merge the switches but the API "
                     + "did not throw an exception");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
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
      assertTrue(status, "Cleanup failed");
      return status;
   }
}