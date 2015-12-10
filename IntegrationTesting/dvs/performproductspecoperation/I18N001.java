/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.performproductspecoperation;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import java.util.ArrayList;

import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.i18n.I18NDataProvider;
import com.vmware.vcqa.i18n.I18NDataProviderConstants;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * (Test case for ProductSpecOperation ) <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1.Create DVS with older vDs version <br>
 * 2.Create new vDs version product spec by passing valid i18N string in name
 * parameter in product spec<BR>
 * TEST:<br>>
 * 3.Invoke perform ProductSpecOperation by passing upgrade operation and new
 * vDs product spec <br>
 * CLEANUP:<br>
 * 4. Destroy vDs<br>
 */
public class I18N001 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   // i18n: dataProvider object
   private I18NDataProvider dataProvider = null;

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

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Invoke perform ProductSpecOperation api by passing "
               + "upgrade operation and new vDs version, "
               + "valid i18N string in name parameter" + " in product spec");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
   throws Exception
   {
      boolean setupDone = false;
      DVSCreateSpec createSpec = null;
      ArrayList<String> nameArr = null;
      DVS = new DistributedVirtualSwitch(connectAnchor);
      dataProvider = new I18NDataProvider();
      /*
       * Create DVS with older vDs version
       */
      productSpec =
         DVSUtil.getProductSpec(connectAnchor, this.data
                  .getString(DVSTestConstants.OLD_VDS_VERSION));
      createSpec =
         DVSUtil.createDVSCreateSpec(DVSUtil
                  .createDefaultDVSConfigSpec(null), productSpec, null);
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
      "Null returned for Distributed Virtual Switch MOR");
      nameArr =
         dataProvider.getData(I18NDataProviderConstants.MULTI_LANG_KEY,
                  I18NDataProviderConstants.MAX_STRING_LENGTH);
      for (String specName : nameArr) {
         log.info("Name = " + specName);
         productSpec =
            DVSUtil.getProductSpec(connectAnchor, this.data
                     .getString(DVSTestConstants.NEW_VDS_VERSION));
         productSpec =
            DVSUtil.createProductSpec(specName, productSpec.getVendor(),
                     productSpec.getVersion(), null, null, null, null);
         assertNotNull(productSpec, "Successfully created  the productSpec",
         "Null returned for productSpec");
         setupDone = true;
         break;
      }
      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   @Test(description = "Invoke perform ProductSpecOperation api by passing "
               + "upgrade operation and new vDs version, "
               + "valid i18N string in name parameter" + " in product spec")
   public void test()
   throws Exception
   {
      assertTrue(this.DVS.performProductSpecOperation(dvsMor,
               DVSTestConstants.OPERATION_UPGRADE, productSpec),
               " Successfully completed performProductSpecOperation",
      " performProductSpecOperation failed");

   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
   throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "dvsMor destroyed successfully",
         "dvsMor could not be removed");
      }
      return true;
   }

}
