/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_PASS;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVPORTGROUP_POLICYOP;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * DESCRIPTION:Reconfigure a portgroup to an existing distributed virtual switch
 * as a user not having DVPortgroup.PolicyOp privilege at root level with
 * propagate as true.<br>
 * PRODUCT: VC<br>
 * VERSION-ESX : 4.0 and above<br>
 * VERSION-EESX: 4.0 and above<br>
 * VERSION-VC : 4.0 and above <br>
 * SETUP:<br>
 * 1. Create a DVS switch. <br>
 * 2. Add a port-group to DVS.<br>
 * 3. Set all privileges except DVPortgroup.PolicyOp to the test user. Logout
 * administrator and login as test user.<br>
 * TEST:<br>
 * 4. Reconfigure the port-group with policy value being set.<br>
 * CLEANUP:<br>
 * 5. Logout test user, remove roles and login as administrator<br>
 * 6. Remove port-groups and DVS created in test setup.<br>
 */

public class Sec012 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private ManagedObjectReference dcMor = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private AuthorizationHelper authHelper;
   private AuthorizationManager authentication;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a portgroup to an existing distributed"
               + " virtual switch as a user not having DVPortgroup.PolicyOp"
               + " privilege at root level with propagate as true.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      log.info("Test setup Begin:");
      this.authentication = new AuthorizationManager(connectAnchor);
      this.iFolder = new Folder(connectAnchor);
      ;
      this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.rootFolderMor = this.iFolder.getRootFolder();
      this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      /*
       * Add a DVS.
       */
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(this.getClass().getName());
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, "Failed to create DVS");
      log.info("Successfully created the distributed "
               + "virtual switch");
      /*
       * Add a portgroup to DVS.
       */
      dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      dvPortgroupConfigSpec.setConfigVersion("");
      dvPortgroupConfigSpec.setName(getTestId());
      dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvPortgroupConfigSpec.setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
      dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
      assertNotEmpty(dvPortgroupMorList, "Failed to add DVPortGroup");
      log.info("Successfully added the portgroup");
      /*
       * Edit the portgroup spec with policy value being set.
       */
      DVPortgroupPolicy policy = new DVPortgroupPolicy();
      dvPortgroupConfigSpec.setConfigVersion(iDVPortgroup.getConfigInfo(
               dvPortgroupMorList.get(0)).getConfigVersion());
      dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
      dvPortgroupConfigSpec.setPolicy(policy);
      /*
       * Set all privileges except DVPortgroup.PolicyOp privilege on root folder.
       */
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      assertTrue(authHelper.setPermissions(rootFolderMor, DVPORTGROUP_POLICYOP,
               GENERIC_USER, true),
               "Successful in setting the permissions on root folder.",
               "Unable to set permissions on root folder.");
      /*
       * Add roles, logout administrator and login as test user.
       */
      return authHelper.performSecurityTestsSetup(GENERIC_USER);
   }

   @Override
   @Test(description = "Reconfigure a portgroup to an existing distributed"
               + " virtual switch as a user not having DVPortgroup.PolicyOp"
               + " privilege at root level with propagate as true.")
   public void test()
      throws Exception
   {
      try {
         iDVPortgroup.reconfigure(dvPortgroupMorList.get(0), dvPortgroupConfigSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvPortgroupMorList.get(0));
         expectedMethodFault.setPrivilegeId(DVPORTGROUP_POLICYOP);
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
      if (dvPortgroupMorList != null) {
         for (ManagedObjectReference mor : dvPortgroupMorList) {
            status &= iManagedEntity.destroy(mor);
         }
      }
      if (dvsMor != null) {
         status &= iManagedEntity.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dvPortgroupMorList.get(0));
      expectedFault.setPrivilegeId(DVPORTGROUP_POLICYOP);
      return expectedFault;
   }
}
