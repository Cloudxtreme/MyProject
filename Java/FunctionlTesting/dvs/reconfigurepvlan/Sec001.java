/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_MODIFY;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_PORTSETTING;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;

/**
 * Add a PVLAN to DVS by a user having PrivilegeConstants.DVSWITCH_MODIFY
 * privilege.
 */
public class Sec001 extends PvlanBase
{
   private String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private AuthorizationManager authentication;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN to DVS by a user having "
               + "\"DVSwitch.Modify\" privilege.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      authentication = new AuthorizationManager(connectAnchor);
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), false,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
      assertNotNull(dvsMor, "Failed to create the DVS");
      String[] perms = new String[] { DVSWITCH_MODIFY, DVSWITCH_PORTSETTING };
      authHelper.setPermissions(dvsMor, perms, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Add a PVLAN to DVS by a user having "
               + "\"DVSwitch.Modify\" privilege.")
   public void test()
      throws Exception
   {
      assertTrue(iVmwareDVS.addPrimaryPvlan(dvsMor, PVLAN1_PRI_1),
               "Failed to add PVLAN.");
      assertTrue(iVmwareDVS.isPvlanIdPresent(dvsMor, PVLAN1_PRI_1),
               "The added PVLAN entry was not found.");
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (authHelper != null) {
         status &= authHelper.performSecurityTestsCleanup();
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
