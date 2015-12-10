package dvs.nrp.enablenetiorm;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_RESOURCEMANAGEMENT;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_CREATE;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * Enable network resource management on a dvs. Login as a user not having
 * DVSwitch.ResourceManagement privilege and try to disable netiorm
 */
public class Sec003 extends TestBase
{
   DistributedVirtualSwitch idvs;
   Folder ifolder;
   HostSystem ihs;
   ManagedObjectReference hostMor;
   ManagedObjectReference dvsMor;
   private int roleId;
   private UserSession loginSession;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private AuthorizationManager authentication;

   /**
    * Test Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Enable network resource management on a dvs "
               + "Login as a user not having DVSwitch.ResourceManagement "
               + "privilege and try to disable netiorm");
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
      // get a standalone hostmor
      hostMor = ihs.getStandaloneHost();
      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch("dvs",hostMor);
      // enable netiorm
      idvs.enableNetworkResourceManagement(dvsMor, true);
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), false,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_CREATE, testUser,
               false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Enable network resource management on a dvs "
               + "Login as a user not having DVSwitch.ResourceManagement "
               + "privilege and try to disable netiorm")
   public void test()
      throws Exception
   {
      try {
         // Disable netiorm. This should throw No Permission
         idvs.enableNetworkResourceManagement(dvsMor, false);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NoPermission();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, getExpectedMethodFault()),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Cleanup method Destroy the dvs
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
      status &= idvs.destroy(dvsMor);
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dvsMor);
      expectedFault.setPrivilegeId(DVSWITCH_RESOURCEMANAGEMENT);
      return expectedFault;
   }
}
