/*
 * ************************************************************************
 *
 * Copyright 2012 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional.lacp;

import static com.vmware.vcqa.util.Assert.*;

import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.BoolPolicy;
import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.StringPolicy;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkLacpMode;
import com.vmware.vc.VMwareUplinkLacpPolicy;
import com.vmware.vcqa.IDataDrivenTest;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a vds version 5.1, add a host with free pnic to the vds with lacp
 * enabled and verify that the property is set on the uplink portgroup.
 */
public class Pos001 extends CreateDVSTestBase implements IDataDrivenTest
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
            String[] uplinkPortNames = new String[32];
            for (int i = 0; i < 32; i++) {
               uplinkPortNames[i] = "uplink" + i;
            }
            DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new
                     DVSNameArrayUplinkPortPolicy();
            lacpPolicy = new VMwareUplinkLacpPolicy();
            BoolPolicy boolPolicy = new BoolPolicy();
            String enableValue = data.getString("Enable");
            String lacpModeValue = data.getString("VMwareUplinkLacpMode");
            log.info("Lacp values : (enable = " + enableValue + ") " +
            "(lacpmode = " +lacpModeValue +")" );
            boolPolicy.setValue(Boolean.valueOf(enableValue));
            lacpPolicy.setEnable(boolPolicy);
            StringPolicy stringPolicy = new StringPolicy();
            stringPolicy.setValue(lacpModeValue);
            lacpPolicy.setMode(stringPolicy);
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setName(dvsName);
            uplinkPolicyInst.getUplinkPortName().clear();
            uplinkPolicyInst.getUplinkPortName().addAll(
                     com.vmware.vcqa.util.TestUtil.arrayToVector(
                              uplinkPortNames));
            this.configSpec.setUplinkPortPolicy(uplinkPolicyInst);
            VMwareDVSPortSetting setting = new VMwareDVSPortSetting();
            setting.setLacpPolicy(lacpPolicy);
            this.configSpec.setDefaultPortConfig(setting);
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
   @Test(description = "Create a vds, add a host with free pnic "
            + "to the vds with lacp enabled and verify that the property is "
            + "set on the uplink portgroup.")
   public void test()
      throws Exception
   {
      if (this.configSpec != null) {
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                  this.networkFolderMor, this.configSpec);
         if (this.dvsMOR != null) {
            log.info("Successfully created the DVSwitch");
            assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor, hostMor,
                     Arrays.asList(dvsMOR)),"Successfully added a host " +
                           "with free pnic to vds", "Failed to add a host " +
                                 "with free pnic to vds");
            List<ManagedObjectReference> pgMorList = this.
                     iDistributedVirtualSwitch.getUplinkPortgroups(dvsMOR);
            assertTrue(pgMorList != null && pgMorList.size() >=1,
                     "Found uplink portgroups on the vds","There were " +
                           "no uplink portgroups on the vds");
            log.info("There are " + pgMorList.size() + " uplink portgroups " +
                  "on the vds");
            /*
             * Query the property on an uplink portgroup to see if the property
             * is set
             */
            DVPortgroupConfigInfo dvpgConfigInfo = this.idvpg.
                     getConfigInfo(pgMorList.get(0));
            VMwareDVSPortSetting vmwarePortSetting = (VMwareDVSPortSetting)
                     dvpgConfigInfo.getDefaultPortConfig();
            VMwareUplinkLacpPolicy actualLacpPolicy = vmwarePortSetting.
                     getLacpPolicy();
            Vector<String> ignorePropList = new Vector<String>();
            ignorePropList.add("BoolPolicy.Inherited");
            ignorePropList.add("StringPolicy.Inherited");
            ignorePropList.add("VMwareUplinkLacpPolicy.Inherited");
            assertTrue(TestUtil.compareObject(actualLacpPolicy, lacpPolicy,
                     ignorePropList),"The expected and actual lacp " +
                           "policies are identical","The expected and " +
                                 "actual lacp policies are not identical");
         } else {
            log.error("Cannot create the distributed "
                     + "virtual switch with the config spec passed");
         }
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
    * file. The method returns null if no test was obtained.
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
