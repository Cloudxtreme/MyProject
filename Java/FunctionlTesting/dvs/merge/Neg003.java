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

import com.vmware.vc.InvalidRequest;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;

/**
 * Merge a destination DVS with null MOR with a source DVS with null MOR
 */
public class Neg003 extends TestBase
{
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DistributedVirtualSwitch iDVSwitch = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Merge a destination DVS with a null MOR "
               + "with a source DVS which has a null  MOR");
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
    * Method that merges two distributed virtual switches.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge a destination DVS with a null MOR "
               + "with a source DVS which has a null  MOR")
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
         MethodFault expectedMethodFault = new InvalidRequest();
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