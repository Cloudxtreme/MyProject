package dvs.nrp.updatenetiorm;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_RESOURCEMANAGEMENT;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_CREATE;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.HostConfigSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.Permission;
import com.vmware.vc.SharesLevel;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.profile.ProfileConstants;

/**
 * Configure a NRP on a dvs by a user not having DVSwitch.ResourceManagement
 * privilege. The api throws exception
 */
public class Sec002 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private HostSystem ihs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private HashMap<ManagedObjectReference, HostSystemInformation> hostMors;
   private ManagedObjectReference hostMor1;
   private ManagedObjectReference hostMor2;
   private HostConfigSpec srcHostProfile1;
   private HostConfigSpec srcHostProfile2;
   private ArrayList<String> srcHost1IpList;
   private ArrayList<String> srcHost2IpList;
   private int roleId;
   private UserSession loginSession;
   private AuthorizationManager authentication;
   private ManagedObjectReference authManagerMor;
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Configure a NRP on a dvs by a user "
               + "not having DVSwitch.ResourceManagement privilege. The api throws exception")
   public void test()
      throws Exception
   {
      try {
         // update nrp
         idvs.updateNetworkResourcePool(dvsMor,
                  new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });
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
      if (authHelper != null) {
         Assert.assertTrue(authHelper.performSecurityTestsCleanup(),
                  "Failed to perform Security Tests Cleanup");
      }

      // delete the dvs
      HashMap<String, List<String>> map = new HashMap<String, List<String>>();
      map.put(ProfileConstants.IP_LIST, srcHost1IpList);
      Assert.assertTrue(NetworkResourcePoolHelper.applyHostConfig(
               connectAnchor, hostMor1, srcHostProfile1),
               "Profile applied on host 1", "Unable to apply profile on host 1");

      map.clear();

      map.put(ProfileConstants.IP_LIST, srcHost2IpList);
      Assert.assertTrue(NetworkResourcePoolHelper.applyHostConfig(
               connectAnchor, hostMor2, srcHostProfile2),
               "Profile applied on host 2", "Unable to apply profile on host 2");

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
      srcHost1IpList = new ArrayList<String>();
      srcHost2IpList = new ArrayList<String>();

      // get a standalone hostmors
      // We need at at least 2 hostmors
      hostMors = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);

      Assert.assertTrue(hostMors.size() >= 2, "Unable to find two hosts");

      Set<ManagedObjectReference> hostSet = hostMors.keySet();
      Iterator<ManagedObjectReference> hostIterator = hostSet.iterator();
      if (hostIterator.hasNext()) {
         hostMor1 = hostIterator.next();
         srcHost1IpList.add(ihs.getIPAddress(hostMor1));
         srcHostProfile1 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId(),
                  hostMor1);
      }
      if (hostIterator.hasNext()) {
         hostMor2 = hostIterator.next();
         srcHost2IpList.add(ihs.getIPAddress(hostMor2));
         srcHostProfile2 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId()
                           + "-1", hostMor2);
      }

      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch("dvs",
               DVSTestConstants.VDS_VERSION_41);
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Extract the network resource pool related to the vm from the dvs
      nrp = idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VM);

      // set the values in the config spec
      setNrpConfigSpec();

      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), false,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_CREATE, testUser,
               false);
      return authHelper.performSecurityTestsSetup(testUser);


   }

   /**
    * Set up the nrp config spec
    */
   private void setNrpConfigSpec()
   {
      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec();
      nrpConfigSpec.setKey(nrp.getKey());
      nrpConfigSpec.setAllocationInfo(nrp.getAllocationInfo());
      nrpConfigSpec.getAllocationInfo().setLimit(new Long(-1));
      nrpConfigSpec.getAllocationInfo().getShares().setLevel(SharesLevel.HIGH);
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Configure a NRP on a dvs by a user "
               + "not having DVSwitch.ResourceManagement privilege. The api throws exception");
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
