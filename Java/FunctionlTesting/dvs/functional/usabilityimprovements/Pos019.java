/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.functional.usabilityimprovements;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchManagerCompatibilityResult;
import com.vmware.vc.DistributedVirtualSwitchManagerDvsProductSpec;
import com.vmware.vc.DistributedVirtualSwitchManagerHostContainer;
import com.vmware.vc.DistributedVirtualSwitchManagerHostDvsFilterSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * (Test case to verify checkCompatibility api for HostArrayFilter) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1.Get the compatible hosts for given vDs version<BR>
 * TEST:<BR>>
 * 2.Invoke checkCompatibility method by passing the compatible hosts in the
 * host ArrayFilter with inclusive flag set to false and switchProductSpec<BR>
 * as valid ProductSpec for the new DVS<BR>
 * CLEANUP<BR>
 */
public class Pos019 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder folder = null;
   private ManagedObjectReference[] allHosts = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private DistributedVirtualSwitchManagerHostContainer hostContainer = null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult =
            null;
   private String vDsVersion = null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostArrayFilter =
            null;


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
      setTestDescription("1. Get the compatible hosts for given vDs version\n"
               + " 2.Invoke checkCompatibility method by passing the compatible hosts \n"
               + "in the host ArrayFilter with inclusive flag set to true \n"
               + " and switchProductSpec as valid ProductSpec for the new \n"
               + "DVS\n ");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      folder = new Folder(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      allHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      assertNotNull(allHosts, "Found required number of hosts ",
               "Unable to find required number of hosts");
      /*
       * Create hostFilterSpec here
       */
      hostArrayFilter =
               DVSUtil.createHostArrayFilter(TestUtil.arrayToVector(allHosts),
                        false);
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
      assertNotNull(hostContainer, "created  hosts container",
               "Unable to create hosts container");
      return true;
   }

   @Test(description = "1. Get the compatible hosts for given vDs version\n"
               + " 2.Invoke checkCompatibility method by passing the compatible hosts \n"
               + "in the host ArrayFilter with inclusive flag set to true \n"
               + " and switchProductSpec as valid ProductSpec for the new \n"
               + "DVS\n ")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchManagerDvsProductSpec spec =
               new DistributedVirtualSwitchManagerDvsProductSpec();
      spec.setDistributedVirtualSwitch(null);
      spec.setNewSwitchProductSpec(productSpec);
      actualCompatibilityResult =
               this.dvsManager
                        .queryCheckCompatibility(
                                 dvsManagerMor,
                                 this.hostContainer,
                                 spec,
                                 new DistributedVirtualSwitchManagerHostDvsFilterSpec[] { hostArrayFilter });
      assertTrue((DVSUtil.verifyCompatibilityResults(
               expectedCompatibilityResult, actualCompatibilityResult)),
               "Unable verify CompatibilityResults");
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }
 

}
