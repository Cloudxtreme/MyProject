/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import com.vmware.vcqa.IDataDrivenTest;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vcqa.execution.TestExecutionUtils;
import org.testng.annotations.Parameters;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.ElasticPortgroupHelper;

/**
 * DESCRIPTION:<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS with host <BR>
 * TEST:<BR>
 * 2.Create dynamic/ephemeral type of DVPortgroup with autoExpand flag to true <BR>
 * CLEANUP:<BR>
 * 3. Destroy vDs<BR>
 */
public class Neg051 extends TestBase implements IDataDrivenTest  
{
   private final ElasticPortgroupHelper helper = new ElasticPortgroupHelper();

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("")String dataFile) throws Exception {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }
   public String getTestName()
   {
      return getTestId();
   }
   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("Add a DVPortgroup(dynamic/ephemeral) with  autoExpand  flag to true. ");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      String dvpgType =
               this.data.getString(DVSTestConstants.DVPORTGROUP_TYPE,
                        DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL);
      log.info(" DVPORTGROUP_TYPE :" + dvpgType);
      helper.init(connectAnchor);
      helper.createDvsWithHostAttached();
      helper.getDVPGConfigSpec().setType(dvpgType);
      helper.getDVPGConfigSpec().setNumPorts(0);
      helper.getDVPGConfigSpec().setAutoExpand(true);
      return true;
   }

   @Test(description = "Add a DVPortgroup(dynamic/ephemeral) with  autoExpand  flag to true. ")
   public void test()
      throws Exception
   {
      try {
         helper.addDVPG();
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
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
      return new InvalidArgument();
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return helper.destroyDVS();
   }
   

}
