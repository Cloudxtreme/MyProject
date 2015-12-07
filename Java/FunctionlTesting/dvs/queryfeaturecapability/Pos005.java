/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.queryfeaturecapability;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import com.vmware.vc.DVSFeatureCapability;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * (Test case for queryfeaturecapability) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1.Invoke querySupportedSwitchSpec to return the productSpec array<BR>
 * 2.Get the productSpec for given vDs version<BR>
 * 3.Set the productSpec with name as empty string<BR>
 * TEST:<br>>
 * 4.Invoke queryFeatureCapability with productSpec from step 3<BR>
 * CLEANUP:<BR>
 */
public class Pos005 extends TestBase implements IDataDrivenTest 
{
   private DistributedVirtualSwitchManager dvsManager = null;
   private ManagedObjectReference dvsManagerMor = null;
   private DistributedVirtualSwitchProductSpec switchProductSpec = null;
   private String version = null;

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
               + " 2)Get the productSpec  for given vDs version\n"
               + "3) Set the productSpec with name as empty string \n"
               + "4)Invoke queryFeatureCapability with productSpec from 3)");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      version = this.data.getString("NEW_VDS_VERSION");
      switchProductSpec = DVSUtil.getProductSpec(connectAnchor, version);
      assertNotNull(switchProductSpec,
               "Successfully obtained  the productSpec",
               "Null returned for productSpec");
      switchProductSpec.setName("");
      return true;
   }

   @Test(description = "1)Invoke querySupportedSwitchSpec to"
               + " return the productSpec array\n"
               + " 2)Get the productSpec  for given vDs version\n"
               + "3) Set the productSpec with name as empty string \n"
               + "4)Invoke queryFeatureCapability with productSpec from 3)")
   public void test()
      throws Exception
   {
      DVSFeatureCapability featureCapability = null;
      log.info("Invoking  queryDvsFeatureCapability..");
      featureCapability =
               this.dvsManager.queryDvsFeatureCapability(dvsManagerMor,
                        switchProductSpec);
      assertTrue(DVSUtil.verifyQueryFeatureCapability(featureCapability,
               version), "Test Failed");
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }
   


}
