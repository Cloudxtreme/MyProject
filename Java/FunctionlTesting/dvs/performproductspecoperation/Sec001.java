/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.performproductspecoperation;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * Upgrade DVS from older vDs version to new vDs version by an user having
 * DVSwitch.Modify privilege<br>
 * SETUP:<br>
 * 1. Create a DVSwitch with older vDs version .<br>
 * 2. Create new vDs version product spec<BR>
 * 3. set 'DVSwitch.Modify' privilege on DVS.<br>
 * 4. Logout Administrator and login as test user.<br>
 * TEST:<br>
 * 5. Invoke perform ProductSpecOperation api<br>
 * CLEANUP:<br>
 * 6. Logout test user and login as Administrator.<br>
 * 7. Destroy the DVS.<br>
 */
public class Sec001 extends TestBase  implements IDataDrivenTest
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private String testUser = GENERIC_USER;
   private String privilege = "DVSwitch.Modify";
   private AuthorizationHelper authHelper;;

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
      setTestDescription(""
               + "Upgrade DVS from older vDs version  to new vDs version"
               + " by a user  having DVSwitch.Modify privilege\n"
               + " 1.Create DVS with older vDs version \n"
               + " 2.Create new vDs version product spec.\n"
               + " 3.Invoke perform ProductSpecOperation api");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
   throws Exception
   {
      DVSCreateSpec createSpec = null;
      DVS = new DistributedVirtualSwitch(connectAnchor);
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
      productSpec =
         DVSUtil.getProductSpec(connectAnchor, this.data
                  .getString(DVSTestConstants.NEW_VDS_VERSION));
      assertNotNull(productSpec, "Successfully obtained  the productSpec",
      "Null returned for productSpec");
      authHelper =
         new AuthorizationHelper(connectAnchor, getTestId(), data
                  .getString(TestConstants.TESTINPUT_USERNAME), data
                  .getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, privilege, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Test(description = ""
               + "Upgrade DVS from older vDs version  to new vDs version"
               + " by a user  having DVSwitch.Modify privilege\n"
               + " 1.Create DVS with older vDs version \n"
               + " 2.Create new vDs version product spec.\n"
               + " 3.Invoke perform ProductSpecOperation api")
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
      boolean cleanedUp = true;
      if (authHelper != null) {
         cleanedUp &= authHelper.performSecurityTestsCleanup();
      }
      if (dvsMor != null) {
         cleanedUp &= DVS.destroy(dvsMor);
      }
      return cleanedUp;
   }




}
