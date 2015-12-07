/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

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
 * Reconfigure an existing DVS as follows: - Set the DVSConfigSpec.configVersion
 * to a valid config version string - Set DVPortSetting.blocked to false - Set
 * inShapingPolicy.enabled to true - Set inShapingPolicy.peakBandWidth to 102400
 * - Set inShapingPolicy.avarageBandWidth to 102400 - Set
 * inShapingPolicy.burstSize to 102400 - Set outShapingPolicy.enabled to true -
 * Set outShapingPolicy.peakBandWidth to 102400 - Set
 * outShapingPolicy.avarageBandWidth to 102400 - Set outShapingPolicy.burstSize
 * to 102400
 */
public class Pos056 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n" + "  - Set DVPortSetting.blocked to false,\n"
               + "  - Set inShapingPolicy.enabled to true,\n"
               + "  - Set inShapingPolicy.peakBandWidth to 102400,\n"
               + "  - Set inShapingPolicy.avarageBandWidth to 102400,\n"
               + "  - Set inShapingPolicy.burstSize to 102400,\n"
               + "  - Set outShapingPolicy.enabled to true,\n"
               + "  - Set outShapingPolicy.peakBandWidth to 102400,\n"
               + "  - Set outShapingPolicy.avarageBandWidth to 102400,\n"
               + "  - Set outShapingPolicy.burstSize to 102400.");
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
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  this.deltaConfigSpec = new DVSConfigSpec();
                  DVPortSetting portSetting = this.iDistributedVirtualSwitch.getConfig(
                           this.dvsMOR).getDefaultPortConfig();
                  inShapingPolicy = portSetting.getInShapingPolicy();
                  if (inShapingPolicy == null) {
                     inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                              true, new Long(102400), new Long(102400),
                              new Long(102400));
                  } else {
                     inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                              true));
                     inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(
                              false, new Long(102400)));
                     inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                              false, new Long(102400)));
                     inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                              new Long(102400)));
                  }
                  outShapingPolicy = portSetting.getInShapingPolicy();
                  if (outShapingPolicy == null) {
                     outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                              true, new Long(102400), new Long(102400),
                              new Long(102400));
                  } else {
                     outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                              true));
                     outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(
                              false, new Long(102400)));
                     outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                              false, new Long(102400)));
                     outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                              new Long(102400)));
                  }
                  String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  portSetting.setBlocked(DVSUtil.getBoolPolicy(false, false));
                  portSetting.setInShapingPolicy(inShapingPolicy);
                  portSetting.setOutShapingPolicy(outShapingPolicy);
                  this.deltaConfigSpec.setDefaultPortConfig(portSetting);
                  status = true;
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n" + "  - Set DVPortSetting.blocked to false,\n"
               + "  - Set inShapingPolicy.enabled to true,\n"
               + "  - Set inShapingPolicy.peakBandWidth to 102400,\n"
               + "  - Set inShapingPolicy.avarageBandWidth to 102400,\n"
               + "  - Set inShapingPolicy.burstSize to 102400,\n"
               + "  - Set outShapingPolicy.enabled to true,\n"
               + "  - Set outShapingPolicy.peakBandWidth to 102400,\n"
               + "  - Set outShapingPolicy.avarageBandWidth to 102400,\n"
               + "  - Set outShapingPolicy.burstSize to 102400.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         assertTrue(status, "Test Failed");
     
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
      boolean status = true;
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}