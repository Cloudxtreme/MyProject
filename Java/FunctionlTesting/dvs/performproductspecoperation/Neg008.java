/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.performproductspecoperation;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertFalse;
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
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * (Test case for downgrading VMware Dvs from new vDs version to old vDs version
 * ) <br>
 * TARGET: VC <br>
 * <br>
 * SETUP:<br>
 * 1.Create DVS with new vDs version <br>
 * TEST:<br>>
 * 2.Invoke perform ProductSpecOperation by passing upgrade operation and old
 * vDs product spec <br>
 * CLEANUP:<br>
 * 3. Destroy vDs<br>
 */
public class Neg008 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private String oldVdsVersion = null;
   private String newVdsVersion = null;

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
      setTestDescription("1. Create DVS with new vDs version\n"
               + " 2. Invoke perform ProductSpecOperation api by passing "
               + "upgrade operation and old vDs version in the product spec. ");
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
      oldVdsVersion = this.data.getString(DVSTestConstants.OLD_VDS_VERSION);
      newVdsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, newVdsVersion);
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), productSpec, null);
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      productSpec = DVSUtil.getProductSpec(connectAnchor, oldVdsVersion);
      assertNotNull(productSpec, "Successfully created  the productSpec",
               "Null returned for productSpec");
      return true;
   }

   @Test(description = "1. Create DVS with new vDs version\n"
               + " 2. Invoke perform ProductSpecOperation api by passing "
               + "upgrade operation and old vDs version in the product spec. ")
   public void test()
      throws Exception
   {
      try {
         assertFalse(this.DVS.performProductSpecOperation(
                  dvsMor, DVSTestConstants.OPERATION_UPGRADE, productSpec),
                  " performProductSpecOperation failed",
                  " Successfully completed performProductSpecOperation");
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
         assertTrue((this.DVS.destroy(dvsMor)),
                  "Successfully deleted DVS", "Unable to delete DVS");
      }
      return true;
   }
   


}
