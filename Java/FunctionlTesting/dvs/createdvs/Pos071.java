/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
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
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * (Test case for ProductSpecOperation ) <br>
 * TARGET: VC <br>
 * SETUP:<br>
 * TEST:<br>>
 * 1.Create DVS without specifying a ProductSpec <br>
 * CLEANUP:<br>
 * 2.Destroy DVS<br>
 */
public class Pos071 extends TestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private DVSCreateSpec createSpec = null;
   private String vDsVersion = DVSTestConstants.VDS_VERSION_DEFAULT;

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create DVS without specifying a ProductSpec");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DVS = new DistributedVirtualSwitch(connectAnchor);
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), null, null);
      assertNotNull(createSpec, "DVSCreateSpec is null");
      return true;
   }

   @Test(description = "Create DVS without specifying a ProductSpec")
   public void test()
      throws Exception
   {
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      assertTrue(DVSUtil
               .verifyDVSProductSpec(connectAnchor, dvsMor, vDsVersion),
               "Failed to ProductSpec :" + vDsVersion);
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
