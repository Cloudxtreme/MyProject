/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_DELETE;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.Permission;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * Reconfigure a portgroup to an existing distributed virtual switch as a user
 * not having DVPortgroup.Scope privilege
 */
public class Sec004 extends TestBase
{
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
   private final String testUser = TestConstants.GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = PrivilegeConstants.DVPORTGROUP_SCOPEOP;
   private AuthorizationManager authentication = null;

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
               + "DVPortgroup.Scope privilege");
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @return true if successful.
    */
   private boolean addRole()
   {
      boolean result = false;
      authentication = new AuthorizationManager(connectAnchor);
      ManagedObjectReference authManagerMor = authentication.getAuthorizationManager();
      final String[] privileges = { DVSTestConstants.DVSWITCH_CREATE_PRIVILEGE,
               DVSTestConstants.DVPORTGROUP_CREATE_PRIVILEGE,
               DVSTestConstants.DVPORTGROUP_MODIFY_PRIVILEGE };
      final String roleName = getTestId() + "Role";
      try {
         roleId = authentication.addAuthorizationRole(authManagerMor, roleName,
                  privileges);
         if (authentication.roleExists(authManagerMor, roleId)) {
            log.info("Successfully added the Role : " + roleName
                     + "with privileges: " + privileges);
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
            permissionSpec.setPropagate(false);
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
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      rootFolderMor = iFolder.getRootFolder();
      iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      dcMor = iFolder.getDataCenter();
      hostMor = iHostSystem.getAllHost().get(0);
      assertNotNull(dcMor, "failed to get Datacenter");
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(this.getClass().getName());
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, "Failed to create DVS");
      log.info("Successfully created the distributed "
               + "virtual switch");
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
      dvPortgroupConfigSpec.setConfigVersion(iDVPortgroup.getConfigInfo(
               dvPortgroupMorList.get(0)).getConfigVersion());
      dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
      dvPortgroupConfigSpec.getScope().clear();
      dvPortgroupConfigSpec.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { hostMor }));
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));

      authHelper.setPermissions(dvPortgroupMorList.get(0), privilege, testUser,
               false);
      return authHelper.performSecurityTestsSetup(testUser);
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
               + "DVPortgroup.Scope privilege")
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
         expectedMethodFault.setPrivilegeId(PrivilegeConstants.
        		 DVPORTGROUP_SCOPEOP);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
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
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dvPortgroupMorList.get(0));
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}
