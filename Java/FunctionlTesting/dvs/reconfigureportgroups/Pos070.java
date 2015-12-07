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
 * DESCRIPTION:Associate/Disassociate a predefined nrp with a dvPortgroup<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS<BR>
 * 2. Enable netiorm <BR>
 * 3. Add a nrp to it<BR>
 * 4. Create the dv portgroup<BR>
 * TEST:<BR>
 * 5. Reconfigure a portgroup on the dvs with nrp associated to it<BR>
 * 6. Verify that the portgroup is associated with the nrp<BR>
 * CLEANUP:<BR>
 * 7. Destroy the dvs<BR>
 */
public class Pos070 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup dvpg;
   private ManagedObjectReference dvsMor;
   private DVSNetworkResourcePool nrp;
   private DVPortgroupConfigSpec[] dvpgSpec;
   private List<ManagedObjectReference> pgMors;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      Folder ifolder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      dvpg = new DistributedVirtualPortgroup(connectAnchor);
      dvpgSpec = new DVPortgroupConfigSpec[1];

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

      // Get a pre-defined nrp of virtualMachine type
      nrp = dvs.extractNetworkResourcePool(dvsMor,DVSTestConstants.NRP_VMOTION);

      Assert.assertNotNull(nrp, "Nrp is null");
      
      // create the spec
      dvpgSpec[0] = NetworkResourcePoolHelper.createDvpgSpec(connectAnchor, getTestId(), dvsMor);

      pgMors = dvs.addPortGroups(dvsMor, dvpgSpec);
      Assert.assertNotEmpty(pgMors, "Portgroup added successfully",
               "Portgroup could not be added");

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Associate/Disassociate a pre-defined nrp with a dvPortgroup")
   public void test()
      throws Exception
   {
      DVPortgroupConfigInfo dvpgconfigInfo = dvpg.getConfigInfo(pgMors.get(0));
      dvpgSpec[0].setConfigVersion(dvpgconfigInfo.getConfigVersion());
      
      NetworkResourcePoolHelper.associateNrpToDvpgSpec(dvpgSpec, nrp);
      Assert.assertTrue(dvpg.reconfigure(pgMors.get(0), dvpgSpec[0]),
               "Successfully reconfigured dvpg with nrp attached",
               "Unable to reconfigure dvpg with nrp attached");
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
      setTestDescription("Associate/Disassociate a pre-defined nrp with a dvPortgroup");
   }

}
