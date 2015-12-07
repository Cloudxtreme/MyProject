/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.TestConstants.PASSWORD;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.Permission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;

/**
 * Move a DVPort by a user having PrivilegeConstants.DVSWITCH_MODIFY privilege
 * on DVS.
 */
public class Sec001 extends MovePortBase
{
   private int roleId;
   private String tempUser = GENERIC_USER;
   private String tempPassword = PASSWORD;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort by user having \"DVSwitch.Modify\" "
               + "privilege.");
   }

   /**
    * Test setup. 1. Create a DVS. 2. Create a standalone DVPort and use it as
    * port to be moved. 3. Create early binding DVPortgroup and use it's key as
    * destination. 4. Create a role with PrivilegeConstants.DVSWITCH_MODIFY
    * privilege.
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;

         if (super.testSetUp()) {
            //
            //
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName);
            if (dvsMor != null) {
               log.info("DVS created: " + iDVSwitch.getName(dvsMor));
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if ((portKeys != null) && (portKeys.size() > 0)) {
                  log.info("Successfully created a standalone DVPort.");
                  portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                           DVPORTGROUP_TYPE_EARLY_BINDING, 1, prefix + "PG");
                  if (portgroupKey != null) {
                     log.info("Successfully created early binding DVPortgroup.");
                     if (addRole()) {
                        if (SessionManager.logout(connectAnchor)) {
                           log.info("Successfully logged out "
                                    + data.getString(TestConstants.TESTINPUT_USERNAME));
                           if (SessionManager.login(connectAnchor, tempUser,
                                    tempPassword) != null) {
                              log.info("Successfully logged in with user "
                                       + tempUser);
                              status = true;
                           } else {
                              log.error("Failed to login with test user.");
                           }
                        } else {
                           log.error("Faied to logout.");
                        }
                     }
                  } else {
                     log.error("Failed to create early binding DVPortgroup.");
                  }
               } else {
                  log.error("Failed to create the standalone DVPort.");
               }
            }
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move the standalone DVPort to the early binding DVPortgroup.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a DVPort by user having \"DVSwitch.Modify\" "
               + "privilege.")
   public void test()
      throws Exception
   {
      boolean status = false;

         status = movePort(dvsMor, portKeys, portgroupKey);

      assertTrue(status, "Test Failed");
   }

   /**
    * Test cleanup.
    *
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         if (SessionManager.logout(connectAnchor)) {
            if (SessionManager.login(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD)) != null) {
               log.info("Successfully logged in user: "
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
               authentication = new AuthorizationManager(connectAnchor);
               authManagerMor = authentication.getAuthorizationManager();
               if (authentication.roleExists(authManagerMor, roleId)) {
                  status = authentication.removeAuthorizationRole(
                           authManagerMor, roleId, false);
               }
            } else {
               log.error("Failed to login user:"
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
            }
         } else {
            log.error("Failed to logout user: " + tempUser);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
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
      final String[] privileges = { PrivilegeConstants.DVSWITCH_MODIFY };
      final String roleName = prefix + "Role";
      try {
         authentication = new AuthorizationManager(connectAnchor);
         authManagerMor = this.authentication.getAuthorizationManager();

         roleId = authentication.addAuthorizationRole(authManagerMor, roleName,
                  privileges);
         if (authentication.roleExists(authManagerMor, roleId)) {
            log.info("Successfully added the Role : " + roleName
                     + "with privileges: " + privileges);
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(tempUser);
            permissionSpec.setPropagate(false);
            permissionSpec.setRoleId(roleId);
            final Permission[] permissionsArr = { permissionSpec };
            if (authentication.setEntityPermissions(authManagerMor, dvsMor,
                     permissionsArr)) {
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

   public boolean isAutoLoginLogout()
   {
      return true;
   }
}
