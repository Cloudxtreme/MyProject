/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.createdvs;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;


/**
 * DESCRIPTION:<br>
 * (Test case for ProductSpecOperation ) <br>
 * TARGET: VC <br>
 * SETUP:<br>
 * TEST:<br>>
 * 1.Create DVS by specifying a ProductSpec with given VMware vDS version <br>
 * CLEANUP:<br>
 * 2. Destroy vDs<br>
 */
public class Pos072 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private DVSCreateSpec createSpec = null;
   private DistributedVirtualSwitchProductSpec spec = null;
   private String vDsVersion = null;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("")String dataFile) throws Exception {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }
   public String getTestName()
   {
      return getTestId();
   }
   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create DVS by "
               + "specifying a ProductSpec with given VMware vDS version ");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DVS = new DistributedVirtualSwitch(connectAnchor);
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      spec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      assertNotNull(spec,
               "Successfully obtained  the productSpec for : " + vDsVersion,
               "Null returned for productSpec for :" + vDsVersion);
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), spec,
                        null);
      assertNotNull(createSpec, "DVSCreateSpec is null");
      return true;
   }

   @Test(description = "Create DVS by "
               + "specifying a ProductSpec with given VMware vDS version ")
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
         assertTrue((this.DVS.destroy(dvsMor)),
                  "Successfully deleted DVS", "Unable to delete DVS");
      }
      return true;
   }
   
}
