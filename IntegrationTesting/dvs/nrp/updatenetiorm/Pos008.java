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
 * Configure NRP for all types.
 */
public class Pos008 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private HostSystem ihs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool[] nrp;
   private DVSNetworkResourcePoolConfigSpec[] nrpConfigSpec;
   private HashMap<ManagedObjectReference, HostSystemInformation> hostMors;
   HashMap<String, Object> vSwitchPnicsMap;
   private ManagedObjectReference hostMor1;
   private ManagedObjectReference hostMor2;
   private HostConfigSpec srcHostProfile1;
   private HostConfigSpec srcHostProfile2;

   /**
    * Test method
    */
   @Override
   @Test(description = "Configure NRP for all types.")
   public void test()
      throws Exception
   {
      NetworkResourcePoolHelper.testNrp(connectAnchor, dvsMor,
               new ManagedObjectReference[] { hostMor1, hostMor2 }, nrp,
               nrpConfigSpec);
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
      NetworkResourcePoolHelper.restoreHosts(
               connectAnchor,
               new HostConfigSpec[] { srcHostProfile1, srcHostProfile2 },
               new ManagedObjectReference[] { hostMor1, hostMor2 });

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

      // get a standalone hostmors
      // We need at at least 2 hostmors
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
      if (hostIterator.hasNext()) {
         hostMor2 = hostIterator.next();
         srcHostProfile2 = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId()
                           + "-1", hostMor2);
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

      // Set the various nrps
      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec[6];
      nrp = new DVSNetworkResourcePool[6];

      // Extract the network resource pool related to the vm from the dvs
      nrp[0] = idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VM);
      nrpConfigSpec[0] = setNrpConfigSpec(nrp[0]);

      nrp[1] = idvs.extractNetworkResourcePool(dvsMor,
               DVSTestConstants.NRP_ISCSI);
      nrpConfigSpec[1] = setNrpConfigSpec(nrp[1]);

      nrp[2] = idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_FT);
      nrpConfigSpec[2] = setNrpConfigSpec(nrp[2]);

      nrp[3] = idvs.extractNetworkResourcePool(dvsMor,
               DVSTestConstants.NRP_MGMT);
      nrpConfigSpec[3] = setNrpConfigSpec(nrp[3]);

      nrp[4] = idvs.extractNetworkResourcePool(dvsMor,
               DVSTestConstants.NRP_VMOTION);
      nrpConfigSpec[4] = setNrpConfigSpec(nrp[4]);

      nrp[5] = idvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_NFS);
      nrpConfigSpec[5] = setNrpConfigSpec(nrp[5]);

      return true;
   }

   private DVSNetworkResourcePoolConfigSpec setNrpConfigSpec(DVSNetworkResourcePool nrpool)
   {
      DVSNetworkResourcePoolConfigSpec configSpec = new DVSNetworkResourcePoolConfigSpec();
      configSpec.setKey(nrpool.getKey());
      configSpec.setName(nrpool.getName());
      configSpec.setAllocationInfo(nrpool.getAllocationInfo());
      configSpec.getAllocationInfo().setLimit(new Long(100));
      configSpec.getAllocationInfo().getShares().setLevel(SharesLevel.HIGH);
      return configSpec;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Configure NRP for all types.");
   }

}
