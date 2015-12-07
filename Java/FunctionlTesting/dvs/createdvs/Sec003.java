/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.PrivilegeConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

public class Sec003 extends CreateDVSTestBase
{
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;
   private final String privilege = DVSWITCH_CREATE;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      configSpec = DVSUtil.createDefaultDVSConfigSpec(getTestId());
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(),
               data.getString(TESTINPUT_USERNAME),
               data.getString(TESTINPUT_PASSWORD));
      authHelper.setPermissions(dcMor, privilege, testUser, true);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Create a DVSwitch inside a valid folder by a"
            + " user having  DVSwitch.create privilege. The DVS parameters are to be"
            + " set as follows:\n"
            + " - DVSConfigSpec.configVersion set to an empty string,\n"
            + " - DVSConfigSpec.name set to 'Create  DVS-Sec003'.")
   public void test()
      throws Exception
   {
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, DVS_CREATE_PASS, DVS_CREATE_FAIL);
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (authHelper != null) {
         status &= authHelper.performSecurityTestsCleanup();
      }
      try {
         if (dvsMOR != null) {
            dvsMOR = iFolder.getDistributedVirtualSwitch(networkFolderMor,
                     configSpec.getName());
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
