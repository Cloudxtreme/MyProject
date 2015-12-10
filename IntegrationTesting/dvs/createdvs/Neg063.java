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

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
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

/**
 * DESCRIPTION:<br>
 * Data-driven test to create DistributedVirtualSwitch with a invalid IpfixConfig
 * in DVSConfigSpec and IpfixEnabled to true/false in DVSPortSetting.
 * SETUP:<br>
 * 1. Create a invalid IpfixConfig object and IpfixEnabled configured to true/false<br>
 * TEST:<br>
 * 2. Create a DVS with a host adding to it, and with the given IpfixConfigSpec object
 * 3. Verify if the expected exception is thrown<br>
 * CLEANUP:<br>
 * 3. Destroy the created dvs<br>
 */

public class Neg063 extends TestBase implements IDataDrivenTest
{
   private Folder folder = null;
   private ManagedObjectReference dcMor = null;
   private HostSystem iHostSystem = null;
   private ManagedObjectReference networkFolderMor = null;
   private ManagedObjectReference hostMor = null;
   private VMwareDVSPortSetting dvPort = new VMwareDVSPortSetting();
   private VMwareDVSConfigSpec configSpec = new VMwareDVSConfigSpec();
   private ManagedObjectReference dvsMor = null;
   private VMwareIpfixConfig expectedIpfixConfig = null;

   /**
   * Test Setup
   */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      this.folder = new Folder(connectAnchor);
      this.iHostSystem = new HostSystem(connectAnchor);
      this.dcMor = (ManagedObjectReference) this.folder.getDataCenter();
      this.networkFolderMor = (ManagedObjectReference) this.folder.getNetworkFolder(dcMor);
      Assert.assertNotNull(this.networkFolderMor, "Unable to get Networkfolder Mor");
      this.hostMor = this.iHostSystem.getConnectedHost(null);
      this.configSpec.setConfigVersion("");
      this.configSpec.setName(this.getClass().getName());
      this.configSpec = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpec(
               configSpec, Arrays.asList(this.hostMor));
      dvPort.setIpfixEnabled(DVSUtil.getBoolPolicy(
               this.data.getBoolean(DVSTestConstants.IP_FIX_INHERITED_KEY),
               this.data.getBoolean(DVSTestConstants.IP_FIX_ENABLED_KEY)));
      expectedIpfixConfig = DVSUtil.createIpfixConfig(
               data.getString(DVSTestConstants.COLLECTORIPADDRESS),
               data.getInt(DVSTestConstants.COLLECTORPORT),
               data.getInt(DVSTestConstants.ACTIVEFLOWTIMEOUT),
               data.getInt(DVSTestConstants.IDLEFLOWTIMEOUT),
               data.getInt(DVSTestConstants.SAMPLINGRATE),
               data.getBoolean(DVSTestConstants.INTERNALFLOWSONLY));
      this.configSpec.setDefaultPortConfig(dvPort);
      this.configSpec.setIpfixConfig(expectedIpfixConfig);
      return true;
   }

   /**
   * Test Method
   *
   */
   @Test(description="Data-driven test to create DistributedVirtualSwitch with a invalid IpfixConfig " +
         "in DVSConfigSpec and IpfixEnabled to true/false in DVSPortSetting")
   public void test()
      throws Exception
   {
      try {
         dvsMor= folder.createDistributedVirtualSwitch(networkFolderMor,this.configSpec);
         log.error("Test did not threw exception!");
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
   * Test Cleanup method.
   *
   */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      if(dvsMor != null) {
         folder.destroy(dvsMor);
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
   public String getTestName()
   {
      return getTestId();
   }
}
