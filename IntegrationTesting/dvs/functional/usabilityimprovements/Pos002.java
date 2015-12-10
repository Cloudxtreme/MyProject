/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.functional.usabilityimprovements;

import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
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
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * (Test Case to verify checkCompatibility api for three specs that contain<BR>
 * HostArrayFilter, HostContainerFilter, HostDvsMembershipFilter) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1.Get the compatible hosts for given vDs version<BR>
 * 2.Add a vds containing the first host<BR>
 * TEST:<BR>>
 * 3.Invoke checkCompatibility method by passing the following three specs<BR>
 * - Host array consists of both the hosts<BR>
 * - HostContainerFilter consists of the datacenter mor as container,<BR>
 * recursive flag set to true, inclusive flag set to true and <BR>
 * switchProductSpec as valid ProductSpec.<BR>
 * - HostDvsMembershipFilter consists of the dvs mor of the vds<BR>
 * CLEANUP:<br>
 * 4. Destroy vDs<br>
 */
public class Pos002 extends TestBase implements IDataDrivenTest
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager = null;
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder folder = null;
   private ManagedObjectReference[] allHosts = null;
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchManagerHostContainer hostContainer = null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostContainerFilter =
            null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostArrayFilter =
            null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec membershipFilter =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult =
            null;
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

   public void setTestDescription()
   {
      setTestDescription("Test Case to verify checkCompatibility api "
               + "for three specs that"
               + " contain HostArrayFilter, HostContainerFilter, "
               + "HostDvsMembershipFilter\n"
               + " 1. Get the compatible hosts for given vDs version\n"
               + " 2. Add a vds containing the first host\n"
               + " 3. Invoke checkCompatibility method by passing "
               + "the following three specs :\n"
               + " - Host array consists of both the hosts\n"
               + "   - HostContainerFilter consists of the datacenter"
               + " mor as container,"
               + "   recursive flag set to true, inclusive flag set to true"
               + " and switchProductSpec as valid ProductSpec\n"
               + "  - HostDvsMembershipFilter consists of the dvs mor"
               + " of the vds");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      folder = new Folder(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      DVS = new DistributedVirtualSwitch(connectAnchor);
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      allHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      assertNotNull(allHosts, "Found required number of hosts ",
               "Unable to find required number of hosts");



      this.dvsMor =
               folder.createDistributedVirtualSwitch(this.getTestId(),
                        vDsVersion, allHosts[0]);
      hostArrayFilter =
               DVSUtil.createHostArrayFilter(TestUtil
                        .arrayToVector(this.allHosts), true);
      /*
       * Create hostFilterSpec here
       */
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
      hostContainerFilter =
               DVSUtil.createHostContainerFilter(hostContainer, true);
      this.membershipFilter =
               DVSUtil.createHostDvsMembershipFilter(this.dvsMor, false);
      assertNotNull(this.membershipFilter, "created  HostDvsMembershipFilter",
      "Unable to create HostDvsMembershipFilter");
      return true;
   }

   @Test(description = "Test Case to verify checkCompatibility api "
               + "for three specs that"
               + " contain HostArrayFilter, HostContainerFilter, "
               + "HostDvsMembershipFilter\n"
               + " 1. Get the compatible hosts for given vDs version\n"
               + " 2. Add a vds containing the first host\n"
               + " 3. Invoke checkCompatibility method by passing "
               + "the following three specs :\n"
               + " - Host array consists of both the hosts\n"
               + "   - HostContainerFilter consists of the datacenter"
               + " mor as container,"
               + "   recursive flag set to true, inclusive flag set to true"
               + " and switchProductSpec as valid ProductSpec\n"
               + "  - HostDvsMembershipFilter consists of the dvs mor"
               + " of the vds")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchManagerDvsProductSpec spec =
               new DistributedVirtualSwitchManagerDvsProductSpec();
      spec.setDistributedVirtualSwitch(null);
      spec.setNewSwitchProductSpec(productSpec);
      actualCompatibilityResult =
               this.dvsManager.queryCheckCompatibility(dvsManagerMor,
                        hostContainer, spec,
                        new DistributedVirtualSwitchManagerHostDvsFilterSpec[] {
                                 hostContainerFilter, hostArrayFilter,
                                 membershipFilter });
      assertTrue((DVSUtil.verifyCompatibilityResults(
               expectedCompatibilityResult, actualCompatibilityResult)),
               "Test Failed");
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if (this.dvsMor != null) {
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "dvsMor destroyed successfully",
                  "dvsMor could not be removed");
      }
      return true;
   }





}
