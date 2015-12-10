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
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import java.util.Vector;

import com.vmware.vc.DistributedVirtualSwitchManagerCompatibilityResult;
import com.vmware.vc.DistributedVirtualSwitchManagerDvsProductSpec;
import com.vmware.vc.DistributedVirtualSwitchManagerHostContainer;
import com.vmware.vc.DistributedVirtualSwitchManagerHostDvsFilterSpec;
import com.vmware.vc.DistributedVirtualSwitchProductSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
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
 * 2.Invoke checkCompatibility method by passing 2 HostDvsFilterSpec values <BR>
 * a) The host array consists of the second host and the inclusive flag <BR>
 * is set to false and switchProductSpec as valid ProductSpec for the<BR>
 * new version of vds<BR>
 * b) The host array consists of the first host and the inclusive <BR>
 * flag is set to false and switchProductSpec as valid ProductSpec<BR>
 * for the new version of vds<BR>
 * CLEANUP<BR>
 */
public class Pos020 extends TestBase implements IDataDrivenTest 
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
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostArrayFilter1 =
            null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostArrayFilter2 =
            null;
   private Vector<ManagedObjectReference> hosts =
            new Vector<ManagedObjectReference>(1);

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
               + "2.Invoke checkCompatibility method by passing 2 "
               + "HostDvsFilterSpec values "
               + "   - The host array consists of the second host "
               + "and the inclusive flag is set   to false and"
               + " switchProductSpec as valid ProductSpec for the "
               + "    new version of vds"
               + "   - The host array consists of the first host"
               + " and the inclusive"
               + "     flag is set to false and switchProductSpec"
               + " as valid ProductSpec  " + "   for the new version of vds ");
   }

   @BeforeMethod(alwaysRun=true)
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
      assertNotNull(allHosts != null && allHosts.length >= 2,
               "Found required number of hosts ",
               "Unable to find required number of hosts");
      /*
       * Create hostFilterSpec here
       */
      hosts.add(allHosts[0]);
      hostArrayFilter1 = DVSUtil.createHostArrayFilter(hosts, false);
      hosts.clear();
      hosts.add(allHosts[1]);
      hostArrayFilter2 = DVSUtil.createHostArrayFilter(hosts, false);
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
      assertNotNull(hostContainer, "created  hosts container",
               "Unable to create hosts container");
      return true;
   }

   @Test(description = "1. Get the compatible hosts for given vDs version\n"
               + "2.Invoke checkCompatibility method by passing 2 "
               + "HostDvsFilterSpec values "
               + "   - The host array consists of the second host "
               + "and the inclusive flag is set   to false and"
               + " switchProductSpec as valid ProductSpec for the "
               + "    new version of vds"
               + "   - The host array consists of the first host"
               + " and the inclusive"
               + "     flag is set to false and switchProductSpec"
               + " as valid ProductSpec  " + "   for the new version of vds ")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchManagerDvsProductSpec spec =
               new DistributedVirtualSwitchManagerDvsProductSpec();
      spec.setDistributedVirtualSwitch(null);
      spec.setNewSwitchProductSpec(productSpec);
      actualCompatibilityResult =
               this.dvsManager.queryCheckCompatibility(dvsManagerMor,
                        this.hostContainer, spec,
                        new DistributedVirtualSwitchManagerHostDvsFilterSpec[] {
                                 hostArrayFilter1, hostArrayFilter2 });
      assertTrue((DVSUtil.verifyCompatibilityResults(
               expectedCompatibilityResult, actualCompatibilityResult)),
               "Unable verify CompatibilityResults");
   }

   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return true;
   }
  


}
