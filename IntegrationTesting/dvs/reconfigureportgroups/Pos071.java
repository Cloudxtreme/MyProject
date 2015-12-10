/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DVSNetworkResourcePoolConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Associate/Disassociate a newly created nrp with multiple
 * dvPortgroup<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS<BR>
 * 2. Enable netiorm <BR>
 * 3. Add a nrp to it<BR>
 * 4. Create multiple dv portgroup<BR>
 * TEST:<BR>
 * 5. Reconfigure multiple portgroup on the dvs with nrp associated to it<BR>
 * 6. Verify that the portgroup is associated with the nrp<BR>
 * CLEANUP:<BR>
 * 7. Destroy the dvs<BR>
 */
public class Pos071 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup dvpg;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVSNetworkResourcePoolConfigSpec nrpConfigSpec;
   private DVPortgroupConfigSpec[] dvpgSpec;
   private List<ManagedObjectReference> pgMors;
   // add 5 portgroups to the dvs
   private static int portgroupCount = 5;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder ifolder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      // add 5 portgroups
      dvpgSpec = new DVPortgroupConfigSpec[portgroupCount];
      dvpg = new DistributedVirtualPortgroup(connectAnchor);

      // create the dvs
      dvsMor = ifolder.createDistributedVirtualSwitch(
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

      Assert.assertTrue(NetworkResourcePoolHelper.verifyNrpFromDvs(
               connectAnchor, dvsMor, nrpConfigSpec), "NRP verified from dvs",
               "NRP not matching with DVS nrp");

      nrp = NetworkResourcePoolHelper.extractNRPByName(connectAnchor, dvsMor,
               nrpConfigSpec.getName());
      
      // create the spec
      for (int i = 0; i < dvpgSpec.length; i++) {
         dvpgSpec[i] = NetworkResourcePoolHelper.createDvpgSpec(connectAnchor, getTestId() + i, dvsMor);
      }

      pgMors = dvs.addPortGroups(dvsMor, dvpgSpec);
      Assert.assertNotEmpty(pgMors, "Portgroups added successfully",
               "Portgroups could not be added");

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Associate/Disassociate a newly created nrp with multiple dvPortgroup")
   public void test()
      throws Exception
   {
      NetworkResourcePoolHelper.associateNrpToDvpgSpec(dvpgSpec, nrp);

      for (int i = 0; i < dvpgSpec.length; i++) {
         DVPortgroupConfigInfo dvpgconfigInfo = dvpg.getConfigInfo(pgMors.get(i));
         dvpgSpec[i].setConfigVersion(dvpgconfigInfo.getConfigVersion());
         Assert.assertTrue(dvpg.reconfigure(pgMors.get(i), dvpgSpec[i]),
                  "Successfully reconfigured dvpg" + i + " with nrp attached",
                  "Unable to reconfigure dvpg" + i + " with nrp attached");
      }

      Assert.assertTrue(NetworkResourcePoolHelper.isNrpAssociatedToDvpg(
               connectAnchor, pgMors, nrp.getKey()),
               "Verfied nrp is attached to dvpg",
               "Unable to verify nrp attached to dvpg");
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
      setTestDescription("Associate/Disassociate a newly created nrp with multiple dvPortgroup");
   }

}
