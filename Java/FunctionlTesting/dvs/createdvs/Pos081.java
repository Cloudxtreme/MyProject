/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import java.util.Arrays;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareIpfixConfig;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * DESCRIPTION:<br>
 * Data-driven test to create DistributedVirtualSwitch with a valid IpfixConfig
 * parameter. <br>
 * SETUP:<br>
 * 1. Create a valid IpfixConfig object<br>
 * TEST:<br>
 * 2. Create a DVS with a host adding to it, and with the given IpfixConfigSpec object<br>
 * CLEANUP:<br>
 * 3. Destroy the created dvs<br>
 *
 */
public class Pos081 extends TestBase implements IDataDrivenTest {

   private Folder folder = null;
   private VMwareDVSConfigSpec configSpec = null;
   private ManagedObjectReference dcMor = null;
   private HostSystem hs = null;
   private DistributedVirtualSwitchHelper dvs = null;
   private ManagedObjectReference networkFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference hostMor = null;
   private VMwareIpfixConfig expectedIpfixConfig = null;
   private String hostName = null;
   private String dvsUUID = null;
   private String vdsVersion = null;

   /**
    * This method retrieves either all the data-driven tests or one
    * test based on the presence of test id in the execution properties
    * file.
    *
    * @return Object[]
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception {
      Object[] tests = TestExecutionUtils.getTests(this.getClass().getName(),
         dataFile);
      /*
       * Load the dvs execution properties file
       */
      String testId = TestUtil.getPropertyValue(this.getClass().getName(),
         DVSTestConstants.DVS_EXECUTION_PROP_FILE);
      if(testId == null){
         return tests;
      } else {
         for(Object test : tests){
            if(test instanceof TestBase){
               TestBase testBase = (TestBase)test;
               if(testBase.getTestId().equals(testId)){
                  return new Object[]{testBase};
               }
            } else {
               log.error("The current test is not an instance of TestBase");
            }
         }
         log.error("The test id " + testId + "could not be found");
      }
      /*
       * TODO : Examine the possibility of a custom exception here since
       * the test id provided is wrong and the user needs to be notified of
       * that.
       */
      return null;
   }

   public String getTestName()
   {
      return getTestId();
   }

   /**
   * Test Setup.
   */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      this.folder = new Folder(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.dvs = new DistributedVirtualSwitchHelper(connectAnchor);
      this.dcMor = (ManagedObjectReference) this.folder.getDataCenter();
      this.hostMor = this.hs.getConnectedHost(null);
      this.hostName = this.hs.getName(hostMor);
      this.networkFolderMor = (ManagedObjectReference) this.folder.getNetworkFolder(dcMor);
      Assert.assertNotNull(this.networkFolderMor,
               "Unable to get Networkfolder Mor");
      this.vdsVersion = DVSUtil.getvDsVersion();
      this.configSpec = new VMwareDVSConfigSpec();
      this.configSpec.setConfigVersion("");
      this.configSpec.setName(this.getClass().getName());
      this.configSpec = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpec(
               configSpec, Arrays.asList(this.hostMor));
      expectedIpfixConfig = DVSUtil.createIpfixConfig(
               data.getString(DVSTestConstants.COLLECTORIPADDRESS),
               data.getInt(DVSTestConstants.COLLECTORPORT),
               data.getInt(DVSTestConstants.ACTIVEFLOWTIMEOUT),
               data.getInt(DVSTestConstants.IDLEFLOWTIMEOUT),
               data.getInt(DVSTestConstants.SAMPLINGRATE),
               data.getBoolean(DVSTestConstants.INTERNALFLOWSONLY));
      if (vdsVersion.compareTo(DVSTestConstants.VDS_VERSION_60) >= 0) {
          expectedIpfixConfig.setObservationDomainId(data.getLong(DVSTestConstants.OBSERVATIONDOMAINID));
      }
      this.configSpec.setIpfixConfig(expectedIpfixConfig);
      return true;
   }

   /**
    * Test.
    */
   @Test(description = "Data-driven test to create DistributedVirtualSwitch " +
         "with a valid IpfixConfig parameter.")
   public void test()
      throws Exception
   {
      dvsMor = folder.createDistributedVirtualSwitch(networkFolderMor,
               this.configSpec);
      this.dvsUUID = this.dvs.getConfig(dvsMor).getUuid();
      Assert.assertTrue(
               (dvs.validateDVSConfigSpec(this.dvsMor, this.configSpec, null)),
               "Successfully verified DVS ConfigSpec",
               "DVS config spec is not valid");
      Assert.assertTrue(DVSUtil.verifyIpfixConfig(connectAnchor, hostName,
               dvsUUID, dvsMor, expectedIpfixConfig), "");
   }

   /**
    * Test Cleanup.
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      if (dvsMor != null) {
         folder.destroy(dvsMor);
         log.info("Destroyed DVS successfully");
      }
      return true;
   }
}
