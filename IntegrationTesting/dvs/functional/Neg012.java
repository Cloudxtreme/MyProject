/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotFound;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;


/**
 * Query the dvs manager with an invalid dvs uuid.
 */
public class Neg012 extends FunctionalTestBase
{

   // Private member variable variables
   private DistributedVirtualSwitchManager iDVSManager = null;
   private ManagedObjectReference dvsManagerMor = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Query the dvs manager with an invalid dvs uuid");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return true if setup is successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;
     
         this.iDVSManager = new DistributedVirtualSwitchManager(connectAnchor);
         this.dvsManagerMor = this.iDVSManager.getDvSwitchManager();
         if (this.dvsManagerMor != null) {
            setupDone = true;
         }
     
      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   /**
    * Test method.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Query the dvs manager with an invalid dvs uuid")
   public void test()
      throws Exception
   {
      boolean testDone = false;
      /*
       * TODO determine the actual method fault
       */
      MethodFault expectedFault = new NotFound();
      try {
         this.iDVSManager.querySwitchByUuid(this.dvsManagerMor, "invalid uuid");
         testDone = false;
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         testDone = TestUtil.checkMethodFault(actualMethodFault, expectedFault);
      }
      assertTrue(testDone, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return true if cleanup is successful, false otherwise.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanupDone = true;
      assertTrue(cleanupDone, "Cleanup failed");
      return cleanupDone;
   }
}