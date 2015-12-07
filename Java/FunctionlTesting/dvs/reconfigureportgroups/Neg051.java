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
import com.vmware.vc.DvsFault;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.StringPolicy;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Reconfigure a dvPortgroup with an non existent nrp key associated
 * to it<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * 1. Create a vDS <BR>
 * 2. Enable netiorm <BR>
 * 3. Create the dv portgroup spec with one port<BR>
 * TEST:<BR>
 * 4. Add portgroups on the dvs with non existent nrp associated to it<BR>
 * CLEANUP:<BR>
 * 5. Destroy the dvs<BR>
 */
public class Neg051 extends TestBase
{
   private DistributedVirtualSwitch dvs;
   private DistributedVirtualPortgroup dvpg;
   private Folder ifolder;
   private ManagedObjectReference dvsMor;
   private DVPortgroupConfigSpec dvpgSpec;
   private List<ManagedObjectReference> pgMors;

   /**
    * Setup method Setup the dvs and attach a host to it.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      ifolder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
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

      // create the default spec with one port and associate a non existent nrp
      // key to it
      dvpgSpec = NetworkResourcePoolHelper.createDvpgSpec(connectAnchor, getTestId(), dvsMor);
      // Add the nrp to the dvpg
      pgMors = dvs.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvpgSpec });

      return true;
   }

   /**
    * Test method
    */
   @Test(description = "Reconfigure a dvPortgroup to associate a invalid non existent nrp ")
   public void test()
      throws Exception
   {
      try {
         DVPortgroupConfigInfo dvpgconfigInfo = dvpg.getConfigInfo(pgMors.get(0));
         dvpgSpec.setConfigVersion(dvpgconfigInfo.getConfigVersion());
         StringPolicy nrpKey = new StringPolicy();
         nrpKey.setValue(DVSTestConstants.NRP_INVALID_KEY);
         dvpgSpec.getDefaultPortConfig().setNetworkResourcePoolKey(nrpKey);
         dvpg.reconfigure(pgMors.get(0), dvpgSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
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
      setTestDescription("Reconfigure a dvPortgroup to associate a invalid non existent nrp ");
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new DvsFault();
   }

}
