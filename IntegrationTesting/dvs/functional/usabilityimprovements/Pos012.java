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
import java.util.List;
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
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * (Test Case to verify checkCompatibility api for for add-host-to-dvs<BR>
 * (given vDs version ) use cas) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1.Get the compatible hosts for given vDs version<BR>
 * 2.create dvs ( dvSwitch1) with given vDs version and add one of the <BR>
 * compatible hosts to it<BR>
 * TEST:<BR>>
 * 3.Invoke checkCompatibility method by passing container as hostfolder,<BR>
 * dvsMembership is set to exclude host members of the dvSwitch1<BR>
 * and switchProductSpec as valid ProductSpec of the dvSwitch1s<BR>
 * 4.Invoke reconfiguredvs by adding hosts returned by checkCompatibility method<BR>
 * CLEANUP:<br>
 * 5. Destroy vDs<br>
 */
public class Pos012 extends TestBase implements IDataDrivenTest 
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
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchManagerHostContainer hostContainer = null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult =
            null;
   private String vDsVersion = null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostDvsMembershipFilter =
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
      setTestDescription("Test case to verify  for  checkCompatibility api"
               + " for add-host-to-dvs (given vDs version ) use case"
               + " 1.Get compatible hosts from datacenter\n"
               + " 2.create dvs ( dvSwitch1)  with given  vDs version and add"
               + " one of the compatible hosts  to it.\n"
               + " 3.Invoke checkCompatibility method by"
               + " passing container as hostfolder, dvsMembership is set to "
               + "exclude host members of the dvSwitch1 \n"
               + "and switchProductSpec as valid ProductSpec of the dvSwitch1"
               + " 4.Invoke reconfiguredvs by adding hosts  returned by "
               + "checkCompatibility method\n");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      folder = new Folder(connectAnchor);
      DVS = new DistributedVirtualSwitch(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      allHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      assertNotNull(allHosts, "Found required number of hosts ",
               "Unable to find required number of hosts");

      /*
       * Create expected CompatibilityResult here
       */
      hostMor = allHosts[0];
      this.dvsMor =
               folder.createDistributedVirtualSwitch(this.getTestId(), vDsVersion,hostMor);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      expectedCompatibilityResult =
               new DistributedVirtualSwitchManagerCompatibilityResult[allHosts.length - 1];
      for (int i = 1; i < expectedCompatibilityResult.length; i++) {
         expectedCompatibilityResult[i] =
                  new DistributedVirtualSwitchManagerCompatibilityResult();
         expectedCompatibilityResult[i].setHost(allHosts[i]);
         expectedCompatibilityResult[i].getError().clear();
      }

      /*
       * Create hostFilterSpec here
       */
      hostDvsMembershipFilter =
               DVSUtil.createHostDvsMembershipFilter(this.dvsMor, false);
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
      assertNotNull(hostContainer, "created  hosts container",
               "Unable to create hosts container");
      return true;
   }

   @Test(description = "Test case to verify  for  checkCompatibility api"
               + " for add-host-to-dvs (given vDs version ) use case"
               + " 1.Get compatible hosts from datacenter\n"
               + " 2.create dvs ( dvSwitch1)  with given  vDs version and add"
               + " one of the compatible hosts  to it.\n"
               + " 3.Invoke checkCompatibility method by"
               + " passing container as hostfolder, dvsMembership is set to "
               + "exclude host members of the dvSwitch1 \n"
               + "and switchProductSpec as valid ProductSpec of the dvSwitch1"
               + " 4.Invoke reconfiguredvs by adding hosts  returned by "
               + "checkCompatibility method\n")
   public void test()
      throws Exception
   {
      boolean testDone = false;
      List<ManagedObjectReference> hostMors =
               new Vector<ManagedObjectReference>();
      DistributedVirtualSwitchManagerDvsProductSpec spec =
               new DistributedVirtualSwitchManagerDvsProductSpec();
      spec.setDistributedVirtualSwitch(this.dvsMor);
      spec.setNewSwitchProductSpec(null);
      actualCompatibilityResult =
               this.dvsManager
                        .queryCheckCompatibility(
                                 dvsManagerMor,
                                 this.hostContainer,
                                 spec,
                                 new DistributedVirtualSwitchManagerHostDvsFilterSpec[] { hostDvsMembershipFilter });
      assertTrue(DVSUtil.verifyHostsInCompatibilityResults(connectAnchor,
               actualCompatibilityResult, expectedCompatibilityResult, TestUtil
                        .arrayToVector(this.allHosts), null),
               "Unable to  verify the CompatibilityResults");
      /*
       * Reconfigure DVS here
       */
      hostMors.addAll(TestUtil.arrayToVector(this.allHosts));
      hostMors.remove(hostMor);
      testDone =
               DVSUtil.addHostsUsingReconfigureDVS(this.dvsMor, hostMors,
                        connectAnchor);
      assertTrue(testDone, "Failed to add host to DVS");

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
