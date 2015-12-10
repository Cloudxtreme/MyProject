/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.addnrp;

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
 * DESCRIPTION:Disable Netiorm, Add Nrp and then enable Netiorm on the dvs<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Extract initial profiles from the host <BR>
 * 2. Create a vDS and dvpg with host <BR>
 * 3. Disable netiorm <BR>
 * TEST:<BR>
 * 4. Add a nrp<BR>
 * 5. Verify the nrp from the dvs <BR>
 * 6. Enable netiorm 7. Add a host to the dvs and verify from the net-dvs
 * command <BR>
 * 8. Add a free pnic to the dvs and verify vsi state on the dvs <BR>
 * 9. Move all pnics to dvs and verify vsi state <BR>
 * 10. Add another host to dvs and verify net-dvs command <BR>
 * CLEANUP:<BR>
 * 11. Destroy nrp<BR>
 * 12. Restore the hosts <BR>
 * 13. Destroy the dvs<BR>
 */
public class Pos003 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference hostMor1;
   private ManagedObjectReference hostMor2;
   private HostConfigSpec srcHostProfile1;
   private HostConfigSpec srcHostProfile2;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder ifolder = new Folder(connectAnchor);
      idvs = new DistributedVirtualSwitch(connectAnchor);
      HostSystem ihs = new HostSystem(connectAnchor);

      // We need at at least 2 hostmors
      Map<ManagedObjectReference, HostSystemInformation> hostMors = ihs.getAllHosts(
               VersionConstants.ALL_ESX, HostSystemConnectionState.CONNECTED);

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

      // disable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, false),
               "Netiorm not enabled");

      Assert.assertTrue(!NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Disable Netiorm, Add Nrp and then enable Netiorm on the dvs")
   public void test()
      throws Exception
   {
      // Get a default nrp spec
      DVSNetworkResourcePoolConfigSpec nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();
      DVSNetworkResourcePoolConfigSpec[] nrpConfigSpecs = new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec };

      // Add the network resource pool to the dvs
      idvs.addNetworkResourcePool(dvsMor, nrpConfigSpecs);

      // verify the nrp details from the dvs
      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      // enable netiorm
      Assert.assertTrue(idvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      // Verify that the nrp is enabled
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Query the nrp by name
      DVSNetworkResourcePool nrp = NetworkResourcePoolHelper.extractNRPByName(
               connectAnchor, dvsMor, nrpConfigSpec.getName());
      DVSNetworkResourcePool[] nrps = new DVSNetworkResourcePool[] { nrp };

      // Add the host to the nrp and then verify the net-dvs command for the nrp
      NetworkResourcePoolHelper.addHostToDvsAndVerifyNetDvs(connectAnchor,
               dvsMor, hostMor1, nrps, nrpConfigSpecs);

      // Add the free pnic to the dvs and verify the vsi state on the pnic
      NetworkResourcePoolHelper.addFreePnicToDvsAndVerifyVsiState(
               connectAnchor, dvsMor, hostMor1, nrps, nrpConfigSpecs);

      // Move the pnic on the vswitch to the dvs and verify the vsi state on the
      // pnic
      NetworkResourcePoolHelper.moveVswitchPnicToDvsAndVerifyVsi(connectAnchor,
               dvsMor, hostMor1, nrps, nrpConfigSpecs);

      // Add te host to the dvs and verify the net-dvs command output on the
      // pnic
      NetworkResourcePoolHelper.addHostToDvsAndVerifyNetDvs(connectAnchor,
               dvsMor, hostMor2, nrps, nrpConfigSpecs);
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // Restore the hosts using their initial profiles
      NetworkResourcePoolHelper.restoreHosts(
               connectAnchor,
               new HostConfigSpec[] { srcHostProfile1, srcHostProfile2 },
               new ManagedObjectReference[] { hostMor1, hostMor2 });

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
      setTestDescription("Disable Netiorm, Add Nrp and then enable Netiorm on the dvs");
   }

}
