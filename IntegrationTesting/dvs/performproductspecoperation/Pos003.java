/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.performproductspecoperation;

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
 * <br>
 * SETUP:<br>
 * 1.Create DVS with older vDs version <br>
 * 2.Create new vDs version product spec<BR>
 * TEST:<br>>
 * 3.Invoke perform ProductSpecOperation by passing upgrade operation and new vDs
 * product spec <br>
 * CLEANUP:<br>
 * 4. Destroy vDs<br>
 */
public class Pos003 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;

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

   public void setTestDescription()
   {
      setTestDescription("1.Create DVS with older vDs version \n"
               + " 2.Invoke perform ProductSpecOperation api by "
               + " passing upgrade operation and new vDs product spec");
   }


   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      DVSCreateSpec createSpec = null;
      DVS = new DistributedVirtualSwitch(connectAnchor);
      /*
       * Create DVS with older vDs version
       */
      productSpec =
               DVSUtil.getProductSpec(connectAnchor, this.data
                        .getString(DVSTestConstants.OLD_VDS_VERSION));
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), productSpec, null);
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      productSpec =
               DVSUtil.getProductSpec(connectAnchor, this.data
                        .getString(DVSTestConstants.NEW_VDS_VERSION));
      assertNotNull(productSpec, "Successfully obtained  the productSpec",
               "Null returned for productSpec");
      return true;
   }


   @Test(description = "1.Create DVS with older vDs version \n"
               + " 2.Invoke perform ProductSpecOperation api by "
               + " passing upgrade operation and new vDs product spec")
   public void test()
      throws Exception
   {
      /*
       * Invoke perform ProductSpecOperation api by passing upgrade operation
       * and valid product spec
       */
      log.info("Invoking  ProductSpecOperation..");
      assertTrue(this.DVS.performProductSpecOperation(dvsMor,
               DVSTestConstants.OPERATION_UPGRADE, productSpec),
               " Successfully completed performProductSpecOperation",
               " performProductSpecOperation failed");
      assertTrue(DVSUtil.getUpgradedEvent(dvsMor, connectAnchor),
               " Failed to get DvsUpgradedEvent");
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(dvsMor), "Successfully deleted DVS",
                  "Unable to delete DVS");
      }
      return true;
   }
  


}
