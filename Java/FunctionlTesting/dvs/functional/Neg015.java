/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.functional;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import com.vmware.vc.DistributedVirtualSwitchManagerDvsProductSpec;
import com.vmware.vc.DistributedVirtualSwitchManagerHostContainer;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * TARGET: VC <BR>
 * SETUP:<BR>
 * TEST:<BR>>
 * 1.Invoke checkCompatibility method by passing the datacenter mor as
 * container,  recursive flag set to false, inclusive flag set to true <BR>
 * and switchProductSpec as invalid ProductSpec <BR>
 * CLEANUP:<BR>
 */
public class Neg015 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager DVS = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder folder = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private DistributedVirtualSwitchManagerHostContainer hostContainer = null;
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
      setTestDescription("1. Invoke checkCompatibility method by passing"
               + " the datacenter mor as container,"
               + " recursive flag set to false,"
               + " inclusive flag set to true and "
               + "switchProductSpec as invalid ProductSpec ");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      DVS = new DistributedVirtualSwitchManager(
               connectAnchor);
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      folder = new Folder(connectAnchor);
      dvsManagerMor = DVS.getDvSwitchManager();
      productSpec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      productSpec.setVersion("0.0");
      /*
       * Create hostFilterSpec here
       */
      hostContainer = DVSUtil.createHostContainer(this.folder.getRootFolder(),
               false);
      assertNotNull(hostContainer, "hostFilterSpec is null");
      return true;
   }

   @Test(description = "1. Invoke checkCompatibility method by passing"
               + " the datacenter mor as container,"
               + " recursive flag set to false,"
               + " inclusive flag set to true and "
               + "switchProductSpec as invalid ProductSpec ")
   public void test()
      throws Exception
   {
      try {
         DistributedVirtualSwitchManagerDvsProductSpec spec = new DistributedVirtualSwitchManagerDvsProductSpec();
         spec.setDistributedVirtualSwitch(null);
         spec.setNewSwitchProductSpec(productSpec);
         this.DVS.queryCheckCompatibility(
                  dvsManagerMor, hostContainer, spec, null);
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
      return true;
   }
   


}
