/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.performproductspecoperation;

import static com.vmware.vcqa.util.Assert.assertFalse;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import com.vmware.vc.InvalidRequest;
import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;


/**
 * DESCRIPTION:<br>
 * (Test case for ProductSpecOperation ) <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * TEST:<br>>
 * 1.Invoke perform ProductSpecOperation api by passing null mor<BR>
 * CLEANUP:<br>
 */
public class Neg001 extends TestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Invoke perform ProductSpecOperation api by passing"
               + " null mor");
   }

   /**
    * Method to set up the Environment for the test.
    *
    * @param connectAnchor Reference to the ConnectAnchor object.
    * @return True, if test set up was successful False, if test set up was not
    *         successful
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp() throws Exception
   {
      DVS = new DistributedVirtualSwitch(connectAnchor);
      return true;
   }


   @Test(description = "Invoke perform ProductSpecOperation api by passing"
               + " null mor")
   public void test()
      throws Exception
   {
      try {
         assertFalse(this.DVS.performProductSpecOperation(
                  null, DVSTestConstants.OPERATION_PROCEEDWITHUPGRADE, null),
                  " performProductSpecOperation failed",
                  " Successfully completed performProductSpecOperation");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidRequest();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Setting the expected Exception.
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new InvalidRequest();
   }

   /**
    * Method to restore the state, as it was, before setting up the test
    * environment.
    *
    * @return True, if test clean up was successful False, if test clean up was
    *         not successful
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }
}
