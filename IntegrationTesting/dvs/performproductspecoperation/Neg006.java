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
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotSupported;
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
 * 1.Create two DVSs source and destination with older vDs version <br>
 * 2.Create new vDs version product spec<BR>
 * TEST:<br>>
 * 3.Invoke perform ProductSpecOperation on destination DVS <BR>
 * 4.Merge both source and destination DVS.<BR>
 * CLEANUP:<br>
 * 5. Destroy vDs<br>
 */
public class Neg006 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference srcDVSMor = null;;
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

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("1. Create two DVSs source and destination with "
               + "older vDs version\n"
               + " 2. Invoke perform ProductSpecOperation on destination DVS.\n"
               + " 3. Merge both source and destination DVS");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp() throws Exception
   {
      DVSCreateSpec createSpec = null;
      DVS = new DistributedVirtualSwitch(connectAnchor);
      /*
       * Create DVS with older vDs version
       */
      oldVdsVersion = this.data.getString(DVSTestConstants.OLD_VDS_VERSION);
      newVdsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, oldVdsVersion);
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), productSpec, null);
      dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      createSpec =
               DVSUtil.createDVSCreateSpec(DVSUtil
                        .createDefaultDVSConfigSpec(null), productSpec, null);
      srcDVSMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
      assertNotNull(srcDVSMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      productSpec = DVSUtil.getProductSpec(connectAnchor, newVdsVersion);
      assertNotNull(productSpec, "Successfully created  the productSpec",
               "Null returned for productSpec");
      return true;
   }

   @Test(description = "1. Create two DVSs source and destination with "
               + "older vDs version\n"
               + " 2. Invoke perform ProductSpecOperation on destination DVS.\n"
               + " 3. Merge both source and destination DVS")
   public void test()
   throws Exception
   {
      try {
         assertTrue(this.DVS.performProductSpecOperation(
                  dvsMor, DVSTestConstants.OPERATION_UPGRADE, productSpec),
                  " performProductSpecOperation failed",
         " Successfully completed performProductSpecOperation");
         assertTrue((this.DVS.merge(dvsMor, srcDVSMor)),
                  "Successfully merged the switches but the API "
                  + "did not throw an exception",
                  "Failed to merge the switches but the API "
                  + "did not throw an exception");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NotSupported();
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
      return new NotSupported();
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
   throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue((this.DVS.destroy(dvsMor)),
                  "Successfully deleted DVS", "Unable to delete DVS");
      }
      if (this.srcDVSMor != null
               && this.DVS.isExists(this.srcDVSMor)) {
         assertTrue((this.DVS.destroy(srcDVSMor)),
                  "Successfully deleted DVS", "Unable to delete srcDVSMor");

      }
      return true;
   }
  

}
