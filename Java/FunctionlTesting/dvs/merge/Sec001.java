/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.merge;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;

/**
 * Create two dvswitches with the default configuration. Merge the switches with
 * a user having PrivilegeConstants.DVSWITCH_MODIFY privilege on the first
 * dvswitch and PrivilegeConstants.DVSWITCH_DELETE privilege on the second
 * dvswitch.
 */
public class Sec001 extends TestBase
{
   private int modifyRoleId;
   private int deleteroleId;
   private String tempUser = GENERIC_USER;
   private String tempPassword = TestConstants.PASSWORD;
   private UserSession loginSession = null;
   private ManagedObjectReference srcDvsMor = null;
   private ManagedObjectReference destDvsMor = null;
   private Folder iFolder = null;
   private DistributedVirtualSwitch iDVS = null;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Create two dvswitches with the default configuration. "
               + "Merge the switches with a user having "
               + "DVSwitch.Modify privilege on the first dvswitch and"
               + " DVSwitch.Delete privilege on the second dvswitch.");
   }

   /**
    * Test setup. 1. Create a DVS.
    *
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if setup is successful.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;

         this.loginSession = SessionManager.login(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         if (this.loginSession != null) {
            this.iFolder = new Folder(connectAnchor);
            this.iDVS = new DistributedVirtualSwitch(connectAnchor);
            this.srcDvsMor = iFolder.createDistributedVirtualSwitch(this.getTestId()
                     + "_SRC");
            if (srcDvsMor != null) {
               this.destDvsMor = iFolder.createDistributedVirtualSwitch(this.getTestId()
                        + "_DEST");
               if (this.destDvsMor != null) {
                  if (addRole()) {
                     if (SessionManager.logout(connectAnchor)) {
                        log.info("Successfully logged out "
                                 + data.getString(TestConstants.TESTINPUT_USERNAME));
                        loginSession = SessionManager.login(connectAnchor,
                                 tempUser, tempPassword);
                        if (loginSession != null) {
                           log.info("Successfully logged in with user "
                                    + tempUser);
                           status = true;
                        } else {
                           log.error("Failed to login with test user.");
                        }
                     } else {
                        log.error("Faied to logout.");
                     }
                  } else {
                     log.error("Can not add the role with the desired "
                              + "privileges");
                  }
               } else {
                  log.error("Can not create the destination dv switch");
               }
            } else {
               log.error("Can not create the source dv switch");
            }
         } else {
            log.error("Can not login into VC");
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Create two dvswitches with the default configuration. "
               + "Merge the switches with a user having "
               + "DVSwitch.Modify privilege on the first dvswitch and"
               + " DVSwitch.Delete privilege on the second dvswitch.")
   public void test()
      throws Exception
   {
      boolean status = false;

         if (this.iDVS.merge(this.destDvsMor, this.srcDvsMor)) {
            log.info("Successfully merged the source and destination DVS");
            status = true;
         } else {
            log.error("Can not merge the source and destination DVS");
         }

      assertTrue(status, "Test Failed");
   }

   /**
    * Test cleanup.
    *
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

         if (SessionManager.logout(connectAnchor)) {
            loginSession = SessionManager.login(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD));
            if (loginSession != null) {
               log.info("Successfully logged in user: "
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
               this.authentication = new AuthorizationManager(connectAnchor);
               this.authManagerMor = this.authentication.getAuthorizationManager();
               if (authentication.roleExists(authManagerMor, deleteroleId)) {
                  status &= authentication.removeAuthorizationRole(
                           authManagerMor, deleteroleId, false);
               }
               if (authentication.roleExists(authManagerMor, modifyRoleId)) {
                  status &= authentication.removeAuthorizationRole(
                           authManagerMor, modifyRoleId, false);
               }
               if (this.srcDvsMor != null && this.iDVS.isExists(this.srcDvsMor)) {
                  status &= this.iDVS.destroy(this.srcDvsMor);
               }
               if (this.destDvsMor != null) {
                  status &= this.iDVS.destroy(this.destDvsMor);
               }
            } else {
               log.error("Failed to login user:"
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
            }
         } else {
            log.error("Failed to logout user: " + tempUser);
         }

      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @return true if successful.
    */
   private boolean addRole()
   {
      boolean result = false;
      final String[] modifyPrivileges = { PrivilegeConstants.DVSWITCH_MODIFY };
      final String[] deletePrivileges = { PrivilegeConstants.DVSWITCH_DELETE };
      final String modifyRoleName = this.getTestId() + "DVS-Modify-Role";
      final String deleteRoleName = this.getTestId() + "DVS-Delete-Role";
      try {
         this.authentication  = new AuthorizationManager(connectAnchor);
         authManagerMor =  this.authentication.getAuthorizationManager();

         modifyRoleId = authentication.addAuthorizationRole(authManagerMor,
                  modifyRoleName, modifyPrivileges);
         if (authentication.roleExists(authManagerMor, modifyRoleId)) {
            log.info("Successfully added the Role : " + modifyRoleName
                     + "with privileges: " + modifyPrivileges);
            deleteroleId = authentication.addAuthorizationRole(authManagerMor,
                     deleteRoleName, deletePrivileges);
            if (authentication.roleExists(authManagerMor, deleteroleId)) {
               log.info("Successfully added the Role : "
                        + deleteRoleName + "with privileges: "
                        + deletePrivileges);
               Permission permissionSpec = new Permission();
               permissionSpec.setGroup(false);
               permissionSpec.setPrincipal(tempUser);
               permissionSpec.setPropagate(false);
               permissionSpec.setRoleId(modifyRoleId);
               Permission[] permissionsArr = new Permission[2];
               permissionsArr[0] = permissionSpec;
               permissionSpec = new Permission();
               permissionSpec.setGroup(false);
               permissionSpec.setPrincipal(tempUser);
               permissionSpec.setPropagate(true);
               permissionSpec.setRoleId(deleteroleId);
               permissionsArr[1] = permissionSpec;
               if (this.authentication.setEntityPermissions(
                        this.authManagerMor, this.destDvsMor,
                        new Permission[] { permissionsArr[0] })
                        && this.authentication.setEntityPermissions(
                                 this.authManagerMor,
                                 this.iFolder.getDataCenter(),
                                 new Permission[] { permissionsArr[1] })) {
                  log.info("Successfully set entity permissions.");
                  result = true;
               } else {
                  log.error("Failed to set entity permissions.");
               }
            }
         } else {
            log.error("Failed to add the role.");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return result;
   }

}
