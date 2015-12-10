/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * TEST:<BR>>
 * 1.Create a vDs with invalid vDs version in product spec <BR>
 * CLEANUP:<BR>
 */
public class Neg055 extends TestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a vDs with invalid vDs version in product spec ");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DVS = new DistributedVirtualSwitch(connectAnchor);
      productSpec =
               DVSUtil.getProductSpec(connectAnchor,
                        DVSTestConstants.VDS_VERSION_DEFAULT);
      productSpec =
               DVSUtil.createProductSpec(productSpec.getName(), productSpec
                        .getVendor(), "0.0", null, null, null, null);
      assertNotNull(productSpec, "Successfully created  the productSpec",
               "Null returned for productSpec");
      return true;
   }

   @Test(description = "Create a vDs with invalid vDs version in product spec ")
   public void test()
      throws Exception
   {
      try {
         DVSCreateSpec createSpec = null;
         createSpec =
                  DVSUtil.createDVSCreateSpec(DVSUtil
                           .createDefaultDVSConfigSpec(null), productSpec, null);
         dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
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
    * Setting the expected Exception.
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new InvalidArgument();
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue((this.DVS.destroy(dvsMor)), "Successfully deleted DVS",
                  "Unable to delete DVS");
      }

      return true;
   }
}
