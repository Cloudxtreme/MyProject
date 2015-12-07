/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Add a portgroup to an existing distributed virtual switch as a user having
 * DVPortgroup.Create privilege
 */
public class Sec001 extends TestBase
{
   /*
    * private data variables
    */
   private UserSession loginSession = null;
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dvPortgroupMor = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private int roleId = 0;
   private ManagedObjectReference dcMor = null;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Add a portgroup to an existing"
               + "distributed virtual switch as a user having "
               + "DVPortgroup.Create privilege");
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @return true if successful.
    */
   private boolean addRole()
   {
      boolean result = false;
      final String[] privileges = { DVSTestConstants.DVSWITCH_CREATE_PRIVILEGE,
               DVSTestConstants.DVPORTGROUP_CREATE_PRIVILEGE };
      final String roleName = getTestId() + "Role";
      try {
         authentication = new AuthorizationManager(connectAnchor);
         authManagerMor = this.authentication.getAuthorizationManager();

         this.roleId = authentication.addAuthorizationRole(authManagerMor,
                  roleName, privileges);
         if (authentication.roleExists(authManagerMor, this.roleId)) {
            log.info("Successfully added the Role : " + roleName
                     + "with privileges: " + privileges);
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
            permissionSpec.setPropagate(true);
            permissionSpec.setRoleId(this.roleId);
            final Permission[] permissionsArr = { permissionSpec };
            if (this.authentication.setEntityPermissions(this.authManagerMor,
                     this.iFolder.getDataCenter(), permissionsArr)) {
               log.info("Successfully set entity permissions.");
               result = true;
            } else {
               log.error("Failed to set entity permissions.");
            }
         } else {
            log.error("Failed to add the role.");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return result;
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");
      this.iFolder = new Folder(connectAnchor);
      this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.rootFolderMor = this.iFolder.getRootFolder();
      this.dcMor = this.iFolder.getDataCenter();
      if (this.dcMor != null) {
         this.dvsConfigSpec = new DVSConfigSpec();
         this.dvsConfigSpec.setConfigVersion("");
         this.dvsConfigSpec.setName(this.getClass().getName());
         if (addRole()) {
            if (SessionManager.logout(connectAnchor)) {
               log.info("Successfully logged out "
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
               this.loginSession = SessionManager.login(connectAnchor,
                        TestConstants.GENERIC_USER, TestConstants.PASSWORD);
               if (this.loginSession != null) {
                  log.info("Successfully logged in with user dvsUser");
                  status = true;
               } else {
                  log.error("Failed to login with test user.");
               }
            } else {
               log.error("Failed to logout");
            }
         }
      } else {
         log.error("Failed to find a datacenter");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that adds a portgroup to the distributed virtual switch as a user
    * having DVPortgroup.Create privilege
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Add a portgroup to an existing"
               + "distributed virtual switch as a user having "
               + "DVPortgroup.Create privilege")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         dvsMor = this.iFolder.createDistributedVirtualSwitch(
                  this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         if (dvsMor != null) {
            log.info("Successfully created the distributed "
                     + "virtual switch");
            this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            this.dvPortgroupConfigSpec.setConfigVersion("");
            this.dvPortgroupConfigSpec.setName(this.getTestId());
            this.dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
            this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
            this.dvPortgroupConfigSpec.setNumPorts(1);
            this.dvPortgroupConfigSpec.setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
            dvPortgroupMorList = this.iDVSwitch.addPortGroups(dvsMor,
                     new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
            if (dvPortgroupMorList != null && dvPortgroupMorList.size() == 1) {
               log.info("Successfully added the portgroup");
               status = true;
            } else {
               log.error("Failed to add the portgroup");
            }
         } else {
            log.error("Failed to create the distributed "
                     + "virtual switch");
         }

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (SessionManager.logout(connectAnchor)) {
            this.loginSession = SessionManager.login(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD));
            if (this.loginSession != null) {
               log.info("Successfully logged in user: "
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
               if (this.authentication.roleExists(this.authManagerMor,
                        this.roleId)) {
                  status = this.authentication.removeAuthorizationRole(
                           this.authManagerMor, this.roleId, false);
               }
            } else {
               log.error("Failed to login user:"
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
            }
         } else {
            log.error("Failed to logout user: " + TestConstants.GENERIC_USER);
         }
         if (this.dvPortgroupMorList != null) {
            for (ManagedObjectReference mor : dvPortgroupMorList) {
               status &= this.iManagedEntity.destroy(mor);
            }
         }
         if (this.dvsMor != null) {
            status &= this.iManagedEntity.destroy(dvsMor);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            status &= SessionManager.logout(connectAnchor);
         } catch (Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

}
