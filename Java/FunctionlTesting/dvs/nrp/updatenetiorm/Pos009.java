package dvs.nrp.updatenetiorm;

import static com.vmware.vcqa.TestConstants.ESX_PASSWORD;
import static com.vmware.vcqa.TestConstants.ESX_USERNAME;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.vim.MessageConstants.LOGIN_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.LOGIN_PASS;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.HostConfigSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.OptionValue;
import com.vmware.vc.SharesLevel;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.option.OptionManager;
import com.vmware.vcqa.vim.profile.ProfileConstants;

/**
 * Opt out the pnic from NetIORM using advanced settings
 */
public class Pos009 extends TestBase
{
   private SessionManager sessionManager = null;
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private HostSystem ihs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private HashMap<ManagedObjectReference, HostSystemInformation> hostMors;
   private ManagedObjectReference hostMor1;
   private HostConfigSpec srcHostProfile1;
   private OptionManager iOptionManager;
   private ManagedObjectReference optionManagerMor;

   private OptionValue opt;
   private AuthorizationManager auth;
   private ManagedObjectReference authMor_host;

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Opt out the pnic from NetIORM using advanced settings")
   public void test()
      throws Exception
   {
      // update nrp
      idvs.updateNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

      // verify with the dvs
      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(connectAnchor,
               dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      NetworkResourcePoolHelper.addHostsToDvs(dvsMor, hostMor1, connectAnchor);

      Assert.assertTrue(NetworkResourcePoolHelper.verifyUplinkPortsWithNetDvs(
               dvsMor, hostMor1, connectAnchor,
               new DVSNetworkResourcePool[] { nrp },
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec }),
               "Uplink ports verified", "Uplink ports not verified");

      String pnic = NetworkResourcePoolHelper.addFreePnicToDvs(connectAnchor,
               dvsMor, hostMor1);

      // verify the vsi state
      Assert.assertTrue(NetworkResourcePoolHelper.verifyVsiState(connectAnchor,
               dvsMor, hostMor1, pnic, nrp, nrpConfigSpec),
               "Vsi state not verified");

      String hostName = this.ihs.getHostName(hostMor1);
      ConnectAnchor anchor = new ConnectAnchor(hostName,
               data.getInt(TestConstants.TESTINPUT_PORT));
      auth = new AuthorizationManager(anchor);
      sessionManager = new SessionManager(anchor);
      authMor_host = sessionManager.getSessionManager();
      assertNotNull(sessionManager.login(authMor_host, ESX_USERNAME,
               ESX_PASSWORD, null), LOGIN_PASS + "to primary host.", LOGIN_FAIL
               + " into primary host");
      iOptionManager = new OptionManager(anchor);
      optionManagerMor = iOptionManager.getOptionManager();

      opt = new OptionValue();
      opt.setKey(DVSTestConstants.NRP_KEY);
      opt.setValue(pnic);
      iOptionManager.updateOptions(optionManagerMor, new OptionValue[] { opt });
      Thread.sleep(20000);
      boolean result = NetworkResourcePoolHelper.verifyPnicOptedOut(
               connectAnchor, dvsMor, hostMor1, pnic, "advopt");

      opt.setValue("");
      iOptionManager.updateOptions(optionManagerMor, new OptionValue[] { opt });

      Assert.assertTrue(sessionManager.logout(authMor_host),
               "Logged out from host", "Unable to logout from the host");

      Assert.assertTrue(result, "Pnic opt out verified",
               "Pnic opt out not verified");

   }

   /**
    * Cleanup method Destroy the dvs
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      Assert.assertTrue(NetworkResourcePoolHelper.applyHostConfig(
               connectAnchor, hostMor1, srcHostProfile1),
               "Profile applied on host 1", "Unable to apply profile on host 1");
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
      sessionManager = new SessionManager(connectAnchor);
      ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);

      // get a standalone hostmors
      // We need at at least 2 hostmors
      hostMors = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);

      Assert.assertTrue(hostMors.size() >= 1, "Unable to find a host");

      Set<ManagedObjectReference> hostSet = hostMors.keySet();
      Iterator<ManagedObjectReference> hostIterator = hostSet.iterator();
      if (hostIterator.hasNext()) {
         hostMor1 = hostIterator.next();
         srcHostProfile1 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId(),
                  hostMor1);
      }

      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      Assert.assertNotNull(idvs.addPortGroup(dvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 4,
               DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX + getTestId()),
               "Unable to add portgroup");

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP is not enabled on the dvs");

      // Extract the network resource pool related to the vm from the dvs
      nrp = idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VM);

      // set the values in the config spec
      setNrpConfigSpec();

      return true;
   }

   private void setNrpConfigSpec()
   {
      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec();
      nrpConfigSpec.setKey(nrp.getKey());
      nrpConfigSpec.setName(nrp.getName());
      nrpConfigSpec.setAllocationInfo(nrp.getAllocationInfo());
      nrpConfigSpec.getAllocationInfo().setLimit(new Long(100));
      nrpConfigSpec.getAllocationInfo().getShares().setLevel(SharesLevel.HIGH);
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Opt out the pnic from NetIORM using advanced settings");
   }

}
