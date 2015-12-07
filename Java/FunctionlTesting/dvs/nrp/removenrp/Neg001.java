/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.nrp.removenrp;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSNetworkResourcePool;
import com.vmware.vc.DvsFault;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkResourcePoolHelper;

/**
 * DESCRIPTION:Remove a pre-defined nrp (fcoe, nfs etc.)<BR>
 * TARGET:VC<BR>
 * SETUP:<BR>
 * 1.create the dvs<BR>
 * 2.enable netiorm<BR>
 * 3.Extract the network resource pool related to fcoe from the dvs<BR>
 * TEST:<BR>
 * 4.Delete the nrp<BR>
 * CLEANUP:<BR>
 * 5.Destroy the dvs<BR>
 */
public class Neg001 extends TestBase
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
   @Test(description = "Remove a pre-defined nrp")
   public void test()
      throws Exception
   {
      try {
         // Extract the network resource pool related to the vm from the dvs
         DVSNetworkResourcePool nrp = dvs.extractNetworkResourcePool(dvsMor,
                  DVSTestConstants.NRP_FT);
         dvs.removeNetworkResourcePool(dvsMor, new String[] { nrp.getKey() });
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
      setTestDescription("Remove a pre-defined nrp");
   }

   /**
    * Set the expected exception
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new DvsFault();
   }
}
