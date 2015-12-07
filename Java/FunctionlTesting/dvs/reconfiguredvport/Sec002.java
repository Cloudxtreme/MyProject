/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.Permission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Sec002 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;
   private int roleId = 0;
   private final String RECONFIGUREPORT_PRIVID = PrivilegeConstants.DVSWITCH_PORTCONFIG;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort by DVS user with required "
               + "Priveleges");
   }

   /**
    * Method to setup the environment for the test.
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

         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDVS = new DistributedVirtualSwitch(connectAnchor);
               configSpec = new DVSConfigSpec();
               configSpec.setName(this.getClass().getName());
               configSpec.setNumStandalonePorts(DVS_PORT_NUM);

               dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
                  if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                     portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
                     portConfigSpecs[0] = new DVPortConfigSpec();
                     portConfigSpecs[0].setKey(portKeyList.get(0));
                     portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
                     if (this.addRole(dvsMOR)) {
                        if (SessionManager.logout(connectAnchor)) {
                           log.info("Successfully logged out "
                                    + data.getString(TestConstants.TESTINPUT_USERNAME));
                           this.loginSession = SessionManager.login(
                                    connectAnchor, TestConstants.GENERIC_USER,
                                    TestConstants.PASSWORD);
                           if (this.loginSession != null) {
                              log.info("Successfully logged in with user dvsUser");
                              status = true;
                           } else {
                              log.error("Failed to login with test user.");
                           }
                        } else {
                           log.error("Faied to logout.");
                        }
                     }
                     status = true;
                  } else {
                     log.error("Can't get correct port keys");
                  }
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         }

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @return true if successful.
    */
   private boolean addRole(ManagedObjectReference entityMor)
   {
      boolean result = false;
      final String[] privIds = { RECONFIGUREPORT_PRIVID };
      final String roleName = getTestId();
      try {
         authentication = new AuthorizationManager(connectAnchor);
         authManagerMor = authentication.getAuthorizationManager();
         this.roleId = this.authentication.addAuthorizationRole(authManagerMor,
                  roleName, privIds);
         if (this.authentication.roleExists(this.authManagerMor, this.roleId)) {
            log.info("Successfully added the Role : " + roleName
                     + "with privileges: " + privIds);
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
            permissionSpec.setPropagate(false);
            permissionSpec.setRoleId(this.roleId);
            final Permission[] permissionsArr = { permissionSpec };
            if (this.authentication.setEntityPermissions(this.authManagerMor,
                     entityMor, permissionsArr)) {
               log.info("Successfully set entity permissions for "
                        + this.iDVS.getName(entityMor));
               result = true;
            } else {
               log.error("Failed to set entity permissions for "
                        + this.iDVS.getName(entityMor));
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
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure DVPort by DVS user with required "
               + "Priveleges")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         status = this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs);
         assertTrue(status, "Test Failed");

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
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
               status &= super.testCleanUp();
            } else {
               log.error("Failed to login user:"
                        + data.getString(TestConstants.TESTINPUT_USERNAME));
            }
         } else {
            log.error("Failed to logout user: " + TestConstants.GENERIC_USER);
         }
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
