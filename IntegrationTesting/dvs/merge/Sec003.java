/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_DELETE;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_MODIFY;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * Create two dvswitches with the default configuration. Merge the switches with
 * a user having no PrivilegeConstants.DVSWITCH_MODIFY privilege on the first
 * dvswitch and PrivilegeConstants.DVSWITCH_DELETE privilege on the second
 * dvswitch.
 */
public class Sec003 extends TestBase
{
   private int roleId;
   private String tempPassword = TestConstants.PASSWORD;
   private UserSession loginSession = null;
   private ManagedObjectReference srcDvsMor = null;
   private ManagedObjectReference destDvsMor = null;
   private Folder iFolder = null;
   private DistributedVirtualSwitchHelper iDVS = null;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = DVSWITCH_MODIFY;
   private AuthorizationManager authentication = null;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Create two dvswitches with the default configuration. "
               + "Merge the switches with a user having no"
               + "DVSwitch.Modify privilege on the first dvswitch and"
               + " DVSwitch.Delete privilege on the second dvswitch.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      iFolder = new Folder(super.getConnectAnchor());
      iDVS = new DistributedVirtualSwitchHelper(super.getConnectAnchor());
      authentication = new AuthorizationManager(super.getConnectAnchor());
      srcDvsMor = iFolder.createDistributedVirtualSwitch(getTestId() + "_SRC");
      assertNotNull(srcDvsMor, "Failed to create source DVS");
      destDvsMor = iFolder.createDistributedVirtualSwitch(getTestId() + "_DEST");
      assertNotNull(destDvsMor, "Failed to create destination DVS");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));

      // Setting required permissions on DC to delete the source DVS.
      authHelper.setPermissions(iFolder.getDataCenter(), DVSWITCH_DELETE,
               testUser, true);
      // set exclude privileges on destination DVS.
      authHelper.setExcludePrivileges(true);
      authHelper.setPermissions(destDvsMor, privilege, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Create two dvswitches with the default configuration. "
               + "Merge the switches with a user having no"
               + "DVSwitch.Modify privilege on the first dvswitch and"
               + " DVSwitch.Delete privilege on the second dvswitch.")
   public void test()
      throws Exception
   {
      
try {
         iDVS.merge(destDvsMor, srcDvsMor);// merge => delete src & modify dest
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(srcDvsMor);
         expectedMethodFault.setPrivilegeId(DVSWITCH_DELETE);
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
      if (srcDvsMor != null && iDVS.isExists(srcDvsMor)) {
         status &= iDVS.destroy(srcDvsMor);
      }
      if (destDvsMor != null) {
         status &= iDVS.destroy(destDvsMor);
      }
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(destDvsMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}
