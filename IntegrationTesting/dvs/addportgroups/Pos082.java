/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Create a dvportgroup with a pre-defined nrp associated to it<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS <BR>
 * 3. Enable netiorm <BR>
 * 4. Extract a pre-defined nrp from the dvs<BR>
 * 5. Create the dv portgroup spec<BR>
 * TEST:<BR>
 * 6. Add a portgroup on the dvs with nrp associated to it<BR>
 * 7. Verify the nrp from the dvs <BR>
 * CLEANUP:<BR>
 * 8. Destroy the dvs<BR>
 */
public class Pos082 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private DVPortgroupConfigSpec dvpgSpec;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);

      // create the dvs
      dvsMor = folder.createDistributedVirtualSwitch(
               DVSTestConstants.DVS_CREATE_NAME_PREFIX + getTestId(),
               DVSUtil.getvDsVersion());
      Assert.assertNotNull(dvsMor, "DVS created", "DVS not created");

      // enable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP enabled on the dvs",
               "NRP is not enabled on the dvs");

      // Get a default nrp spec
      nrpConfigSpec = NetworkResourcePoolHelper.createDefaultNrpSpec();

      // Add the network resource pool to the dvs
      dvs.addNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec });

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(connectAnchor,
               dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      nrp = dvs.extractNetworkResourcePool(dvsMor, DVSTestConstants.NRP_VMOTION);

      // create the spec
      dvpgSpec = NetworkResourcePoolHelper.createDvpgSpec(connectAnchor, getTestId(), dvsMor);

      // associate nrp to dvpg spec
      NetworkResourcePoolHelper.associateNrpToDvpgSpec(dvpgSpec, nrp);

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Create a dvportgroup with a pre-defined nrp associated to it")
   public void test()
      throws Exception
   {
      List<ManagedObjectReference> pgMors = dvs.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvpgSpec });
      Assert.assertNotEmpty(pgMors, "Portgroup added successfully",
               "Portgroup could not be added");
      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvpg(
               connectAnchor, pgMors.get(0), nrp.getKey()),
               "Nrp is associated", "Nrp is not associated");
   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a dvportgroup with a pre-defined nrp associated to it");
   }

}
