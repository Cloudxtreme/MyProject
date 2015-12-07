/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_PASS;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * Reconfigure a VM to connect to an existing standalone DVPort by an user not
 * having PrivilegeConstants.NETWORK_ASSIGN privilege on Datacenter. <br>
 * <br>
 * TARGET: VC<br>
 * <br>
 * SETUP:<br>
 * 1. Initial setup from super class.<br>
 * 2. Add role and set permission on the VM.<br>
 * 3. Logout Administrator and login with test user.<br>
 * TEST:<br>
 * 4. Try reconfiguring the VM to connect it to the DVPort.<br>
 * 5. Expect "NoPermission" MethodFault.<br>
 * CLEANUP:<br>
 * 6. Logout the test user and login as administrator.<br>
 * 7. Remove the added entity permissions.<br>
 * 8. Do post cleanup from super class.<br>
 */
public class Sec002 extends ReconfigureVMBase
{
   private VirtualMachineConfigSpec[] vmCfgs = null;
   private String testUser = GENERIC_USER;
   private String privilege = PrivilegeConstants.NETWORK_ASSIGN;
   private AuthorizationHelper authHelper;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a VM to connect to an existing "
               + "standalone DVPort by an user not having \"Network.Assign\" "
               + "privilege on Datacenter.");
   }

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      deviceType = VM_VIRTUALDEVICE_ETHERNET_PCNET32;
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      vmCfgs =
               DVSUtil
                        .getVMConfigSpecForDVSPort(
                                 vmMor,
                                 connectAnchor,
                                 new DistributedVirtualSwitchPortConnection[] { dvsPortConnection });
      assertNotEmpty(vmCfgs, "Failed to get reconfig specs");
      assertTrue(vmCfgs[0] != null && vmCfgs[1] != null, "Failed to get Cfgs");
      authHelper =
               new AuthorizationHelper(connectAnchor, getTestId(), data
                        .getString(TestConstants.TESTINPUT_USERNAME), data
                        .getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper
               .setPermissions(
                        new ManagedObjectReference[] { this.vmMor },
                        new String[] {
                                 PrivilegeConstants.VIRTUALMACHINE_INTERACT_DEVICECONNECTION,
                                 PrivilegeConstants.VIRTUALMACHINE_CONFIG_EDITDEVICE },
                        testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Reconfigure a VM to connect to an existing "
               + "standalone DVPort by an user not having \"Network.Assign\" "
               + "privilege on Datacenter.")
   public void test()
      throws Exception
   {
      try {
         ivm.reconfigVM(vmMor, vmCfgs[0]);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = 
        		 com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, getExpectedMethodFault()),
                  "MethodFault mismatch!");
      }
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      if (authHelper != null) {
         status = authHelper.performSecurityTestsCleanup();
      }

      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(this.dvsMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}
