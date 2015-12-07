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
import static com.vmware.vcqa.vim.PrivilegeConstants.DVPORTGROUP_SCOPEOP;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

/**
 * DESCRIPTION:Reconfigure a port-group to an existing distributed virtual
 * switch as a user not having DVPortgroup.ScopeOp privilege set at root folder
 * with propagate as true.<br>
 * PRODUCT: VC<br>
 * VERSION-ESX : 4.0 and above VERSION-EESX: 4.0 and above VERSION-VC : 4.0 and
 * above <br>
 * SETUP:<br>
 * 1. Create a DVS switch. <br>
 * 2. Add a port-group to DVS.<br>
 * 3. Set all privileges excluding DVPortgroup.Modify to the test user. Logout
 * administrator and login as test user.<br>
 * TEST:<br>
 * 4. Reconfigure the port-group with scope value being set.<br>
 * CLEANUP:<br>
 * 5. Logout test user, remove roles and login as administrator<br>
 * 6. Remove port-groups and DVS created in test.<br>
 */
public class Sec010 extends TestBase
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
   private ManagedObjectReference hostMor = null;
   private HostSystem iHostSystem = null;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = DVPORTGROUP_SCOPEOP;

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
               + "DVPortgroup.ScopeOp privilege");
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
      this.iFolder = new Folder(connectAnchor);
      this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.rootFolderMor = this.iFolder.getRootFolder();
      this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      iHostSystem = new HostSystem(connectAnchor);
      rootFolderMor = iFolder.getRootFolder();
      dcMor = iFolder.getDataCenter();
      //hostMor = iHostSystem.getAllHost().get(0);
      assertNotNull(dcMor, "failed to get Datacenter");
      this.hostMor = this.iHostSystem.getConnectedHost(null);
      assertNotNull(this.hostMor,"Failed to get a host in the inventory");
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
       * Edit the portgroup spec with scope value being set.
       */
      dvPortgroupConfigSpec.setConfigVersion(iDVPortgroup.getConfigInfo(
               dvPortgroupMorList.get(0)).getConfigVersion());
      dvPortgroupConfigSpec.setName(getTestId() + "-pg1");
      dvPortgroupConfigSpec.getScope().clear();
      dvPortgroupConfigSpec.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { hostMor }));
      /*
       * Set all privileges except DVPortgroup.ScopeOp privilege on root folder.
       */
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));

      assertTrue(authHelper.setPermissions(rootFolderMor, privilege, testUser,
               true), "Successful in setting the permissions on root folder.",
               "Unable to set permissions on root folder.");
      /*
       * Add roles, logout administrator and login as test user.
       */
      return authHelper.performSecurityTestsSetup(testUser);
   }

   /**
    * Method that reconfigures a port-group to the distributed virtual switch as
    * a user not having DVPortgroup.Scope privilege
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Reconfigure a portgroup on an existing"
               + "distributed virtual switch as a user not having "
               + "DVPortgroup.ScopeOp privilege")
   public void test()
      throws Exception
   {
      try {
         iDVPortgroup.reconfigure(dvPortgroupMorList.get(0), dvPortgroupConfigSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault =
        		 com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, getExpectedMethodFault()),
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
      assertTrue(status, "Cleanup failed");
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
