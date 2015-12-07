package dvs.nrp.enablenetiorm;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.Permission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * Enable network resource management on a dvs by a user having
 * DVSwitch.ResourceManagement privilege
 */
public class Sec001 extends TestBase
{
   DistributedVirtualSwitch idvs;
   Folder ifolder;
   HostSystem ihs;
   ManagedObjectReference hostMor;
   ManagedObjectReference dvsMor;
   private int roleId;
   private UserSession loginSession;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Enable network resource management on a dvs "
               + "by a user having DVSwitch.ResourceManagement privilege ")
   public void test()
      throws Exception
   {
      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      // delete the dvs
      Assert.assertTrue(SessionManager.logout(connectAnchor),
               "Logout done for dvs user", "Logout failed for dvs user");
      loginSession = SessionManager.login(connectAnchor,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      Assert.assertNotNull(loginSession, "Login done", "Login failed");
      Assert.assertTrue(authentication.roleExists(this.authManagerMor, roleId),
               "Role does not exist");
      Assert.assertTrue(authentication.removeAuthorizationRole(authManagerMor,
               roleId, false), "Role removed", "Unable to remove role");

      Assert.assertTrue(idvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      authentication = new AuthorizationManager(connectAnchor);
      authManagerMor = authentication.getAuthorizationManager();

      // get a standalone hostmor
      hostMor = ihs.getStandaloneHost();
      Assert.assertNotNull(hostMor, "Host Mor null");
      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch("dvs",
               DVSTestConstants.VDS_VERSION_41, hostMor);

      Assert.assertNotNull(dvsMor, "DVS Mor null");

      Assert.assertTrue(addRole(), "Role added", "Unable to add role");

      Assert.assertTrue(SessionManager.logout(connectAnchor), "Logout done",
               "Logout failed");

      loginSession = SessionManager.login(connectAnchor,
               TestConstants.GENERIC_USER, TestConstants.PASSWORD);

      Assert.assertNotNull(loginSession, "Login done", "Login failed");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Enable network resource management on a dvs "
               + "by a user having DVSwitch.ResourceManagement privilege ");
   }

   /**
    * Add a role with given privileges and set necessary entity permissions.
    *
    * @return true if successful.
    */
   private boolean addRole()
   {
      boolean result = false;
      final String[] privileges = { PrivilegeConstants.DVSWITCH_RESOURCEMANAGEMENT };
      final String roleName = getTestId() + "Role";
      try {
         this.roleId = this.authentication.addAuthorizationRole(authManagerMor,
                  roleName, privileges);
         if (this.authentication.roleExists(this.authManagerMor, this.roleId)) {
            log.info("Successfully added the Role : " + roleName
                     + "with privileges: " + privileges);
            final Permission permissionSpec = new Permission();
            permissionSpec.setGroup(false);
            permissionSpec.setPrincipal(TestConstants.GENERIC_USER);
            permissionSpec.setPropagate(false);
            permissionSpec.setRoleId(this.roleId);
            final Permission[] permissionsArr = { permissionSpec };
            if (this.authentication.setEntityPermissions(this.authManagerMor,
                     dvsMor, permissionsArr)) {
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
