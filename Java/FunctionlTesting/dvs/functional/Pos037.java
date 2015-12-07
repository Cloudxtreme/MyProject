/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.LOGIN_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.LOGIN_PASS;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSSummary;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Test setup: (Hosts must be ESX4x or later) Functional test to validate DVS
 * objects filters based on permissions
 */
public class Pos037 extends TestBase
{
   private UserSession loginSession;
   private DistributedVirtualSwitchHelper iDVS = null;
   private DistributedVirtualPortgroup iDVPG = null;
   private NetworkSystem ins = null;
   private HostSystem ihs = null;
   private VirtualMachine ivm = null;
   private Folder iFolder = null;
   private DVPortgroupConfigSpec pgConfigSpec = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
   private DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference nsMor = null;
   private ManagedObjectReference pgMor = null;
   private ManagedObjectReference datacenterMor = null;
   private final ManagedObjectReference[] nwFolderMors = new ManagedObjectReference[2];
   private final Vector<ManagedObjectReference> entityList = new Vector<ManagedObjectReference>(2);
   private List<ManagedObjectReference> pgList = null;
   private final String dvSwitchName = getTestId() + "-dvs";
   private String pgName = null;
   private String[] pnicIds = null;
   private final String vmName = getTestId() + "-vm";
   private List<String> roleIdList = null;
   private final Map<String, ManagedObjectReference> permissionSpecMap = new HashMap<String, ManagedObjectReference>();
   private DistributedVirtualSwitch iDVSwitch;
   private DistributedVirtualPortgroup iDVPortGroup;
   private final String testUser = TestConstants.GENERIC_USER;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Functional test to validate DVS objects filters "
               + "based on permissions. " + "This test validates getconfig(), getportgroup()"
               + " and getsummary ");
   }

   /**
    * Method to set up the Environment for the test.
    *
    * @param connectAnchor Reference to the ConnectAnchor object.
    * @return True, if test set up was successful False, if test set up was not
    *         successful
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp() throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");
      ManagedObjectReference parentNWFolder = null;
      HashMap allHosts = null;
      assertNotNull(SessionManager.login(connectAnchor,
               super.data.getString(TestConstants.TESTINPUT_USERNAME),
               super.data.getString(TestConstants.TESTINPUT_PASSWORD)), LOGIN_PASS, LOGIN_FAIL);
      ihs = new HostSystem(connectAnchor);
      iFolder = new Folder(connectAnchor);
      ivm = new VirtualMachine(connectAnchor);
      iDVPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      iDVS = new DistributedVirtualSwitchHelper(connectAnchor);
      iDVPG = new DistributedVirtualPortgroup(connectAnchor);
      ins = new NetworkSystem(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      datacenterMor = iFolder.getDataCenter();
      authentication = new AuthorizationManager(connectAnchor);
      authManagerMor = authentication.getAuthorizationManager();
      Assert.assertNotNull(datacenterMor, "The DataCenter MOR is null");
      allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
      final Set hostsSet = allHosts.keySet();
      if (hostsSet != null && hostsSet.size() > 0) {
         final Iterator hostsItr = hostsSet.iterator();
         if (hostsItr.hasNext()) {
            hostMor = (ManagedObjectReference) hostsItr.next();
         }
      }
      Assert.assertNotNull(hostMor, "The Host MOR is null");
      /*
       * Create two network folders
       */
      parentNWFolder = iFolder.getNetworkFolder(datacenterMor);
      nwFolderMors[0] = iFolder.createFolder(parentNWFolder, getTestId() + "-NF1");
      nwFolderMors[1] = iFolder.createFolder(parentNWFolder, getTestId() + "-NF2");
      /*
       * Perform DVS OPS
       */
      nsMor = ins.getNetworkSystem(hostMor);
      Assert.assertNotNull(nsMor, "The network system MOR is null");
      originalNetworkConfig = ins.getNetworkConfig(nsMor);
      pnicIds = ins.getPNicIds(hostMor);
      Assert.assertNotNull(nsMor, "Free pnics are available on host",
               "There are no free pnics on the host");
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(dvSwitchName);
      dvsConfigSpec.setNumStandalonePorts(5);
      hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostMember.setBacking(pnicBacking);
      hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      hostMember.setHost(hostMor);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
      dvsMor = iFolder.createDistributedVirtualSwitch(nwFolderMors[0], dvsConfigSpec);
      Assert.assertNotNull(dvsMor, "Successfully created the DVS " + dvSwitchName,
               "Can not create the DVS " + dvSwitchName);
      entityList.add(dvsMor);
      assertTrue(ins.refresh(nsMor), "Refreshed the network system of the host",
               "Can not refresh the network system of the host");
      assertTrue(iDVS.validateDVSConfigSpec(dvsMor, dvsConfigSpec, null),
               "Successfully validated the DVS config spec", "The config spec does not match");
      hostNetworkConfig = iDVS.getHostNetworkConfigMigrateToDVS(dvsMor, hostMor);
      assertTrue((hostNetworkConfig != null && hostNetworkConfig.length == 2
               && hostNetworkConfig[0] != null && hostNetworkConfig[1] != null),
               "Successfully retrieved the original "
                        + "and the updated network config of the host",
               "Can not retrieve the original and the updated " + "network config");
      originalNetworkConfig = hostNetworkConfig[1];
      assertTrue(ins.updateNetworkConfig(nsMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY), "Successfully updated the host network"
               + "  config", "Can not update the host network config");
      pgConfigSpec = new DVPortgroupConfigSpec();
      pgName = getTestId() + "-earlypg";
      pgConfigSpec.setName(pgName);
      pgConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      pgConfigSpec.setNumPorts(1);
      pgList = iDVS.addPortGroups(dvsMor, new DVPortgroupConfigSpec[] { pgConfigSpec });
      assertTrue((pgList != null && pgList.size() == 1), "Successfully added the early binding "
               + "portgroup to the DVS " + pgName, "Unable to add the early binding "
               + "portgroup to the DVS  ");
      pgMor = pgList.get(0);
      /***********/
      status = true;
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test Logic
    *
    * @param connectAnchor - Reference to the ConnectAnchor object
    */
   @Override
   @Test(description = "Functional test to validate DVS objects filters "
               + "based on permissions. " + "This test validates getconfig(), getportgroup()"
               + " and getsummary ")
   public void test() throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         roleIdList = new Vector<String>();
         DVSSummary summary = iDVSwitch.getSummary(dvsMor);
         final ManagedObjectReference[] hosts = com.vmware.vcqa.util.TestUtil.vectorToArray(summary.getHostMember(), com.vmware.vc.ManagedObjectReference.class);
         for (final ManagedObjectReference hostMor : hosts) {
            permissionSpecMap.put("System.Read", ihs.getParentNode(hostMor));
            addRolesAndSetPermissions(permissionSpecMap);
         }
         setNoaccessPermissions(dvsMor);
         if (performSecurityTestsSetup(connectAnchor)) {
            summary = iDVSwitch.getSummary(dvsMor);
            Assert.assertNull(summary, "Unable to acess PortgroupName",
                     "Successfully accessed PortgroupName");
            performSecurityTestsCleanup(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD));
         }
         /*
          * Create new User and do not give access to pgmor
          */
         permissionSpecMap.put("System.Read", dvsMor);
         if (addRolesAndSetPermissions(permissionSpecMap)
                  && performSecurityTestsSetup(connectAnchor)) {
            List<ManagedObjectReference> pgList = iDVS.getPortgroup(dvsMor);
            if (pgList == null || pgList.size() <= 0) {
               log.info("Unable to acess dvport");
               pgList = null;
            } else {
               log.error("Successfully accessed dvport");
            }
            Assert.assertNull(pgList, "Unable to acess dvport", "Successfully accessed dvport");
            performSecurityTestsCleanup(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD));
         }
         // pgList = this.iDVS.getUplinkPortgroups(dvsMor);
         // Assert.assertNull(pgList,"Successfully accessed UplinkPortgroups");
         permissionSpecMap.put("System.Read", dvsMor);
         addRolesAndSetPermissions(permissionSpecMap);
         permissionSpecMap.put("System.Read", pgMor);
         addRolesAndSetPermissions(permissionSpecMap);
         if (addRolesAndSetPermissions(permissionSpecMap)
                  && performSecurityTestsSetup(connectAnchor)) {
            pgList = iDVS.getPortgroup(dvsMor);
            Assert.assertNotNull(pgList, "Successfully accessed dvport", "Unable to acess dvport");
            performSecurityTestsCleanup(connectAnchor,
                     data.getString(TestConstants.TESTINPUT_USERNAME),
                     data.getString(TestConstants.TESTINPUT_PASSWORD));
            status = true;
         }
         VMwareDVSConfigInfo info = iDVS.getConfig(dvsMor);
         ManagedObjectReference[] ports = com.vmware.vcqa.util.TestUtil.vectorToArray(info.getUplinkPortgroup(), com.vmware.vc.ManagedObjectReference.class);
         for (final ManagedObjectReference uplinkPort : ports) {
            permissionSpecMap.put("System.Read", uplinkPort);
            addRolesAndSetPermissions(permissionSpecMap);
         }
         permissionSpecMap.put("System.Read", dvsMor);
         addRolesAndSetPermissions(permissionSpecMap);
         if (performSecurityTestsSetup(connectAnchor)) {
            info = iDVS.getConfig(dvsMor);
            ports = com.vmware.vcqa.util.TestUtil.vectorToArray(info.getUplinkPortgroup(), com.vmware.vc.ManagedObjectReference.class);
            Assert.assertNotNull(ports, "Successfully accessed uplink port",
                     "Unable to acess uplinkport");
            final DistributedVirtualSwitchHostMember[] hostMember = com.vmware.vcqa.util.TestUtil.vectorToArray(info.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
            Assert.assertNull(hostMember, "Unable to acess host", "Successfully accessed Host");
            pgList = iDVS.getPortgroup(dvsMor);
            for (final ManagedObjectReference port : pgList) {
               if (!iDVPG.isUplinkPortgroup(port, dvsMor)) {
                  status = false;
                  break;
               }
            }
            assertTrue(status, "Unable to acess dvport", "Successfully accessed dvport");
         }
      } catch (final Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state, as it was, before setting up the test
    * environment.
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    * @return True, if test clean up was successful False, if test clean up was
    *         not successful
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp() throws Exception
   {
      boolean status = true;
      try {
         status = performSecurityTestsCleanup(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         assertTrue(iDVS.destroy(pgMor), "Successfully destroyed the  port group ",
                  "Unable to destroy the portgroup");
         assertTrue(ins.refresh(nsMor), "Refreshed the network system of the host",
                  "Can not refresh the network system of the host");
         Assert.assertNotNull(originalNetworkConfig, "host network config is null");
         log.info("Restoring the network setting of the host");
         assertTrue(ins.updateNetworkConfig(nsMor, originalNetworkConfig,
                  TestConstants.CHANGEMODE_MODIFY), "Restored the network setting of the host",
                  "Unable to restore the network setting of the host");
         Assert.assertNotNull(dvsMor, " dvsmor is  null");
         assertTrue(iDVS.destroy(dvsMor), "Successfully deleted DVS", "Unable to delete DVS");
         assertTrue(iFolder.destroy(TestUtil.arrayToVector(nwFolderMors)),
                  "Successfully deleted networkfolders", "Unable to delete networkfolders");
         assertTrue(ins.refresh(nsMor), "Refreshed the network system of the host",
                  "Can not refresh the network system of the host");
         status = true;
      } catch (final Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= SessionManager.logout(connectAnchor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @param permissionSpecMap Map of privileges and entity
    * @return boolean true, if setentitypermissions is successful, false,
    *         otherwise.
    */
   public boolean addRolesAndSetPermissions(
            final Map<String, ManagedObjectReference> permissionSpecMap)
   {
      boolean result = false;
      String[] privileges = null;
      int roleId = -1;
      final String roleName = getTestId() + "_role" + "_" + System.currentTimeMillis();
      try {
          if (permissionSpecMap != null && !permissionSpecMap.isEmpty()) {
              privileges = (String[]) permissionSpecMap.keySet().toArray(
                       new String[0]);
              if (privileges != null && privileges.length > 0) {
                 roleIdList = new Vector<String>(privileges.length);
                 roleId = authentication.addAuthorizationRole(authManagerMor,
                          roleName, privileges);
                 roleIdList.add(roleId + "");
                 if (this.authentication.roleExists(this.authManagerMor,
                          roleId)) {
                    log.info("Successfully added the Role : " + roleName
                             + "with privileges");
                    final Permission permissionSpec = new Permission();
                    permissionSpec.setGroup(false);
                    permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
                    permissionSpec.setPropagate(true);
                    permissionSpec.setRoleId(roleId);
                    final Permission[] permissionsArr = { permissionSpec };
                    result = true;
                    if (this.authentication.setEntityPermissions(
                        this.authManagerMor,
                        permissionSpecMap.get(privileges[0]),
                        permissionsArr)) {
							log.info("Successfully set entity permissions " + privileges[0]);
                        } else {
							log.error("Failed to set entity permissions " + privileges[0]);
							result = false;
                       }
                 }
            } else {
               log.error("Unable to obtain privileges ");
            }
         } else {
            log.error("Unable to obtain permissionSpecMap ");
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      return result;
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @param permissionSpecMap Map of privileges and entity
    * @return boolean true, if setentitypermissions is successful, false,
    *         otherwise.
    */
   public boolean setNoaccessPermissions(final ManagedObjectReference enitityMor)
   {
      boolean result = false;
      final int roleId = -5;
      try {
         if (authentication.roleExists(authManagerMor, roleId)) {
            log.info("Successfully added the No access role ");
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(testUser);
            permissionSpec.setPropagate(false);
            permissionSpec.setRoleId(roleId);
            final Permission[] permissionsArr = { permissionSpec };
            result = true;
            if (authentication.setEntityPermissions(authManagerMor, enitityMor, permissionsArr)) {
               log.info("Successfully set entity permissions.");
            } else {
               log.error("Failed to set entity permissions.");
               result = false;
            }
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      return result;
   }

   /**
    * This method performs following actions. 1.Logout of GENERIC_USER 2.Logged in
    * of administrator 3.Removes authorization role
    *
    * @param connectAnchor ConnectAnchor.
    * @param data.getString(TestConstants.TESTINPUT_USERNAME)
    * @param data.getString(TestConstants.TESTINPUT_PASSWORD).
    * @return boolean true, If successful. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean performSecurityTestsCleanup(final ConnectAnchor connectAnchor,
            final String userName, final String password) throws Exception
   {
      boolean result = false;
      int roleId = -1;
      if (SessionManager.logout(connectAnchor)) {
         loginSession = SessionManager.login(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         if (loginSession != null) {
            log.info("Successfully logged in user: "
                     + data.getString(TestConstants.TESTINPUT_USERNAME));
            result = true;
            if (roleIdList != null && roleIdList.size() > 0) {
               for (int i = 0; i < roleIdList.size(); i++) {
                  roleId = Integer.parseInt(roleIdList.get(i));
                  if (authentication.roleExists(authManagerMor, roleId)) {
                     result &= authentication.removeAuthorizationRole(authManagerMor, roleId, false);
                  }
               }
            }
         } else {
            log.error("Failed to login user:" + data.getString(TestConstants.TESTINPUT_USERNAME));
         }
      } else {
         log.error("Failed to logout user: " + TestConstants.GENERIC_USER);
      }
      if (permissionSpecMap != null) {
         permissionSpecMap.clear();
      }
      return result;
   }

   /**
    * This method performs following actions. 1.Logout of administrator 2.Logged
    * in of GENERIC_USER
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, If successful. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean performSecurityTestsSetup(final ConnectAnchor connectAnchor) throws Exception
   {
      boolean result = false;
      if (SessionManager.logout(connectAnchor)) {
         log.info("Successfully logged out " + data.getString(TestConstants.TESTINPUT_USERNAME));
         loginSession = SessionManager.login(connectAnchor, testUser, TestConstants.PASSWORD);
         if (loginSession != null) {
            log.info("Successfully logged in " + "with vm user ");
            result = true;
         } else {
            log.error("Failed to login with test user.");
         }
      } else {
         log.error("Faied to logout.");
      }
      return result;
   }
}

