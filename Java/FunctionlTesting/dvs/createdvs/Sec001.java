/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.PrivilegeConstants;

import dvs.CreateDVSTestBase;

/**
 * DESCRIPTION:<br>
 * Create a DVS by user having "DVSwitch.Create" privilege on Datacenter with
 * propagate as true.<br>
 * As per bug#526902 propagate should be 'true' to get the MOR of the DVS. <br>
 * NOTE : Bugs #526902<br>
 * <br>
 * SETUP:<br>
 * 1. Set permission on DC for dvsuser having "DVSwitch.Create" privilege with
 * propagate=true<br>
 * 2. Logout of Administrator and login with dvsuser.<br>
 * TEST:<br>
 * 3. Creating the DVS should be successful.<br>
 * CLEANUP:<br>
 * 4. Logout the dvsuser and login with Administrator.<br>
 * 5. Destroy the DVS.<br>
 */
public class Sec001 extends CreateDVSTestBase
{
   private String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create DVS by user having '"
               + PrivilegeConstants.DVSWITCH_CREATE
               + "' privilege on Datacenter with propagate as true.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), MessageConstants.TB_SETUP_FAIL);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      configSpec = new DVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(getTestId());
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(),
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dcMor, PrivilegeConstants.DVSWITCH_CREATE,
               testUser, true);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Create DVS by user having '"
               + PrivilegeConstants.DVSWITCH_CREATE
               + "' privilege on Datacenter with propagate as true.")
   public void test()
      throws Exception
   {
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, MessageConstants.DVS_CREATE_PASS,
               MessageConstants.DVS_CREATE_FAIL);
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = authHelper.performSecurityTestsCleanup();
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
