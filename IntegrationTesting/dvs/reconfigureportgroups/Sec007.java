/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_PASS;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVPORTGROUP_MODIFY;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
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
 * DESCRIPTION:Reconfigure a port-group to an existing distributed virtual
 * switch as a user having DVPortgroup.Modify privilege at root folder with
 * propagate as true.<br>
 * PRODUCT: VC<br>
 * VERSION-ESX : 4.0 and above<br>
 * VERSION-EESX: 4.0 and above<br>
 * VERSION-VC : 4.0 and above <br>
 * SETUP:<br>
 * 1. Create a DVS switch. <br>
 * 2. Add a port-group to DVS.<br>
 * 3. Set required DVPortgroup.Modify privilege to the test user. Logout
 * administrator and login as test user.<br>
 * TEST:<br>
 * 4. Reconfigure the port-group.<br>
 * CLEANUP:<br>
 * 5. Logout test user, remove roles and login as administrator<br>
 * 6. Remove port-groups and DVS created in test.<br>
 */
public class Sec007 extends TestBase
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
   private AuthorizationManager authentication = null;

   public void setTestDescription()
   {
      setTestDescription("Reconfigure a port-group to an existing distributed"
               + " virtual switch as a user having DVPortgroup.Modify privilege "
               + "with propagate as true.");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      log.info("Test setup Begin:");
      this.iFolder = new Folder(connectAnchor);
      this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.rootFolderMor = this.iFolder.getRootFolder();
      this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      this.dvsConfigSpec = new DVSConfigSpec();
      this.dvsConfigSpec.setConfigVersion("");
      authentication = new AuthorizationManager(connectAnchor);
      this.dvsConfigSpec.setName(this.getClass().getName());
      /*
       * Create a DVS.
       */
      dvsMor = this.iFolder.createDistributedVirtualSwitch(
               this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, "Successfully created the distributed "
               + "virtual switch", "Failed to create the distributed "
               + "virtual switch");
      log.info("Successfully created the distributed "
               + "virtual switch");
      /*
       * Add a port-group to DVS.
       */
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setConfigVersion("");
      this.dvPortgroupConfigSpec.setName(this.getTestId());
      this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      this.dvPortgroupConfigSpec.setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
      dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
      assertTrue(dvPortgroupMorList != null && dvPortgroupMorList.size() == 1,
               "Successfully added the portgroup",
               "Failed to add the portgroup");
      /*
       * Edit the port-group spec to reconfigure in test.
       */
      this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
               dvPortgroupMorList.get(0)).getConfigVersion());
      this.dvPortgroupConfigSpec.setName(this.getTestId() + "-pg1");
      /*
       * Set required DVPortgroup.Modify privilege to the test user. Logout
       * administrator and login as test user.
       */
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), false,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      assertTrue(authHelper.setPermissions(rootFolderMor, DVPORTGROUP_MODIFY,
               GENERIC_USER, true),
               "Successful in setting the permissions on root folder.",
               "Unable to set permissions on root folder.");
      assertTrue(authHelper.performSecurityTestsSetup(GENERIC_USER),
               "Successfully logged in as test user.",
               "Unable to perform AuthHelper security setup.");
      return true;
   }

   @Test(description = "Reconfigure a port-group to an existing distributed"
               + " virtual switch as a user having DVPortgroup.Modify privilege "
               + "with propagate as true.")
   public void test()
      throws Exception
   {
      assertTrue(this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
               this.dvPortgroupConfigSpec),
               "Successfully reconfigured the portgroup",
               "Failed to reconfigure the portgroup");
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (authHelper.performSecurityTestsCleanup()) {
         log.info("Successfully removed roles and logged out test user.");
      } else {
         log.error("Unable to perform AuthHelper security cleanup.");
         status = false;
      }
      if (this.dvPortgroupMorList != null) {
         for (ManagedObjectReference mor : dvPortgroupMorList) {
            status &= this.iManagedEntity.destroy(mor);
         }
      }
      if (this.dvsMor != null) {
         status &= this.iManagedEntity.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
