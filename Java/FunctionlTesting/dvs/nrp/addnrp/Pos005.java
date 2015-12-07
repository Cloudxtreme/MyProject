/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.addnrp;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Add two or more network resource pools with the same name. Set
 * the keys to different values<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.create the dvs<BR>
 * 2.enable netiorm<BR>
 * 3.set the values in the config spec<BR>
 * TEST:<BR>
 * 4.add both the nrp<BR>
 * CLEANUP:<BR>
 * 5.Destroy dvs<BR>
 */
public class Pos005 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private ManagedObjectReference dvsMor;

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
      dvsMor = folder.createDistributedVirtualSwitch(getTestId(),
               DVSUtil.getvDsVersion());

      // enable netiorm
      Assert.assertTrue(dvs.enableNetworkResourceManagement(dvsMor, true),
               "Netiorm not enabled");

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpEnabled(connectAnchor,
               dvsMor), "NRP not enabled");

      return true;
   }

   /**
    * Test method Enable Netiorm on the dvs
    */
   @Test(description = "Add two or more network resource pools with the same name. Set the keys to different values")
   public void test()
      throws Exception
   {
      // set the values in the config spec
      DVSNetworkResourcePoolConfigSpec nrpConfigSpec1 = NetworkResourcePoolHelper.createDefaultNrpSpec();

      DVSNetworkResourcePoolConfigSpec nrpConfigSpec2 = NetworkResourcePoolHelper.createDefaultNrpSpec();
      // keep the name same but set a different key
      nrpConfigSpec2.setKey("key2");
      nrpConfigSpec2.setName(nrpConfigSpec1.getName());

      // add nrp
      dvs.addNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec1 });

      DVSNetworkResourcePool nrp1 = NetworkResourcePoolHelper.extractNRPByName(
               connectAnchor, dvsMor, nrpConfigSpec1.getName());

      Assert.assertNotNull(nrp1, "First NRP was added successfully",
               "First nrp was not added successfully");

      // Now add the second NRP
      dvs.addNetworkResourcePool(dvsMor,
               new DVSNetworkResourcePoolConfigSpec[] { nrpConfigSpec2 });

   }

   /**
    * Cleanup method Destroy the dvs
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      // delete the dvs
      Assert.assertTrue(dvs.destroy(dvsMor), "DVS destroyed",
               "Unable to destroy DVS");

      return true;
   }

   /**
    * Test Description
    */
   public void setTestDescription()
   {
      setTestDescription("Add two or more network resource pools with the same name. Set the keys to different values");
   }
}
