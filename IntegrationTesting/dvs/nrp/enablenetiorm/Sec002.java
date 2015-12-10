package dvs.nrp.enablenetiorm;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_CREATE;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_RESOURCEMANAGEMENT;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;

/**
 * Enable network resource management on a dvs by a user not having
 * DVSwitch.ResourceManagement privilege
 */
public class Sec002 extends TestBase
{
   DistributedVirtualSwitch idvs;
   Folder ifolder;
   HostSystem ihs;
   ManagedObjectReference hostMor;
   ManagedObjectReference dvsMor;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private AuthorizationManager authentication;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Enable network resource management on a dvs "
               + "by a user not having DVSwitch.ResourceManagement privilege ");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      authentication = new AuthorizationManager(connectAnchor);
      hostMor = ihs.getConnectedHost(false);
      assertNotNull(hostMor, "Failed to get host");
      dvsMor = ifolder.createDistributedVirtualSwitch(getTestId(),
                hostMor);
      assertNotNull(dvsMor, "Failed to create the DVS");
      authentication = new AuthorizationManager(connectAnchor);
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), false,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_CREATE, testUser,
               false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Enable network resource management on a dvs "
               + "by a user not having DVSwitch.ResourceManagement privilege ")
   public void test()
      throws Exception
   {
      try {
         // enable netiorm. This should throw exception as privilege is not present
         idvs.enableNetworkResourceManagement(dvsMor, true);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, getExpectedMethodFault()	),
                  "MethodFault mismatch!");
      }
   }

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
