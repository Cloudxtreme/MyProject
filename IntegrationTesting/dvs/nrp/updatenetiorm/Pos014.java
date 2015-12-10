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
 * DESCRIPTION:Update a previously created nrp on the dvs. Change the
 * description to some valid value<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.get standalone hostmors<BR>
 * 2.create the dvs<BR>
 * 3.enable netiorm<BR>
 * 4.Get a default nrp spec<BR>
 * 5.Add the network resource pool to the dvs<BR>
 * 6.Change the description and update the spec<BR>
 * TEST:<BR>
 * 7.update nrp<BR>
 * 8.If nrp is retrieved, description change is successful.<BR>
 * 9.Verify the net-dvs command<BR>
 * CLEANUP:<BR>
 * 10.Delete nrp<BR>
 * 11.Restore hosts<BR>
 * 12.Delete the dvs<BR>
 */
public class Pos014 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private ManagedObjectReference hostMor1;
   private ManagedObjectReference hostMor2;
   private HostConfigSpec srcHostProfile1;
   private HostConfigSpec srcHostProfile2;
   private String changedDescription;
   private DVSNetworkResourcePoolConfigSpec[] nrpConfigSpecs;

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

      // We need at at least 2 hostmors
      Map<ManagedObjectReference, HostSystemInformation> hostMors = hostSystem.getAllHosts(
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
      dvsMor = folder.createDistributedVirtualSwitch(getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      Assert.assertNotNull(dvs.addPortGroup(dvsMor,
               DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 4,
               DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX + getTestId()),
               "Unable to add portgroup");

      // enable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Get a default nrp spec
      nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();
      nrpConfigSpecs = new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec };

      // Add the network resource pool to the dvs
      dvs.addNetworkResourcePool(dvsMor, nrpConfigSpecs);

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());
      DVSNetworkResourcePool[] nrps = new DVSNetworkResourcePool[] { nrp };

      NetworkResourcePoolHelper.addHostToDvsAndVerifyNetDvs(connectAnchor,
               dvsMor, hostMor1, nrps, nrpConfigSpecs);

      NetworkResourcePoolHelper.addFreePnicToDvsAndVerifyVsiState(
               connectAnchor, dvsMor, hostMor1, nrps, nrpConfigSpecs);

      NetworkResourcePoolHelper.moveVswitchPnicToDvsAndVerifyVsi(connectAnchor,
               dvsMor, hostMor1, nrps, nrpConfigSpecs);

      NetworkResourcePoolHelper.addHostToDvsAndVerifyNetDvs(connectAnchor,
               dvsMor, hostMor2, nrps, nrpConfigSpecs);

      //Update the description
      changedDescription = getTestId() + "-1";

      // Now update the name in the spec
      nrpConfigSpec.setKey(nrp.getKey());
      nrpConfigSpec.setDescription(changedDescription);

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Update a previously created nrp on the dvs. Change the description to some valid value")
   public void test()
      throws Exception
   {
      // update nrp
      dvs.updateNetworkResourcePool(dvsMor, nrpConfigSpecs);

      // Extract the nrp by name
      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());

      // If nrp is retrieved, name change is successful.
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
      // delete the dvs
      NetworkResourcePoolHelper.restoreHosts(
               connectAnchor,
               new HostConfigSpec[] { srcHostProfile1, srcHostProfile2 },
               new ManagedObjectReference[] { hostMor1, hostMor2 });

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
      setTestDescription("Update a previously created nrp on the dvs. Change the description to some valid value");
   }

}
