/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

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
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Reconfigure a portgroup to an existing distributed virtual switch as a user
 * not having DVPortgroup.PolicyOp privilege
 */
public class Sec006 extends TestBase
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
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private ManagedObjectReference hostMor = null;
   private HostSystem iHostSystem = null;
   private AuthorizationManager authentication = null;
   private ManagedObjectReference authManagerMor = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Reconfigure a portgroup on an existing"
               + "distributed virtual switch as a user not having "
               + "DVPortgroup.PolicyOp privilege");
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
               DVSTestConstants.DVPORTGROUP_CREATE_PRIVILEGE,
               DVSTestConstants.DVPORTGROUP_MODIFY_PRIVILEGE };
      final String roleName = getTestId() + "Role";
      try {
         authentication = new AuthorizationManager(connectAnchor);
         authManagerMor = authentication.getAuthorizationManager();
         roleId = authentication.addAuthorizationRole(authManagerMor, roleName,
                  privileges);
         if (authentication.roleExists(authManagerMor, roleId)) {
            log.info("Successfully added the Role : " + roleName
                     + "with privileges: " + privileges);
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
            permissionSpec.setPropagate(true);
            permissionSpec.setRoleId(roleId);
            final Permission[] permissionsArr = { permissionSpec };
            if (authentication.setEntityPermissions(authManagerMor,
                     iFolder.getDataCenter(), permissionsArr)) {
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
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");
      try {

         iFolder = new Folder(connectAnchor);
         iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         iManagedEntity = new ManagedEntity(connectAnchor);
         iHostSystem = new HostSystem(connectAnchor);
         rootFolderMor = iFolder.getRootFolder();
         iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         dcMor = iFolder.getDataCenter();
         if (dcMor != null) {
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setConfigVersion("");
            dvsConfigSpec.setName(this.getClass().getName());
            if (addRole()) {
               if (SessionManager.logout(connectAnchor)) {
                  log.info("Successfully logged out ");
                  loginSession = SessionManager.login(connectAnchor,
                           TestConstants.GENERIC_USER, TestConstants.PASSWORD);
                  if (loginSession != null) {
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
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that reconfigures a portgroup to the distributed virtual switch as
    * a user not having DVPortgroup.Scope privilege
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Reconfigure a portgroup on an existing"
               + "distributed virtual switch as a user not having "
               + "DVPortgroup.PolicyOp privilege")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      DVPortgroupPolicy policy = null;
      try {
         dvsMor = iFolder.createDistributedVirtualSwitch(
                  iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
         if (dvsMor != null) {
            log.info("Successfully created the distributed "
                     + "virtual switch");
            dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            dvPortgroupConfigSpec.setConfigVersion("");
            dvPortgroupConfigSpec.setName(getTestId());
            dvPortgroupConfigSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
            dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING);
            dvPortgroupConfigSpec.setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
            dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                     new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec });
            if (dvPortgroupMorList != null && dvPortgroupMorList.size() == 1) {
               log.info("Successfully added the portgroup");
               policy = new DVPortgroupPolicy();
               dvPortgroupConfigSpec.setConfigVersion(iDVPortgroup.getConfigInfo(
                        dvPortgroupMorList.get(0)).getConfigVersion());
               dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
               dvPortgroupConfigSpec.setPolicy(policy);
               if (iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                        dvPortgroupConfigSpec)) {
                  log.info("Successfully reconfigured the portgroup");
               } else {
                  log.error("Failed to reconfigure the portgroup");
               }
            } else {
               log.error("Failed to add the portgroup");
            }
         } else {
            log.error("Failed to create the distributed "
                     + "virtual switch");
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvPortgroupMorList.get(0));
         expectedMethodFault.setPrivilegeId(PrivilegeConstants.DVPORTGROUP_POLICYOP);
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (SessionManager.logout(connectAnchor)) {
            loginSession = SessionManager.login(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD));
            if (loginSession != null) {
               log.info("Successfully logged in user ");
               if (authentication.roleExists(authManagerMor, roleId)) {
                  status = authentication.removeAuthorizationRole(
                           authManagerMor, roleId, false);
               }
            } else {
               log.error("Failed to login user:");
            }
         } else {
            log.error("Failed to logout user: " + TestConstants.GENERIC_USER);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            if (dvsMor != null) {
               status &= iManagedEntity.destroy(dvsMor);
            }
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
