/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.removenrp;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotSupported;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * DESCRIPTION:Invoke Remove operation on a dvs version 4.0, 4.1<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.create the dvs<BR>
 * 2.enable netiorm<BR>
 * TEST:<BR>
 * 3.Delete the nrp with an invalid name<BR>
 * CLEANUP:<BR>
 * 4.Destroy the dvs<BR>
 */
public class Neg004 extends TestBase implements IDataDrivenTest {

   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;

   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("")String dataFile) throws Exception {
      return TestExecutionUtils.getTests(
                  this.getClass().getName(), dataFile);
   }

   public String getTestName() { return getTestId(); }

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);

      // create the dvs
      dvsMor = folder.createDistributedVirtualSwitch(getTestId(),
               data.getString(DVSTestConstants.VDS_VERSION));

      return true;
   }

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test()
   public void test()
      throws Exception
   {
      try {
         dvs.removeNetworkResourcePool(dvsMor, new String[] { "invalid" });
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NotSupported();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // delete the dvs
      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Invoke Remove operation on a dvs version 4.0, 4.1");
   }

   /**
    * Set the expected exception
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new NotSupported();
   }
}
