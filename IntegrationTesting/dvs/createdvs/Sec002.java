/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_CREATE;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;

import dvs.CreateDVSTestBase;

public class Sec002 extends CreateDVSTestBase
{
   private int roleId;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = DVSWITCH_CREATE;
   private AuthorizationManager authentication = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder by a"
               + " user not having  DVSwitch.create privilege. The DVS parameters are to"
               + " be set as follows:\n"
               + " - DVSConfigSpec.configVersion set to an empty string,\n"
               + " - DVSConfigSpec.name set to 'Create  DVS-Sec002'.");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      authentication = new AuthorizationManager(super.getConnectAnchor());
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      configSpec = new VMwareDVSConfigSpec();
      configSpec.setConfigVersion("");
      configSpec.setName(getTestId());
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));

      authHelper.setPermissions(dcMor, privilege, testUser, true);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Create a DVSwitch inside a valid folder by a"
               + " user not having  DVSwitch.create privilege. The DVS parameters are to"
               + " be set as follows:\n"
               + " - DVSConfigSpec.configVersion set to an empty string,\n"
               + " - DVSConfigSpec.name set to 'Create  DVS-Sec002'.")
   public void test()
      throws Exception
   {
      try {
         dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
                  configSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dcMor);
         expectedMethodFault.setPrivilegeId(DVSWITCH_CREATE);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
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
      expectedFault.setObject(dcMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}