package dvs.nrp.updatenetiorm;

import java.util.Iterator;
import java.util.Map;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.HostConfigSpec;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SharesInfo;
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
 * DESCRIPTION:Update a previously created nrp alongwith the pre-defined nrps in
 * the same call<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.get standalone hostmors<BR>
 * 2.create the dvs<BR>
 * 3.enable netiorm<BR>
 * 4.Add new nrps and get specs for pre-defined nrps<BR>
 * 5.Update the network resource pool specs<BR>
 * TEST:<BR>
 * 7.update nrp<BR>
 * 8.Verify the updated nrps.<BR>
 * 9.Verify the net-dvs command<BR>
 * 10.Verify vsi state<BR>
 * CLEANUP:<BR>
 * 11.Remove the created nrps<BR>
 * 12.Restore hosts<BR>
 * 13.Delete the dvs<BR>
 */
public class Pos018 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private HostSystem ihs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool[] nrps;
   private DVSNetworkResourcePoolConfigSpec[] nrpConfigSpecs;
   private ManagedObjectReference[] hostMors;
   private HostConfigSpec[] srcHostProfiles;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      ihs = new HostSystem(connectAnchor);
      nrps = new DVSNetworkResourcePool[2];
      nrpConfigSpecs = new DVSNetworkResourcePoolConfigSpec[2];
      srcHostProfiles = new HostConfigSpec[2];
      hostMors = new ManagedObjectReference[2];

      // get a standalone hostmors
      // We need at at least 2 hostmors
      Map<ManagedObjectReference, HostSystemInformation> hostMorsMap = ihs.getAllHosts(
               VersionConstants.ALL_ESX, HostSystemConnectionState.CONNECTED);

      Assert.assertTrue(hostMorsMap.size() >= 2, "Unable to find two hosts");

      Set<ManagedObjectReference> hostSet = hostMorsMap.keySet();
      Iterator<ManagedObjectReference> hostIterator = hostSet.iterator();
      if (hostIterator.hasNext()) {
         hostMors[0] = hostIterator.next();
         srcHostProfiles[0] = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId(),
                  hostMors[0]);
      }
      if (hostIterator.hasNext()) {
         hostMors[1] = hostIterator.next();
         srcHostProfiles[1] = NetworkResourcePoolHelper.extractHostConfigSpec(
                  connectAnchor, ProfileConstants.SRC_PROFILE + getTestId()
                           + "-1", hostMors[1]);
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
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Get a default nrp spec
      nrpConfigSpecs[0] = NetworkResourcePoolHelper.createDefaultNrpSpec();

      // Add the network resource pool to the dvs
      idvs.addNetworkResourcePool(dvsMor, new DVSNetworkResourcePoolConfigSpec[]{nrpConfigSpecs[0]});

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpecs[0]),
               "NRP verified from dvs", "NRP not matching with DVS nrp");

      // set up the first nrp
      nrps[0] = NetworkResourcePoolHelper.extractNRPByName(connectAnchor,
               dvsMor, nrpConfigSpecs[0].getName());

      // get the second nrp. This is a pre-defined nrp
      nrps[1] = idvs.extractNetworkResourcePool(dvsMor,
               DVSTestConstants.NRP_VMOTION);

      // change the descriptions for the newly created nrps
      nrpConfigSpecs[0].setKey(nrps[0].getKey());
      nrpConfigSpecs[0].getAllocationInfo().setLimit(new Long(1000));

      // Get the spec for the second nrp
      nrpConfigSpecs[1] = setNrpConfigSpec(nrps[1]);

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Update a previously created nrp alongwith the pre-defined nrps in the same call")
   public void test()
      throws Exception
   {
      // update nrp
      idvs.updateNetworkResourcePool(dvsMor, nrpConfigSpecs);

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpecs[0]),
               "NRP verified from dvs:", "NRP not matching with DVS nrp:");
      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpecs[1]),
               "NRP verified from dvs:", "NRP not matching with DVS nrp:");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // Delete the nrp
      idvs.removeNetworkResourcePool(dvsMor,
               new String[] { nrps[0].getKey() });

      // delete the dvs
      NetworkResourcePoolHelper.restoreHosts(connectAnchor, srcHostProfiles,
               hostMors);

      // Destroy the dvs
      Assert.assertTrue(idvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Update a previously created nrp alongwith the pre-defined nrps in the same call");
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

}
