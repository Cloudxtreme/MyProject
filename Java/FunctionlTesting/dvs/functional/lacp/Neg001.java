/*
 * ************************************************************************
 *
 * Copyright 2012 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.lacp;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.BoolPolicy;
import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotSupported;
import com.vmware.vc.StringPolicy;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkLacpPolicy;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.CreateDVSTestBase;

/**
 * Create a vds and reconfigure dvport to set the lacp policy
 */
public class Neg001 extends CreateDVSTestBase implements IDataDrivenTest
{
   private VMwareUplinkLacpPolicy lacpPolicy = null;
   private ManagedObjectReference hostMor = null;

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      String dvsName = this.getTestId();
      if (super.testSetUp()) {
         this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
         if (this.networkFolderMor != null) {
            lacpPolicy = new VMwareUplinkLacpPolicy();
            BoolPolicy boolPolicy = new BoolPolicy();
            boolPolicy.setValue(Boolean.valueOf(data.getString("Enable")));
            lacpPolicy.setEnable(boolPolicy);
            StringPolicy stringPolicy = new StringPolicy();
            stringPolicy.setValue(data.getString("VMwareUplinkLacpMode"));
            lacpPolicy.setMode(stringPolicy);
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setName(dvsName);
            this.configSpec.setNumStandalonePorts(1);
            //this.configSpec.setDefaultPortConfig(setting);
            this.hostMor = this.ihs.getConnectedHost(null);
            assertNotNull(this.hostMor,"Found a host in the inventory",
                     "Failed to find a host in the inventory");
            status = true;
         } else {
            log.error("Failed to create the network folder");
         }
      } else {
         log.error("Test setup failed.");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a vds and reconfigure a dvport to set the " +
         "lacp policy")
   public void test()
      throws Exception
   {
      try{
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                  this.networkFolderMor, this.configSpec);
         assertNotNull(dvsMOR, "Successfully created the vds",
                  "Failed to create the vds");
         DVPortConfigSpec portConfigSpec = new DVPortConfigSpec();
         String portKey = this.iDistributedVirtualSwitch.
                  getFreeStandaloneDVPortKey(dvsMOR, null);
         assertNotNull(portKey,"Could not find a standalone dvport key " +
               "on the vds");
         portConfigSpec.setKey(portKey);
         portConfigSpec.setOperation(ConfigSpecOperation.EDIT.value());
         VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
         portSetting.setLacpPolicy(lacpPolicy);
         portConfigSpec.setSetting(portSetting);
         this.iDistributedVirtualSwitch.reconfigurePort(dvsMOR, new
                  DVPortConfigSpec[]{portConfigSpec});
      }catch(Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.
                  getFault(actualMethodFaultExcep);
         NotSupported expectedMethodFault = new NotSupported();
         assertTrue(TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault),"The expected exception was thrown",
                  "Method fault mismatch was detected");
      }
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      assertTrue(super.testCleanUp(), "Cleanup failed");
      return true;
   }

   /*
    * (non-Javadoc)
    * @see org.testng.ITest#getTestName()
    */
   public String getTestName()
   {
      return getTestId();
   }

   /**
    * This method retrieves either all the data-driven tests or one
    * test based on the presence of test id in the execution properties
    * file.The method returns null if no test was obtained.
    *
    * @return Object[]
    *
    * @throws Exception
    */
   @Factory
   @Parameters({"dataFile"})
   public Object[] getTests(@Optional("") String dataFile)
      throws Exception
   {
      Object[] tests = TestExecutionUtils.getTests(this.getClass().getName(),
               dataFile);
      /*
       * Load the dvs execution properties file
       */
      String testId = TestUtil.getPropertyValue(this.getClass().getName(),
               DVSTestConstants.DVS_EXECUTION_PROP_FILE);
      if (testId == null) {
         return tests;
      } else {
         for (Object test : tests) {
            if (test instanceof TestBase) {
               TestBase testBase = (TestBase) test;
               if (testBase.getTestId().equals(testId)) {
                  return new Object[] { testBase };
               }
            } else {
               log.error("The current test is not an instance of TestBase");
            }
         }
         log.error("The test id " + testId + "could not be found");
      }
      return null;
   }
}
