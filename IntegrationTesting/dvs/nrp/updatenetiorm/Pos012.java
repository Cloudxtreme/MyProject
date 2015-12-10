package dvs.nrp.updatenetiorm;

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
import com.vmware.vc.SharesLevel;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.profile.ProfileConstants;

/**
 * Call enableNetworkResourceManagement api with parameter enable set to false.
 * Configure a NRP for vm traffic. Call update.
 */
public class Pos012 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private HashMap<ManagedObjectReference, HostSystemInformation> hostMors;
   private HostSystem ihs;
   private ManagedObjectReference hostMor1;
   private HostConfigSpec srcHostProfile1;

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Override
   @Test(description = "Call enableNetworkResourceManagement api with "
               + "parameter enable set to false. Configure a NRP for vm traffic. "
               + "Call update.")
   public void test()
      throws Exception
   {
      // update nrp
      idvs.updateNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(connectAnchor,
               dvsMor, nrpConfigSpec),
               "Config spec should not be matched as the api should throw an exception");

      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      // verify whether netiorm is enabled
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP is not enabled on the dvs",
               "NRP is enabled on the dvs");

      Assert.assertTrue(NetworkResourcePoolHelper.addHostToDvsAndVerifyNetDvs(
               connectAnchor, dvsMor, hostMor1,
               new DVSNetworkResourcePool[] { nrp },
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec }),
               "Unable to add host and verify");

      NetworkResourcePoolHelper.addFreePnicToDvsAndVerifyVsiState(
               connectAnchor, dvsMor, hostMor1,
               new DVSNetworkResourcePool[] { nrp },
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

      NetworkResourcePoolHelper.moveVswitchPnicToDvsAndVerifyVsi(connectAnchor,
               dvsMor, hostMor1, new DVSNetworkResourcePool[] { nrp },
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

   }

   /**
    * Cleanup method Destroy the dvs
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      NetworkResourcePoolHelper.restoreHosts(connectAnchor,
               new HostConfigSpec[] { srcHostProfile1 },
               new ManagedObjectReference[] { hostMor1 });

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

      hostMors = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);

      Assert.assertTrue(hostMors.size() >= 2, "Unable to find two hosts");

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

      Assert.assertNotNull(idvs.addPortGroup(dvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 4,
               DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX + getTestId()),
               "Unable to add portgroup");

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, false),
               "Netiorm not enabled");

      // verify whether netiorm is enabled
      Assert.assertFalse(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP is not enabled on the dvs",
               "NRP is enabled on the dvs");

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
      setTestDescription("Call enableNetworkResourceManagement api with "
               + "parameter enable set to false. Configure a NRP for vm traffic. "
               + "Call update.");
   }

}
