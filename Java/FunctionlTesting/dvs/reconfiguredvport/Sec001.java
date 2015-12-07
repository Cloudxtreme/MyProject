/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;

import dvs.CreateDVSTestBase;

/**
 * DESCRIPTION:<br>
 * Reconfigure DVPort by a user having only "DVSwitch.PortConfig" privilege. <br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS with a standalone DVPort.<br>
 * 2. Create port config spec to change the name & description.<br>
 * 3. Set the "DVSwitch.PortConfig" privilege on DVS for test user.<br>
 * 4. Logout test user and login as administrator.<br>
 * TEST:<br>
 * 5. Reconfigure DVPort operation should be successful <br>
 * CLEANUP:<br>
 * 6. Logout test user and login as administrator.<br>
 * 7. Remove the create role.<br>
 * 8. Delete the DVS<br>
 */
public class Sec001 extends CreateDVSTestBase
{
   private DistributedVirtualSwitch iDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private static final int DVS_PORT_NUM = 1;
   private AuthorizationHelper authHelper;
   private String testUser = TestConstants.VMPROVIDER_USER;
   private String privilegeId = PrivilegeConstants.DVSWITCH_PORTCONFIG;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort by DVS user with required "
               + "Priveleges");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      iDVS = new DistributedVirtualSwitch(connectAnchor);
      configSpec = new DVSConfigSpec();
      configSpec.setName(this.getClass().getName());
      configSpec.setNumStandalonePorts(DVS_PORT_NUM);
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
      assertNotEmpty(portKeyList, "Failed to get standalone DVPorts");
      portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
      portConfigSpecs[0] = new DVPortConfigSpec();
      portConfigSpecs[0].setKey(portKeyList.get(0));
      portConfigSpecs[0].setName(getTestId());
      portConfigSpecs[0].setDescription(getTestId());
      portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(),
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMOR, privilegeId, testUser, true);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Reconfigure DVPort by DVS user with required "
               + "Priveleges")
   public void test()
      throws Exception
   {
      assertTrue(iDVS.reconfigurePort(dvsMOR, portConfigSpecs), "Test Failed");
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (authHelper != null) {
            status &= authHelper.performSecurityTestsCleanup();
         }
         status &= super.testCleanUp();
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         status &= SessionManager.logout(connectAnchor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
