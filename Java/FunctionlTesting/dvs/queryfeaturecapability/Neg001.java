/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.queryfeaturecapability;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.InvalidType;
import com.vmware.vc.MethodFault;
import com.vmware.vc.MethodNotFound;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * (Test case for queryfeaturecapability) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1. Invoke querySupportedSwitchSpec to return the productSpec array<BR>
 * 2. Get the productSpec for given vDs version<BR>
 * TEST:<BR>>
 * 3.Invoke queryFeatureCapability on hostmor with productSpec from step 2<BR>
 * CLEANUP:<BR>
 */
public class Neg001 extends TestBase implements IDataDrivenTest
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager = null;
   DistributedVirtualSwitchProductSpec switchProductSpec = null;
   private String version = null;
   private HostSystem hostSystem = null;

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
   public void setTestDescription()
   {
      setTestDescription("1)Invoke querySupportedSwitchSpec to"
               + " return the productSpec array\n"
               + " 2)Get the productSpec  for given  vDs version\n"
               + "3)Invoke queryFeatureCapability with productSpec from 2)"
               + " and passing hostMor  ");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      version = this.data.getString("NEW_VDS_VERSION");
      switchProductSpec = DVSUtil.getProductSpec(connectAnchor, version);
      assertNotNull(switchProductSpec,
               "Successfully obtained  the productSpec",
               "Null returned for productSpec");
      return true;
   }

   @Test(description = "1)Invoke querySupportedSwitchSpec to"
               + " return the productSpec array\n"
               + " 2)Get the productSpec  for given  vDs version\n"
               + "3)Invoke queryFeatureCapability with productSpec from 2)"
               + " and passing hostMor  ")
   public void test()
      throws Exception
   {
      try {
         this.dvsManager.queryDvsFeatureCapability(hostSystem.getAllHost().get(0),
                  switchProductSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidType();
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
      return new MethodNotFound();
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }


}
