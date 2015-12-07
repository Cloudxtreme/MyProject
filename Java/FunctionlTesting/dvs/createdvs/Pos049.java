/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder with the following configuration:
 * DVSConfigSpec.configVersion is set to an empty string. DVSConfigSpec.name is
 * set to "CreateDVS-Pos049" numPort - valid number maxPort - valid number For
 * DVPortSetting: blocked - false For outShapingPolicy enabled - true
 * peakBandWidth = 102400 averageBandWidth = 102400 burstSize = 102400
 */

public class Pos049 extends CreateDVSTestBase
{
   DVPortSetting dvPort = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + "the following configuration: \n"
               + "DVSConfigSpec.configVersion is set to an empty string,\n"
               + "DVSConfigSpec.name is set to 'CreateDVS-Pos049',\n"
               + "numPort - valid number\n" + "maxPort - valid number\n"
               + "For DVPortSetting:\n" + "blocked - false\n"
               + "For outShapingPolicy\n" + "enabled - true\n"
               + "peakBandWidth = 102400\n" + "averageBandWidth = 102400\n"
               + "burstSize = 102400\n");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               DVSTrafficShapingPolicy outShapingPolicy = new DVSTrafficShapingPolicy();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(this.getTestId());
               dvPort = new DVPortSetting();
               dvPort.setBlocked(DVSUtil.getBoolPolicy(false, false));
               outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
               outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false,
                        (long) 102400));
               outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                        false, (long) 102400));
               outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                        (long) 102400));
               dvPort.setOutShapingPolicy(outShapingPolicy);
               this.configSpec.setDefaultPortConfig(dvPort);
               status = true;
            } else {
               log.error("Failed to create the root folder");
            }
         } else {
            log.error("Failed to login");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a DVSwitch inside a valid folder with"
               + "the following configuration: \n"
               + "DVSConfigSpec.configVersion is set to an empty string,\n"
               + "DVSConfigSpec.name is set to 'CreateDVS-Pos049',\n"
               + "numPort - valid number\n" + "maxPort - valid number\n"
               + "For DVPortSetting:\n" + "blocked - false\n"
               + "For outShapingPolicy\n" + "enabled - true\n"
               + "peakBandWidth = 102400\n" + "averageBandWidth = 102400\n"
               + "burstSize = 102400\n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               if (iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
                        this.configSpec, null)) {
                  log.info("successfully verified the dvs config spec");
                  if (super.verifyPortSettingOnHost(connectAnchor, dvPort)) {
                     log.info("Verified the dv port setting on the host");
                     status = true;
                  } else {
                     log.error("Can not verift the dv port setting on the host");
                  }
               } else {
                  log.info("The config spec of the Distributed Virtual Switch"
                           + "is not created as per specifications");
               }
            } else {
               log.error("Cannot create the distributed "
                        + "virtual switch with the config spec passed");
            }
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
     
         status = super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}