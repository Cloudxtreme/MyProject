/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
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
 * DESCRIPTION:Invoke the api on a previously created nrp with netiorm disabled.
 * Perform verification for the dvs alone as the nrp update is not propagated to
 * the host when nrm is disabled<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.get standalone hostmors<BR>
 * 2.create the dvs<BR>
 * 3.disable netiorm<BR>
 * 4.Get a default nrp spec<BR>
 * 5.Add the network resource pool to the dvs<BR>
 * 6.Change the description and update the spec<BR>
 * TEST:<BR>
 * 7.Update network resource pool<BR>
 * 8.Extract the resource pool by name and verify<BR>
 * CLEANUP:<BR>
 * 10.Delete nrp<BR>
 * 11.Restore hosts<BR>
 * 12.Delete the dvs<BR>
 */
public class Pos015 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec[] nrpConfigSpec;
   private ManagedObjectReference[] hostMors;
   private HostConfigSpec[] srcHostProfiles;
   private String changedDescription;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      HostSystem hostSystem = new HostSystem(connectAnchor);
      hostMors = new ManagedObjectReference[2];
      srcHostProfiles = new HostConfigSpec[2];
      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec[1];

      // We need at at least 2 hostmors
      Map<ManagedObjectReference, HostSystemInformation> hostMorsMap = hostSystem.getAllHosts(
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
      dvsMor = folder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      Assert.assertNotNull(dvs.addPortGroup(dvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 4,
               DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX + getTestId()),
               "Unable to add portgroup");

      // disable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, false),
               "Disabled netiorm", "Netiorm not disabled");

      Assert.assertFalse(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP not enabled on the dvs", "NRP enabled on the dvs");

      // Get a default nrp spec
      nrpConfigSpec[0] = NetworkResourcePoolHelper.createDefaultNrpSpec();

      // Add the network resource pool to the dvs
      dvs.addNetworkResourcePool(dvsMor, nrpConfigSpec);

      changedDescription = getTestId() + "-1";

      // Now update the name in the spec
      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec[0].getName());
      nrpConfigSpec[0].setKey(nrp.getKey());
      nrpConfigSpec[0].setDescription(changedDescription);

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Invoke the api on a previously created nrp with netiorm disabled")
   public void test()
      throws Exception
   {
      // update nrp
      dvs.updateNetworkResourcePool(dvsMor, nrpConfigSpec);

      // Extract the nrp by name
      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec[0].getName());

      // Verify description.
      Assert.assertTrue(changedDescription.equals(nrp.getDescription()),
               "NRP name change verified", "NRP name change not verified");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // restore hosts
      NetworkResourcePoolHelper.restoreHosts(connectAnchor, srcHostProfiles,
               hostMors);

      // Destroy the dvs
      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Invoke the api on a previously created nrp with netiorm disabled");
   }

}
