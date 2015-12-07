/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.PrivilegeConstants.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;

/**
 * Move a DVPort by a user not having PrivilegeConstants.DVSWITCH_MODIFY
 * privilege on DVS.
 */
public class Sec002 extends MovePortBase
{
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = DVSWITCH_MODIFY;

   /**
    * Test setup. <br>
    * 1. Create a DVS. <br>
    * 2. Create a standalone DVPort and use it as port to be moved. <br>
    * 3. Create early binding DVPortgroup and use it's key as destination. <br>
    * 4. Use a role with read only privilege.<br>
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
      assertTrue(dvsMor != null, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      log.info("DVS created: {} ", dvsName);
      portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
      assertNotEmpty(portKeys, "Failed to create the standalone DVPort.");
      log.info("Successfully created a standalone DVPort.");
      portgroupKey = iDVSwitch.addPortGroup(dvsMor,
               DVPORTGROUP_TYPE_EARLY_BINDING, 1, prefix + "PG");
      assertNotNull(portgroupKey, "Failed to create early binding DVPortgroup.");
      log.info("Successfully created early binding DVPortgroup.");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, privilege, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Move a DVPort by user not having DVSWITCH_MODIFY "
            + " privilege.")
   public void test()
      throws Exception
   {
      try {
         movePort(dvsMor, portKeys, portgroupKey);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvsMor);
         expectedMethodFault.setPrivilegeId(privilege);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
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
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
