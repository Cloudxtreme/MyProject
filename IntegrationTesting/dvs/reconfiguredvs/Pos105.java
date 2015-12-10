/*
 * ************************************************************************
 *
 * Copyright 2009-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import java.util.Arrays;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * DESCRIPTION:<br>
 * Data-driven test to reconfigure DistributedVirtualSwitch with a ipfixEnabled to true/false in DVSPortSetting
 * SETUP:<br>
 * 1. Create a DVS with a host adding to it, and with the given IpfixConfigSpec object<br>
 * 2. Create a IpfixConfig Object with IpfixEnabled enabled/disabled<br>
 * TEST:<br>
 * 3. Reconfigure dvs with the valid IpfixConfig object created above.
 * CLEANUP:<br>
 * 4. Destroy the created dvs<br>
 *
 */

public class Pos105 extends TestBase implements IDataDrivenTest
{
   private Folder folder = null;
   private VMwareDVSConfigSpec configSpec = null;
   private ManagedObjectReference dcMor = null;
   private DistributedVirtualSwitch dvs = null;
   private ManagedObjectReference networkFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private VMwareDVSConfigSpec deltaConfigSpec = null;
   private ManagedObjectReference hostMor = null;
   private VMwareDVSPortSetting dvPort = null;
   private HostSystem hs = null;

   public String getTestName()
   {
      return getTestId();
   }

   /**
    * Test Setup
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;
      this.folder = new Folder(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.hostMor = this.hs.getConnectedHost(null);
      this.dcMor = this.folder.getDataCenter();
      this.networkFolderMor = this.folder.getNetworkFolder(this.dcMor);
      Assert.assertNotNull(this.networkFolderMor, "Unable to get Networkfolder Mor");
      this.dvs = new DistributedVirtualSwitch(connectAnchor);
      this.configSpec = new VMwareDVSConfigSpec();
      this.configSpec = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpec(
               configSpec, Arrays.asList(this.hostMor));
      this.configSpec.setConfigVersion("");
      this.configSpec.setName(this.getClass().getName());
      this.dvsMor = this.folder.createDistributedVirtualSwitch(
               this.networkFolderMor, this.configSpec);
      Assert.assertNotNull(this.dvsMor, "Failed to create DVS");
      this.deltaConfigSpec = new VMwareDVSConfigSpec();
      this.deltaConfigSpec.setConfigVersion(this.dvs.getConfig(dvsMor).getConfigVersion());
      this.deltaConfigSpec.setName(this.getClass().getName());
      dvPort = new VMwareDVSPortSetting();
      dvPort.setIpfixEnabled(DVSUtil.getBoolPolicy(
               this.data.getBoolean(DVSTestConstants.IP_FIX_INHERITED_KEY),
               this.data.getBoolean(DVSTestConstants.IP_FIX_ENABLED_KEY)));
      this.deltaConfigSpec.setDefaultPortConfig(dvPort);
      setupDone = true;
      return setupDone;
   }

   /**
    * Test
    */
   @Test(description="Data-driven test to reconfigure DistributedVirtualSwitch with " +
         "a ipfixEnabled to true/false in DVSPortSetting")
   public void test()
      throws Exception
   {
      Assert.assertTrue(
               this.dvs.reconfigure(this.dvsMor, this.deltaConfigSpec),
               "Could not reconfigure dvs.");
      // Add a standalone port to the dvs created.
      List<String> keys = this.dvs.addStandaloneDVPorts(dvsMor, 1);
      Assert.assertTrue(
               (dvs.validateDVSConfigSpec(this.dvsMor, this.configSpec, null)),
               "Successfully verified DVS ConfigSpec",
               "DVS config spec is not valid");
      // Verify PortSettings from VC & hostd side.

      dvPort = (VMwareDVSPortSetting) this.dvs.getConfig(dvsMor).getDefaultPortConfig();
      Assert.assertTrue(DVSUtil.verifyIpfixPortSettingFromParent(connectAnchor,
               dvsMor, dvPort, keys), "Verification of IpfixPortSetting failed");
   }

   /**
    * Test Cleanup
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if(dvsMor != null) {
         folder.destroy(dvsMor);
         log.info("Successfully destroyed dvs");
      }
      return true;
   }

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
}
