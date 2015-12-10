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
import java.util.ArrayList;

import com.vmware.vc.DVSFeatureCapability;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.i18n.I18NDataProviderConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<br>
 * (Test case for queryfeaturecapability) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1.Invoke querySupportedSwitchSpec to return the productSpec array<BR>
 * 2.Get the productSpec for given vDs version<BR>
 * 3.Set the productSpec with name as i18N string.<BR>
 * TEST:<BR>
 * 4.Invoke queryFeatureCapability with productSpec from step 3<BR>
 * CLEANUP:<BR>
 */
public class I18N001 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager =
      null;
   private ManagedObjectReference dvsManagerMor = null;
   private DistributedVirtualSwitchProductSpec switchProductSpec = null;
   // i18n: dataProvider object
   private I18NDataProvider dataProvider = null;
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
      setTestDescription("Query the vDS for a new vDs version Product Spec "
               + "having name set as an i18N string");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
   throws Exception
   {
      boolean setupDone = false;
      ArrayList<String> nameArr = null;
      dvsManager =
         new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      // i18n: get DataProvider object from factory implementation.
      dataProvider = new I18NDataProvider();
      version = this.data.getString("NEW_VDS_VERSION");
      nameArr =
         dataProvider.getData(I18NDataProviderConstants.MULTI_LANG_KEY,
                  I18NDataProviderConstants.MAX_STRING_LENGTH);
      for (String specName : nameArr) {
         log.info("Name = " + specName);
         switchProductSpec = DVSUtil.getProductSpec(connectAnchor, version);
         switchProductSpec =
            DVSUtil.createProductSpec(specName, switchProductSpec
                     .getVendor(), switchProductSpec.getVersion(), null,
                     null, null, null);
         assertNotNull(switchProductSpec,
                  "Successfully created  the productSpec",
         "Null returned for productSpec");
         setupDone = true;
         break;
      }
      return setupDone;
   }

   @Test(description = "Query the vDS for a new vDs version Product Spec "
               + "having name set as an i18N string")
   public void test()
   throws Exception
   {
      DVSFeatureCapability featureCapability = null;
      log.info("Invoking  queryDvsFeatureCapability..");
      featureCapability =
         this.dvsManager.queryDvsFeatureCapability(
                  dvsManagerMor, switchProductSpec);
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
