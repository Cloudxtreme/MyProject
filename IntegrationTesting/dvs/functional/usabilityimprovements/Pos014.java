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
 * 2.queryCompatibleHostForNewDVS and create dvs ( dvSwitch1) with given vDs
 * version and add both CompatibleHost to it. datacenter<BR>
 * TEST:<BR>>
 * 3.Invoke checkCompatibility method by passing container as datacenter,<BR>
 * dvsMembership is set to exclude host members of the dvSwitch1 and<BR>
 * switchProductSpec as valid ProductSpec of the dvSwitch1.<BR>
 * CLEANUP:<BR>
 * 5. Destroy vDs<BR>
 */
public class Pos014 extends TestBase implements IDataDrivenTest 
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
   private DistributedVirtualSwitchProductSpec productSpec = null;
   private ManagedObjectReference dvsMor = null;
   private DistributedVirtualSwitchManagerHostContainer hostContainer = null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] expectedCompatibilityResult =
            null;
   private DistributedVirtualSwitchManagerCompatibilityResult[] actualCompatibilityResult =
            null;
   private ManagedObjectReference hostFolder = null;
   private String vDsVersion = null;
   private Vector<MethodFault> faults = new Vector<MethodFault>();
   private ManagedObjectReference compatibleHosts[] = null;
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
      setTestDescription("Test case to verify  for  checkCompatibility api for"
               + " add-host-to-dvs (new vDs version ) usecase\n"
               + "1.Get all  hosts(ompatible + incompatible  for given vds version) from  datacenter\n"
               + "2. queryCompatibleHostForNewDVS and create dvs ( dvSwitch1)  with given  vDs version and add both CompatibleHost to it."
               + " datacenter "
               + "3.Invoke checkCompatibility method by passing container"
               + " as datacenter,dvsMembership is set to exclude host"
               + " members of the dvSwitch1 and switchProductSpec as"
               + " valid ProductSpec of the dvSwitch1.");
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
      vDsVersion = this.data.getString(DVSTestConstants.NEW_VDS_VERSION);
      productSpec = DVSUtil.getProductSpec(connectAnchor, vDsVersion);
      assertNotNull(productSpec,
               "Successfully obtained  the productSpec for : " + vDsVersion,
               "Null returned for productSpec for :" + vDsVersion);
      compatibleHosts =
               dvsManager.queryCompatibleHostForNewDVS(dvsManagerMor,
                        this.folder.getDataCenter(), true, productSpec);
      this.dvsMor =
               folder.createDistributedVirtualSwitch(this.getTestId(),
                        vDsVersion, compatibleHosts);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");

      allHosts = this.hostSystem.getAllHost();
      assertTrue((allHosts != null && allHosts.size() > 0),
               MessageConstants.HOST_GET_PASS, MessageConstants.HOST_GET_FAIL);

      //allHosts.removeAll(TestUtil.arrayToVector(compatibleHosts));
      assertTrue((allHosts != null && allHosts.size() > 0),
               MessageConstants.HOST_GET_PASS, MessageConstants.HOST_GET_FAIL);
      hostFolder = this.hostSystem.getHostFolder(allHosts.get(0));
      assertNotNull(hostFolder, "Successfully got the hostFolder",
               "Null returned for hostFolder"); 
      expectedCompatibilityResult =
               new DistributedVirtualSwitchManagerCompatibilityResult[allHosts
                        .size()];
      for (int i = 0; i < allHosts.size(); i++) {
         expectedCompatibilityResult[i] =
                  new DistributedVirtualSwitchManagerCompatibilityResult();
         expectedCompatibilityResult[i].setHost(allHosts.get(i));
         faults.add(DVSTestConstants.EXPECTED_FAULT_1);
         expectedCompatibilityResult[i].getError().clear();
         expectedCompatibilityResult[i].getError().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(DVSUtil
                  .createLocalizedMethodFault(faults)));
      }
      /*
       * Create hostFilterSpec here
       */
      hostDvsMembershipFilter =
               DVSUtil.createHostDvsMembershipFilter(this.dvsMor, false);
    		  //DVSUtil.createHostDvsMembershipFilter(this.dvsMor, true);
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
    		 // DVSUtil.createHostContainer(this.folder.getDataCenter(), false);
      assertNotNull(hostContainer, "created  hosts container",
               "Unable to create hosts container");
      return true;
   }

   @Test(description = "Test case to verify  for  checkCompatibility api for"
               + " add-host-to-dvs (new vDs version ) usecase\n"
               + "1.Get all  hosts(ompatible + incompatible  for given vds version) from  datacenter\n"
               + "2. queryCompatibleHostForNewDVS and create dvs ( dvSwitch1)  with given  vDs version and add both CompatibleHost to it."
               + " datacenter "
               + "3.Invoke checkCompatibility method by passing container"
               + " as datacenter,dvsMembership is set to exclude host"
               + " members of the dvSwitch1 and switchProductSpec as"
               + " valid ProductSpec of the dvSwitch1.")
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
                                 null);
                                // new DistributedVirtualSwitchManagerHostDvsFilterSpec[] { hostDvsMembershipFilter });
      assertTrue(DVSUtil.verifyCompatibilityResults(
               expectedCompatibilityResult, actualCompatibilityResult),
               "Unable verify CompatibilityResults");
     /* assertTrue(DVSUtil.verifyHostsInCompatibilityResults(connectAnchor,
              actualCompatibilityResult, expectedCompatibilityResult, 
             this.allHosts, null),
              "Unable to  verify the CompatibilityResults");
              */
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
