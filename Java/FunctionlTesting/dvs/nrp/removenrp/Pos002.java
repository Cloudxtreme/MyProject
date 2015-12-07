/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.removenrp;

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
 * DESCRIPTION:Create and remove multiple nrps<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.get standalone hostmors and initial profiles<BR>
 * 2.create the dvs<BR>
 * 3.enable netiorm<BR>
 * 4.Add the nrps to the dvs<BR>
 * TEST:<BR>
 * 5.Delete the nrps<BR>
 * CLEANUP:<BR>
 * 6.Restore the hosts<BR>
 * 7.Delete the dvs<BR>
 */
public class Pos002 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;

   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec[] nrpConfigSpec;
   private String[] keys;

   private HashMap<ManagedObjectReference, HostSystemInformation> hostMors;
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
      Folder folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      HostSystem hs = new HostSystem(connectAnchor);

      nrpConfigSpec = new DVSNetworkResourcePoolConfigSpec[5];
      keys = new String[5];

      // We need at at least 2 hostmors
      hostMors = hs.getAllHosts(VersionConstants.ALL_ESX, HostSystemConnectionState.CONNECTED);

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
      dvsMor = folder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
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
      for (int i = 0; i < 5; i++) {
         nrpConfigSpec[i] = NetworkResourcePoolHelper.createDefaultNrpSpec();
         nrpConfigSpec[i].setName(nrpConfigSpec[i].getName() + i);
      }

      // Add the network resource pool to the dvs
      dvs.addNetworkResourcePool(dvsMor, nrpConfigSpec);

      for (int i = 0; i < 5; i++) {
         nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor,
                  dvsMor, nrpConfigSpec[i].getName());
         Assert.assertNotNull(nrp, "NRP successfully added -" + i,
                  "NRP not added -" + i);
         keys[i] = nrp.getKey();
      }

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Create and remove multiple nrps")
   public void test()
      throws Exception
   {
      // Delete the nrp
      dvs.removeNetworkResourcePool(dvsMor, keys);

      for (int i = 0; i < 5; i++) {
         nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor,
                  dvsMor, nrpConfigSpec[i].getName());
         Assert.assertNull(nrp, "NRP successfully removed -" + i,
                  "NRP not removed -" + i);
      }
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

      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Create and remove multiple nrps");
   }

}
