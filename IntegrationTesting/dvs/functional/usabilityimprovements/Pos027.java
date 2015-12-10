/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.functional.usabilityimprovements;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import com.vmware.vc.DistributedVirtualSwitchManagerCompatibilityResult;
import com.vmware.vc.DistributedVirtualSwitchManagerDvsProductSpec;
import com.vmware.vc.DistributedVirtualSwitchManagerHostContainer;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * (Test Case to verify checkCompatibility api for three specs that contain<BR>
 * HostArrayFilter, HostContainerFilter, HostDvsMembershipFilter) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1.Get the compatible hosts for given vDs version from datacenter. <BR>
 * 2.Set setNoaccessPermissions on one of the compatible hosts TEST:<BR>
 * 3.Invoke checkCompatibility method by passing container as datacenter, <BR>>
 * dvsMembership as null and switchProductSpec as valid ProductSpec for<BR>
 * the new DVSs<BR>
 * CLEANUP:<BR>
 * 3. Destroy vDs<BR>
 */
public class Pos027 extends TestBase implements IDataDrivenTest
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder folder = null;
   private HostSystem ihs = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private DistributedVirtualSwitchManagerHostContainer hostContainer = null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult =
            null;
   private ManagedObjectReference hostFolder = null;
   private String vDsVersion = null;
   private String testUser = TestConstants.GENERIC_USER;
   private UserSession loginSession;
   private List<String> roleIdList = null;
   private Map<String, ManagedObjectReference> permissionSpecMap =
            new HashMap<String, ManagedObjectReference>();
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;
   private Vector<ManagedObjectReference> allHosts =
            new Vector<ManagedObjectReference>();
   private List<ManagedObjectReference> validHosts =
            new Vector<ManagedObjectReference>();
   private Vector<MethodFault> faults = new Vector<MethodFault>();
   private ManagedObjectReference compatibleHosts[] = null;
   private Vector<DistributedVirtualSwitchManagerCompatibilityResult> allFaults =
            new Vector<DistributedVirtualSwitchManagerCompatibilityResult>();
   private ManagedObjectReference sessionMgrMor;// SessionManager MOR.
   private SessionManager sessionManager = null;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters( { "dataFile" })
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   public String getTestName()
   {
      return getTestId();
   }

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("1. Get the compatible hosts for given vDs version from  datacenter. \n"
               + "2.Set setNoaccessPermissions on one of the compatible hosts \n"
               + " 3.Invoke checkCompatibility method by passing\n"
               + " container as datacenter, "
               + " dvsMembership as null and new vDs version"
               + "switchProductSpec "
               + "as valid ProductSpec for  the new DVS\n");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      folder = new Folder(connectAnchor);
      this.authentication = new AuthorizationManager(connectAnchor);
      sessionManager = new SessionManager(connectAnchor);
      sessionMgrMor = sessionManager.getSessionManager();
      ihs = new HostSystem(connectAnchor);
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      assertNotNull(productSpec,
               "Successfully obtained  the productSpec for : " + vDsVersion,
               "Null returned for productSpec for :" + vDsVersion);
      compatibleHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      allHosts = this.ihs.getAllHost();
      assertTrue((allHosts != null && allHosts.size() > 0),
               MessageConstants.HOST_GET_PASS, MessageConstants.HOST_GET_FAIL);
      allHosts.removeAll(TestUtil.arrayToVector(compatibleHosts));
      hostFolder = this.ihs.getHostFolder(compatibleHosts[0]);
      this.setNoaccessPermissions(this.ihs.getParentNode(compatibleHosts[0]));
      assertNotNull(hostFolder, "Successfully got the hostFolder",
               "Null returned for hostFolder");
      if (compatibleHosts != null) {
         for (int i = 1; i < compatibleHosts.length; i++) {
            validHosts.add(compatibleHosts[i]);
         }
      }
      if (allHosts != null && allHosts.size() > 0) {
         for (int i = 0; i < allHosts.size(); i++) {
            faults = new Vector<MethodFault>();
            DistributedVirtualSwitchManagerCompatibilityResult expectedCompatibilityResult =
                     new DistributedVirtualSwitchManagerCompatibilityResult();
            expectedCompatibilityResult.setHost(allHosts.get(i));
            faults.add(DVSTestConstants.EXPECTED_FAULT_1);
            expectedCompatibilityResult.getError().clear();
            expectedCompatibilityResult.getError().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(DVSUtil
                     .createLocalizedMethodFault(faults)));
            allFaults.add(expectedCompatibilityResult);
         }
         expectedCompatibilityResult = TestUtil.vectorToArray(allFaults);
      }
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
      permissionSpecMap.put("System.View", this.folder.getRootFolder());
      assertTrue(addRolesAndSetPermissions(permissionSpecMap)
               && performSecurityTestsSetup(connectAnchor), "Test setup failed");
      return true;
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @param permissionSpecMap Map of privileges and entity
    * @return boolean true, if setentitypermissions is successful, false,
    *         otherwise.
    */
   public boolean addRolesAndSetPermissions(Map<String, ManagedObjectReference> permissionSpecMap)
   {
      boolean result = false;
      final String roleName = getTestId() + "Role";
      String[] privileges = null;
      int roleId = -1;
      try {
         this.authentication = new AuthorizationManager(connectAnchor);
         this.authManagerMor = this.authentication.getAuthorizationManager();
         if (permissionSpecMap != null && !permissionSpecMap.isEmpty()) {
            privileges = permissionSpecMap.keySet().toArray(new String[0]);
            if (privileges != null && privileges.length > 0) {
               roleIdList = new Vector<String>(privileges.length);
               for (int i = 0; i < privileges.length; i++) {
                  roleId =
                           authentication.addAuthorizationRole(authManagerMor,
                                    roleName, privileges);
                  roleIdList.add(roleId + "");
                  if (this.authentication.roleExists(this.authManagerMor,
                           roleId)) {
                     log.info("Successfully added the Role : " + roleName
                              + "with privileges: " + privileges[i]);
                     final Permission permissionSpec = new Permission();
                     permissionSpec.setGroup(false);
                     permissionSpec.setPrincipal(this.testUser);
                     permissionSpec.setPropagate(true);
                     permissionSpec.setRoleId(roleId);
                     final Permission[] permissionsArr = { permissionSpec };
                     result = true;
                     if (this.authentication.setEntityPermissions(
                              this.authManagerMor, permissionSpecMap
                                       .get(privileges[i]), permissionsArr)) {
                        log.info("Successfully set entity permissions.");
                     } else {
                        log.error("Failed to set entity permissions.");
                        result = false;
                        break;
                     }
                  }
               }

            } else {
               log.error("Unable to obtain privileges ");
            }
         } else {
            log.error("Unable to obtain permissionSpecMap ");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return result;
   }

   /**
    * This method performs following actions. 1.Logout of GENERIC_USER 2.Logged
    * in of administrator 3.Removes authorization role
    *
    * @param connectAnchor ConnectAnchor.
    * @param data.getString(TestConstants.TESTINPUT_USERNAME)
    * @param data.getString(TestConstants.TESTINPUT_PASSWORD).
    * @return boolean true, If successful. false, otherwise.
    * @throws MethodFault, Exception
    */
   public boolean performSecurityTestsCleanup(ConnectAnchor connectAnchor,
                                              String userName,
                                              String password)
      throws Exception
   {
      boolean result = false;
      int roleId = -1;
      if (new SessionManager(connectAnchor).logout(this.sessionMgrMor)) {
         if (new SessionManager(connectAnchor).login(sessionMgrMor, data
                  .getString(TestConstants.TESTINPUT_USERNAME), data
                  .getString(TestConstants.TESTINPUT_PASSWORD), null) != null) {
            log.info("Successfully logged in user: "
                     + data.getString(TestConstants.TESTINPUT_USERNAME));
            result = true;
            if (roleIdList != null && roleIdList.size() > 0) {
               for (int i = 0; i < roleIdList.size(); i++) {
                  roleId = Integer.parseInt(roleIdList.get(i));
                  if (this.authentication.roleExists(this.authManagerMor,
                           roleId)) {
                     result &=
                              this.authentication.removeAuthorizationRole(
                                       this.authManagerMor, roleId, false);
                  }
               }
            }
         } else {
            log.error("Failed to login user:"
                     + data.getString(TestConstants.TESTINPUT_USERNAME));
         }
      } else {
         log.error("Failed to logout user: " + TestConstants.GENERIC_USER);
      }
      if (this.permissionSpecMap != null) {
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
   public boolean performSecurityTestsSetup(ConnectAnchor connectAnchor)
      throws Exception
   {
      boolean result = false;
      if (new SessionManager(connectAnchor).logout(sessionMgrMor)) {
         log.info("Successfully logged out "
                  + data.getString(TestConstants.TESTINPUT_USERNAME));
         if (new SessionManager(connectAnchor).login(sessionMgrMor,
                  this.testUser, TestConstants.PASSWORD, null) != null) {
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

   @Test(description = "1. Get the compatible hosts for given vDs version from  datacenter. \n"
            + "2.Set setNoaccessPermissions on one of the compatible hosts \n"
            + " 3.Invoke checkCompatibility method by passing\n"
            + " container as datacenter, "
            + " dvsMembership as null and new vDs version"
            + "switchProductSpec " + "as valid ProductSpec for  the new DVS\n")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchManagerDvsProductSpec spec =
               new DistributedVirtualSwitchManagerDvsProductSpec();
      spec.setDistributedVirtualSwitch(null);
      spec.setNewSwitchProductSpec(productSpec);
      actualCompatibilityResult =
               this.dvsManager.queryCheckCompatibility(dvsManagerMor,
                        hostContainer, spec, null);
      if (expectedCompatibilityResult != null) {
         assertTrue(DVSUtil.verifyHostsInCompatibilityResults(connectAnchor,
                  actualCompatibilityResult, expectedCompatibilityResult,
                  this.validHosts, this.vDsVersion), "Test Failed");
         status = true;
      } else {
         log
                  .info("expectedCompatibilityResult is null.."
                           + "that means all hosts are compatible hence setting outcome to true");
         status = true;
      }
      assertTrue(status, "Test failed");

   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return performSecurityTestsCleanup(connectAnchor, data
               .getString(TestConstants.TESTINPUT_USERNAME), data
               .getString(TestConstants.TESTINPUT_PASSWORD));

   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @param permissionSpecMap Map of privileges and entity
    * @return boolean true, if setentitypermissions is successful, false,
    *         otherwise.
    */
   public boolean setNoaccessPermissions(ManagedObjectReference enitityMor)
   {
      boolean result = false;
      int roleId = -5;
      try {
         authManagerMor = this.authentication.getAuthorizationManager();
         if (this.authentication.roleExists(this.authManagerMor, roleId)) {
            log.info("Successfully added the No access role ");
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(this.testUser);
            permissionSpec.setPropagate(true);
            permissionSpec.setRoleId(roleId);
            final Permission[] permissionsArr = { permissionSpec };
            result = true;
            if (this.authentication.setEntityPermissions(this.authManagerMor,
                     enitityMor, permissionsArr)) {
               log.info("Successfully set entity permissions.");
            } else {
               log.error("Failed to set entity permissions.");
               result = false;
            }
         }

      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      return result;
   }

}
