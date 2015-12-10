/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.updatenetiorm;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_RESOURCEMANAGEMENT;

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
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;
import com.vmware.vcqa.vim.profile.ProfileConstants;

/**
 * DESCRIPTION:Configure a NRP on a dvs by a user having
 * DVSwitch.ResourceManagement privilege.Invoke updateNetworkResourcePool with
 * configspec(with the new pTag)<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.get standalone hostmors<BR>
 * 2.create the dvs<BR>
 * 3.enable netiorm<BR>
 * 4.Get a default nrp spec<BR>
 * 5.Add the network resource pool to the dvs and verify the same<BR>
 * 6.Add the roles and privileges<BR>
 * TEST:<BR>
 * 7.update nrp<BR>
 * 8.Verify the updated nrp<BR>
 * 9.Verify the net-dvs command<BR>
 * CLEANUP:<BR>
 * 10.Perform security cleanup<BR>
 * 11.Delete nrp<BR>
 * 12.Restore hosts<BR>
 * 13.Delete the dvs<BR>
 */
public class Sec003 extends TestBase
{
   private DistributedVirtualSwitch idvs;
   private Folder ifolder;
   private HostSystem ihs;
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference[] hostMors;
   private HostConfigSpec[] srcHostProfiles;
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;

   private DVSNetworkResourcePool[] nrps;
   private DVSNetworkResourcePool nrp;

   private DVSNetworkResourcePoolConfigSpec[] nrpConfigSpecs;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;

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
      hostMors = new ManagedObjectReference[2];
      srcHostProfiles = new HostConfigSpec[2];

      // get a standalone hostmors
      // We need at at least 2 hostmors
      HashMap<ManagedObjectReference, HostSystemInformation> hostMorsMap = ihs.getAllHosts(
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
      nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();
      nrpConfigSpecs = new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec };

      // Add the network resource pool to the dvs
      idvs.addNetworkResourcePool(dvsMor, nrpConfigSpecs);

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());
      nrps = new DVSNetworkResourcePool[] { nrp };

      // Now update the name in the spec
      nrpConfigSpec.setKey(nrp.getKey());
      nrpConfigSpec.setName(getTestId() + "-1");

      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), false,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_RESOURCEMANAGEMENT,
               TestConstants.GENERIC_USER, false);
      authHelper.performSecurityTestsSetup(testUser);

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Configure a NRP on a dvs by a user having DVSwitch.ResourceManagement privilege. " +
   		"Invoke updateNetworkResourcePool with configspec(with the new pTag)")
   public void test()
      throws Exception
   {
      // update nrp
      idvs.updateNetworkResourcePool(dvsMor, nrpConfigSpecs);

      // verify from the dvs that the
      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpec),
               "Verified from dvs successfully");

      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());

      // If nrp is retrieved, name change is successful.
      Assert.assertNotNull(nrp, "NRP name change verified",
               "NRP name change not verified");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // remove the network resource pool
      Assert.assertTrue(authHelper.performSecurityTestsCleanup(),
               "Authorization helper cleanup not successful");

      // Delete the nrp
      idvs.removeNetworkResourcePool(dvsMor,
               new String[] { nrpConfigSpec.getKey() });

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
      setTestDescription("Configure a NRP on a dvs by a user having DVSwitch.ResourceManagement privilege. "
               + "Invoke updateNetworkResourcePool with configspec(with the new pTag)");
   }

}
