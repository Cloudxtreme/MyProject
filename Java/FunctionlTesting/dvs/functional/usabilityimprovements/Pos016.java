/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.functional.usabilityimprovements;

import com.vmware.vcqa.IDataDrivenTest;
import static com.vmware.vcqa.util.Assert.assertFalse;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

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
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;

/**
 * DESCRIPTION:<BR>
 * (Test case to verify checkCompatibility for create-dvs(with given vDS
 * version)<BR>
 * dvs situation) <BR>
 * TARGET: VC <BR>
 * <BR>
 * SETUP:<BR>
 * 1.Get all hosts( compatible + incompatible for given vds version) from
 * datacenter<BR>
 * 2.queryCompatibleHostForNewDVS and create dvs ( dvSwitch1) with given vDs<BR>
 * version and add CompatibleHosts to it <BR>
 * TEST:<BR>
 * 3.Invoke checkCompatibility method by passing container as hostfolder,<BR>
 * dvsMembership is set to include host members of the dvSwitch1 and<BR>
 * switchProductSpec as valid ProductSpec(for new VDs Version) of the dvSwitch1<BR>
 * 4.Invoke perform ProductSpecOperation api by passing Upgrade operation and<BR>
 * valid product spec (with new vDs version))<BR>
 * CLEANUP:<BR>
 * 5. Destroy vDs<BR>
 */
public class Pos016 extends TestBase implements IDataDrivenTest 
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitchManager dvsManager = null;
   private DistributedVirtualSwitch DVS = null;
   private ManagedObjectReference dvsManagerMor = null;
   private Folder folder = null;
   private HostSystem hostSystem = null;
   private Vector<ManagedObjectReference> allHosts =
            new Vector<ManagedObjectReference>();
   private Vector<ManagedObjectReference> allTempHosts =
            new Vector<ManagedObjectReference>();
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchManagerHostContainer hostContainer = null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult =
            null;
   private ManagedObjectReference compatibleHosts[] = null;
   private DistributedVirtualSwitchManagerHostDvsFilterSpec hostDvsMembershipFilter =
            null;
   private String oldvDsVersion = null;
   private String newvDsVersion = null;

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
      setTestDescription("Test case to verify  for  checkCompatibility api for"
               + " add-host-to-dvs (new vDs version ) usecase\n"
               + "1.Get all  hosts(ompatible + incompatible  for given vds version)"
               + " from  datacenter\n"
               + "2. queryCompatibleHostForNewDVS and create dvs ( dvSwitch1)"
               + "  with given  vDs version and add compatibleHosts to it."
               + " datacenter "
               + " 3.Invoke checkCompatibility method by passing container as "
               + "hostfolder, dvsMembership is set to include host members of"
               + " the dvSwitch1  and switchProductSpec as valid "
               + "ProductSpec(for new VDs Version) of the dvSwitch1\n"
               + " 4.Invoke perform ProductSpecOperation api by passing "
               + "proceedWithUpgrade operation and  valid  product spec "
               + "(with new vDs version)");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {

      dvsManager = new DistributedVirtualSwitchManager(connectAnchor);
      folder = new Folder(connectAnchor);
      DVS = new DistributedVirtualSwitch(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      dvsManagerMor = dvsManager.getDvSwitchManager();
      oldvDsVersion = this.data.getString(DVSTestConstants.OLD_VDS_VERSION);
      newvDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, oldvDsVersion);
      compatibleHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      assertNotNull(allHosts, "Found required number of hosts ",
               "Unable to find required number of hosts");
      allHosts = TestUtil.arrayToVector(compatibleHosts);
      productSpec = DVSUtil.getProductSpec(connectAnchor, newvDsVersion);
      compatibleHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);

      allTempHosts = TestUtil.arrayToVector(compatibleHosts);
      assertTrue((allTempHosts != null && allTempHosts.size() > 0),
               MessageConstants.HOST_GET_PASS, MessageConstants.HOST_GET_FAIL);
      allHosts.removeAll(allTempHosts);
      this.dvsMor =
               folder.createDistributedVirtualSwitch(this.getTestId(),
                        oldvDsVersion, TestUtil.vectorToArray(allHosts));
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      expectedCompatibilityResult =
               new DistributedVirtualSwitchManagerCompatibilityResult[allTempHosts
                        .size()];
      for (int i = 0; i < allTempHosts.size(); i++) {
         expectedCompatibilityResult[i] =
                  new DistributedVirtualSwitchManagerCompatibilityResult();
         expectedCompatibilityResult[i].setHost(allTempHosts.get(i));
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

   @Test(description = "Test case to verify  for  checkCompatibility api for"
               + " add-host-to-dvs (new vDs version ) usecase\n"
               + "1.Get all  hosts(ompatible + incompatible  for given vds version)"
               + " from  datacenter\n"
               + "2. queryCompatibleHostForNewDVS and create dvs ( dvSwitch1)"
               + "  with given  vDs version and add compatibleHosts to it."
               + " datacenter "
               + " 3.Invoke checkCompatibility method by passing container as "
               + "hostfolder, dvsMembership is set to include host members of"
               + " the dvSwitch1  and switchProductSpec as valid "
               + "ProductSpec(for new VDs Version) of the dvSwitch1\n"
               + " 4.Invoke perform ProductSpecOperation api by passing "
               + "proceedWithUpgrade operation and  valid  product spec "
               + "(with new vDs version)")
   public void test()
      throws Exception
   {
      try {
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
         assertTrue(DVSUtil.verifyCompatibilityResults(
                  expectedCompatibilityResult, actualCompatibilityResult),
                  "Unable verify CompatibilityResults");
         productSpec = DVSUtil.getProductSpec(connectAnchor, newvDsVersion);
         assertFalse(this.DVS.performProductSpecOperation(dvsMor,
                  DVSTestConstants.OPERATION_UPGRADE, productSpec),
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
         assertTrue(this.DVS.destroy(this.dvsMor),
                  "dvsMor destroyed successfully",
                  "dvsMor could not be removed");
      }
      return true;
   }
   


}
