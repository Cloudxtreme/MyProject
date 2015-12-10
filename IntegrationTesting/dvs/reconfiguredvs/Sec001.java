/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_MODIFY;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;

import dvs.CreateDVSTestBase;

/**
 * DESCRIPTION:<br>
 * Reconfigure DVS to set a different name by user not having "DVSwitch.Modify"
 * privilege.<br>
 * <br>
 * TARGET: VC<br>
 * VERSION-ESX : 4.0 and above<br>
 * VERSION-EESX: 4.0 and above<br>
 * VERSION-VC : 4.1 <br>
 * NOTE : Related bug 524321 <br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS.<br>
 * 2. Set permissions on DVS to a user without "DVSwitch.Modify" privilege<br>
 * 3. Logout administrator and login with dvsuser<br>
 * TEST:<br>
 * 4. Reconfigure the DVS to set a different name.<br>
 * 5. Expect that NoPermission is thrown with entity as DVS and privilege as
 * "DVSwitch.Modify"<br>
 * 6. <br>
 * CLEANUP:<br>
 * 7. Logout dvsuser and login as Administrator.<br>
 * 8. Remove the create roles.<br>
 * 9. Destroy the DVS.<br>
 */
public class Sec001 extends CreateDVSTestBase
{
   private DVSConfigSpec deltaConfigSpec = null;
   private int roleId;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = DVSWITCH_MODIFY;
   private AuthorizationManager authentication = null;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVS to set a different name by "
               + "user not having \"DVSwitch.Modify\"" + "privilege.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      authentication = new AuthorizationManager(connectAnchor);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      configSpec = new DVSConfigSpec();
      configSpec.setName(getTestId());
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, "Failed to create DVS");
      log.info("Successfully created the DVSwitch");
      deltaConfigSpec = new DVSConfigSpec();
      deltaConfigSpec.setName(getTestId() + "-newName");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMOR, privilege, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Reconfigure DVS to set a different name by "
               + "user not having \"DVSwitch.Modify\"" + "privilege.")
   public void test()
      throws Exception
   {
      try {
         iDistributedVirtualSwitch.reconfigure(dvsMOR, deltaConfigSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvsMOR);
         expectedMethodFault.setPrivilegeId(DVSWITCH_MODIFY);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
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

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dvsMOR);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}