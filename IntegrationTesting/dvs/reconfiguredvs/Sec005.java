/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.Permission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create DVSwitch with the following parameters with the following parameters
 * set in the configSpec: - DVSConfigSpec.maxPort set to a valid number equal to
 * numPorts - DVSConfigSpec.numPort set to a valid number equal to the number of
 * uplinks ports per host - DVSConfigSpec.uplinkPortPolicy set to a valid array
 * that is equal to the max number of pnics per host.({uplink1, ..., uplink32})
 * - DVSHostMemberConfigSpec.operation set to add - DVSHostMemberConfigSpec.host
 * set to a valid host Mor - DVSHostMemberConfigSpec.proxy set a a valid pnic
 * proxy selection with pnic spec having a valid pnic device and uplinkPortKey
 * set to null
 */
public class Sec005 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference[] hostMors = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private NetworkSystem iNetworkSystem = null;
   private int roleId;
   private ManagedObjectReference authManagerMor;
   private AuthorizationManager authentication;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create DVSwitch with the following parameters"
               + " with the following parameters set in the configSpec:\n"
               + "- DVSConfigSpec.maxPort set to a valid number equal to numPorts\n"
               + "- DVSConfigSpec.numPort set to a valid number equal to the number of"
               + "uplinks ports per host\n"
               + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that is equal "
               + "to the max number of pnics per host.\n"
               + "- DVSHostMemberConfigSpec.operation set to add\n"
               + "- DVSHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DVSHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchHostMemberPnicBacking hostPnicBacking = null;
      DVSConfigInfo configInfo = null;
      this.hostMors = new ManagedObjectReference[2];
      DistributedVirtualSwitchHostMemberConfigSpec[] hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec[2];
      String dvsName = this.getTestId();
      log.info("Test setup Begin:");

         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.iNetworkSystem = new NetworkSystem(connectAnchor);
            allHosts = this.ihs.getAllHost();
            if ((allHosts != null) && (allHosts.size() >= 2)) {
               this.hostMors[0] = (ManagedObjectReference) allHosts.get(0);
               this.hostMors[1] = (ManagedObjectReference) allHosts.get(1);
            } else {
               log.error("Valid Host MOR not found");
            }
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(dvsName);
               for (int i = 0; i < 2; i++) {
                  hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement[i].setHost(this.hostMors[i]);
                  hostConfigSpecElement[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
                  hostPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostPnicBacking.getPnicSpec().clear();
                  hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
                  hostConfigSpecElement[i].setBacking(hostPnicBacking);
               }
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  this.deltaConfigSpec = new DVSConfigSpec();
                  DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
                  this.deltaConfigSpec.setConfigVersion(configInfo.getConfigVersion());
                  this.deltaConfigSpec.setName(dvsName);
                  String[] uplinkPortNames = new String[] { "Uplink1" };
                  uplinkPolicyInst.getUplinkPortName().clear();
                  uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                  this.deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
                  this.deltaConfigSpec.setMaxPorts(5);
                  this.deltaConfigSpec.setNumStandalonePorts(2);
                  String[] hostPhysicalNics = null;
                  for (int i = 0; i < 2; i++) {
                     hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostConfigSpecElement[i].setHost(this.hostMors[i]);
                     if (i == 1) {
                        hostPhysicalNics = iNetworkSystem.getPNicIds(this.hostMors[i]);
                        if (hostPhysicalNics != null) {
                           DistributedVirtualSwitchHostMemberPnicSpec hostPnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                           hostPnicSpec.setPnicDevice(hostPhysicalNics[0]);
                           hostPnicSpec.setUplinkPortKey(null);
                           hostPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                           hostPnicBacking.getPnicSpec().clear();
                           hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostPnicSpec }));
                           hostConfigSpecElement[i].setBacking(hostPnicBacking);
                           hostConfigSpecElement[i].setOperation(TestConstants.CONFIG_SPEC_EDIT);
                        } else {
                           log.error("No free pnics found on the host.");
                        }
                     } else {
                        hostConfigSpecElement[i].setOperation(TestConstants.CONFIG_SPEC_REMOVE);
                     }
                  }
                  this.deltaConfigSpec.getHost().clear();
                  this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
                  if (addRole()) {
                     if (SessionManager.logout(connectAnchor)) {
                        log.info("Successfully logged out "
                                 + data.getString(TestConstants.TESTINPUT_USERNAME));
                        this.loginSession = SessionManager.login(connectAnchor,
                                 TestConstants.GENERIC_USER, TestConstants.PASSWORD);
                        if (this.loginSession != null) {
                           log.info("Successfully logged in with "
                                    + "user dvsUser");
                           status = true;
                        } else {
                           log.error("Failed to login with test "
                                    + "user.");
                        }
                     } else {
                        log.error("Faied to logout.");
                     }
                  }
               } else {
                  log.error("Failed to create the DVS");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         } else {
            log.error("Failed to login");
         }


      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create DVSwitch with the following parameters"
               + " with the following parameters set in the configSpec:\n"
               + "- DVSConfigSpec.maxPort set to a valid number equal to numPorts\n"
               + "- DVSConfigSpec.numPort set to a valid number equal to the number of"
               + "uplinks ports per host\n"
               + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that is equal "
               + "to the max number of pnics per host.\n"
               + "- DVSHostMemberConfigSpec.operation set to add\n"
               + "- DVSHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DVSHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
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
               authentication = new AuthorizationManager(connectAnchor);
               authManagerMor = authentication.getAuthorizationManager();
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
      final String[] privileges = { PrivilegeConstants.DVSWITCH_MODIFY,
               "DVSwitch.HostOp", PrivilegeConstants.HOST_CONFIG_NETWORK };
      final String roleName = getTestId() + "Role";
      try {
         this.authentication  = new AuthorizationManager(connectAnchor);
         authManagerMor =  this.authentication.getAuthorizationManager();

         this.roleId = this.authentication.addAuthorizationRole(authManagerMor,
                  roleName, privileges);
         if (this.authentication.roleExists(this.authManagerMor, this.roleId)) {
            log.info("Successfully added the Role : " + roleName
                     + "with privileges: " + privileges);
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
            permissionSpec.setPropagate(true);
            permissionSpec.setRoleId(this.roleId);
            final Permission[] permissionsArr = { permissionSpec };
            if (this.authentication.setEntityPermissions(this.authManagerMor,
                     this.dcMor, permissionsArr)) {
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

}
