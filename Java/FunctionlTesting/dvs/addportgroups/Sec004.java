/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DVS_CREATE_PASS;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVPORTGROUP_DELETE;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;

/**
 * DESCRIPTION:<br>
 * Destroy a DVPortGroup by user NOT having 'DVPortgroup.Delete' privilege on
 * it.<br>
 * SETUP:<br>
 * 1. Create a DVSwitch, and get the uplink DVPortGroup.<br>
 * 2. Set all privileges EXCEPT 'DVPortgroup.Delete' on DVPortGroup.<br>
 * 3. Logout Administrator and login as test user.<br>
 * TEST:<br>
 * 4. Destroy DVPortGroup should throw NoPermission with privilegeId as
 * 'DVPortgroup.Delete' on DVPortGroup entity.<br>
 * CLEANUP:<br>
 * 5. Logout test user and login as Administrator.<br>
 * 6. Destroy the DVS.<br>
 */
public class Sec004 extends TestBase
{
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference dvPgMor;
   private DistributedVirtualSwitch iDVSwitch;
   private AuthorizationHelper authHelper;
   private String testUser = GENERIC_USER;
   private String privilege = DVPORTGROUP_DELETE;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Destroy a DVPortGroup by a user NOT having "
               + "'DVPortgroup.Delete' privilege on it.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      final Folder iFolder = new Folder(connectAnchor);
      final ManagedObjectReference dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      final DVSConfigSpec dvsCfg = new DVSConfigSpec();
      dvsCfg.setConfigVersion("");
      dvsCfg.setName(getTestId());
      log.info("Creating vDS: " + dvsCfg.getName());
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsCfg);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      List<ManagedObjectReference> dvPgMors = iDVSwitch.getUplinkPortgroups(dvsMor);
      assertNotEmpty(dvPgMors, "Failed to get uplink DVPortGroup");
      dvPgMor = dvPgMors.get(0);
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvPgMor, privilege, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Destroy a DVPortGroup by a user NOT having "
               + "'DVPortgroup.Delete' privilege on it.")
   public void test()
      throws Exception
   {
      try {
         iDVSwitch.destroy(dvPgMor);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvPgMor);
         expectedMethodFault.setPrivilegeId(privilege);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dvPgMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }

   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanedUp = true;
      if (authHelper != null) {
         cleanedUp &= authHelper.performSecurityTestsCleanup();
      }
      if (dvsMor != null) {
         cleanedUp &= iDVSwitch.destroy(dvsMor);
      }
      return cleanedUp;
   }
}
