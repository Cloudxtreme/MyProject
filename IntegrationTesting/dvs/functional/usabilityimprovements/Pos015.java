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
 * 1.Get the compatible hosts for new vDs version<BR>
 * 2.Invoke create dvs with old vds version by adding compatible hosts<BR>
 * TEST:<BR>
 * 3.Invoke checkCompatibility method by passing container as hostfolder,<BR>
 * dvsMembership is set to include host members of the dvSwitch1 and<BR>
 * switchProductSpec as valid ProductSpec of the dvSwitch1<BR>
 * 4.Invoke perform ProductSpecOperation api by passing Upgrade operation <BR>
 * and valid product spec with new vDs version<BR>
 * CLEANUP:<br>
 * 5. Destroy vDs<br>
 */
public class Pos015 extends TestBase implements IDataDrivenTest  
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
   private DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult =
            null;
   private String oldvDsVersion = null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostDvsMembershipFilter =
            null;
   private String newvDsVersion = null;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters( { "dataFile" })
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
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
               + " 2.Invoke create dvs with new spec by adding compatible hosts\n"
               + " 3.Invoke checkCompatibility method by passing container as "
               + "hostfolder, dvsMembership is set to include host members of"
               + " the dvSwitch1  *  and switchProductSpec as valid "
               + "ProductSpec of the dvSwitch1\n"
               + " 4.Invoke perform ProductSpecOperation api by passing "
               + " Upgrade operation and  valid  product spec "
               + "(with new vDs version)");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      folder = new Folder(connectAnchor);
      DVS = new DistributedVirtualSwitch(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      oldvDsVersion =  this.data.getString(DVSTestConstants.OLD_VDS_VERSION);
      newvDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, newvDsVersion);
      allHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      assertNotNull(allHosts, "Found required number of hosts ",
               "Unable to find required number of hosts");
      this.dvsMor =
               folder.createDistributedVirtualSwitch(TestUtil.getShortTime(),
                        oldvDsVersion, this.allHosts);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      /*
       * Create expected CompatibilityResult here
       */
      expectedCompatibilityResult =
               new DistributedVirtualSwitchManagerCompatibilityResult[allHosts.length];
      for (int i = 0; i < allHosts.length; i++) {
         expectedCompatibilityResult[i] =
                  new DistributedVirtualSwitchManagerCompatibilityResult();
         expectedCompatibilityResult[i].setHost(allHosts[i]);
         expectedCompatibilityResult[i].getError().clear();
      }
      /*
       * Create hostFilterSpec here
       */
      hostDvsMembershipFilter =
               DVSUtil.createHostDvsMembershipFilter(this.dvsMor, true);
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
      assertNotNull(hostContainer, "created  hosts container",
               "Unable to create hosts container");
      return true;
   }

   @Test(description = "1. Get the compatible hosts for given vDs version\n"
               + " 2.Invoke create dvs with new spec by adding compatible hosts\n"
               + " 3.Invoke checkCompatibility method by passing container as "
               + "hostfolder, dvsMembership is set to include host members of"
               + " the dvSwitch1  *  and switchProductSpec as valid "
               + "ProductSpec of the dvSwitch1\n"
               + " 4.Invoke perform ProductSpecOperation api by passing "
               + " Upgrade operation and  valid  product spec "
               + "(with new vDs version)")
   public void test()
      throws Exception
   {
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
      assertTrue((DVSUtil.verifyCompatibilityResults(
               expectedCompatibilityResult, actualCompatibilityResult)),
               "Unable verify CompatibilityResults");
      productSpec = DVSUtil.getProductSpec(connectAnchor, newvDsVersion);
      assertTrue(this.DVS.performProductSpecOperation(dvsMor,
               DVSTestConstants.OPERATION_UPGRADE, productSpec),
               " Successfully completed performProductSpecOperation",
               " performProductSpecOperation failed");

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
