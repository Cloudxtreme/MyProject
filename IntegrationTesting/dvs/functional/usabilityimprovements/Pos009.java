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
import java.util.Vector;

import com.vmware.vc.DistributedVirtualSwitchManagerCompatibilityResult;
import com.vmware.vc.DistributedVirtualSwitchManagerDvsProductSpec;
import com.vmware.vc.DistributedVirtualSwitchManagerHostContainer;
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
 * 1.Get all hosts( compatible + incompatible  for given vds version) from<BR>
 * datacenter<BR>
 * TEST:<BR>>
 * 2.Invoke checkCompatibility method by passing container as datacenter, <BR>>
 * dvsMembership as null and switchProductSpec as valid ProductSpec for<BR>
 * the new DVSs<BR>
 * 3.Invoke create dvs with new spec by adding compatible  hosts returned by <BR>
 * checkCompatibility method<BR>
 * CLEANUP:<BR>
 * 4. Destroy vDs<BR>
 */
public class Pos009 extends TestBase implements IDataDrivenTest 
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
      setTestDescription("Test case to verify checkCompatibility for create-dvs"
               + "(with  given vDS version)  dvs  situation\n"
               + "1.Get all  hosts(ompatible + incompatible  for given vds version) from  datacenter\n"
               + " 2. Invoke checkCompatibility method by passing\n"
               + " container as dataCenter, "
               + " dvsMembership as null and new vDs version"
               + "switchProductSpec "
               + "as valid ProductSpec for  the new DVS\n"
               + " 3.Invoke create dvs with new spec by adding compatible host "
               + " returned by checkCompatibility method ");
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
      allHosts = this.hostSystem.getAllHost();
      assertTrue((allHosts != null && allHosts.size() > 0),
               MessageConstants.HOST_GET_PASS, MessageConstants.HOST_GET_FAIL);
      expectedCompatibilityResult =
         new DistributedVirtualSwitchManagerCompatibilityResult[allHosts
                  .size()];
      //allHosts.removeAll(TestUtil.arrayToVector(compatibleHosts));
      assertTrue((allHosts != null && allHosts.size() > 0),
               MessageConstants.HOST_GET_PASS, MessageConstants.HOST_GET_FAIL);
      hostFolder = this.hostSystem.getHostFolder(allHosts.get(0));
      assertNotNull(hostFolder, "Successfully got the hostFolder",
               "Null returned for hostFolder");
      for (int i = 0; i < compatibleHosts.length; i++) {
         expectedCompatibilityResult[i] =
                  new DistributedVirtualSwitchManagerCompatibilityResult();
         expectedCompatibilityResult[i].setHost(compatibleHosts[i]);
         expectedCompatibilityResult[i].getError().clear();
      }
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
      hostContainer =
               DVSUtil.createHostContainer(this.folder.getDataCenter(), true);
      assertNotNull(hostContainer, "created  hosts container",
               "Unable to create hosts container");
      return true;
   }

   @Test(description = "Test case to verify checkCompatibility for create-dvs"
               + "(with  given vDS version)  dvs  situation\n"
               + "1.Get all  hosts(ompatible + incompatible  for given vds version) from  datacenter\n"
               + " 2. Invoke checkCompatibility method by passing\n"
               + " container as dataCenter, "
               + " dvsMembership as null and new vDs version"
               + "switchProductSpec "
               + "as valid ProductSpec for  the new DVS\n"
               + " 3.Invoke create dvs with new spec by adding compatible host "
               + " returned by checkCompatibility method ")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchManagerDvsProductSpec spec =
               new DistributedVirtualSwitchManagerDvsProductSpec();
      spec.setDistributedVirtualSwitch(null);
      spec.setNewSwitchProductSpec(productSpec);
      actualCompatibilityResult =
               this.dvsManager.queryCheckCompatibility(dvsManagerMor,
                        hostContainer, spec, null);
      assertTrue(DVSUtil.verifyHostsInCompatibilityResults(connectAnchor,
               actualCompatibilityResult, expectedCompatibilityResult,
               TestUtil.arrayToVector(compatibleHosts), null),
               "Unable to  verify the CompatibilityResults");
      this.dvsMor =
               folder.createDistributedVirtualSwitch(this.getTestId(),
                        vDsVersion, compatibleHosts);
      assertNotNull(dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
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
