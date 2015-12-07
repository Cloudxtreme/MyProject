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
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid folder with the following parameters set in the
 * config spec. - DVSConfigSpec.configVersion is set to an empty string -
 * DVSConfigSpec.name is set to "CreateDVS-Neg040" - DVPortSetting.blocked is
 * set to false - outShapingPolicy.enabled is set to true -
 * outShapingPolicy.averageBandWidth is set to -1.
 */
public class Neg040 extends CreateDVSTestBase
{

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS inside a valid folder with the"
               + " following parameters set in the config spec:\n"
               + "  - DVSConfigSpec.configVersion is set to an empty string\n"
               + "  - DVSConfigSpec.name is set to 'CreateDVS-Neg040'\n"
               + "  - DVPortSetting.blocked is set to false\n"
               + "  - outShapingPolicy.enabled is set to true\n"
               + "  - outShapingPolicy.averageBandWidth is set to -1.");
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
               DVPortSetting portSetting = new DVPortSetting();
               DVSTrafficShapingPolicy outShapingPolicy = new DVSTrafficShapingPolicy();
               this.configSpec = new VMwareDVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(this.getTestId());
               portSetting.setBlocked(DVSUtil.getBoolPolicy(false, false));
               outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false, true));
               outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                        false, new Long(-1)));
               portSetting.setOutShapingPolicy(outShapingPolicy);
               this.configSpec.setDefaultPortConfig(portSetting);
               status = true;
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
   @Test(description = "Create a DVS inside a valid folder with the"
               + " following parameters set in the config spec:\n"
               + "  - DVSConfigSpec.configVersion is set to an empty string\n"
               + "  - DVSConfigSpec.name is set to 'CreateDVS-Neg040'\n"
               + "  - DVPortSetting.blocked is set to false\n"
               + "  - outShapingPolicy.enabled is set to true\n"
               + "  - outShapingPolicy.averageBandWidth is set to -1.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                  this.networkFolderMor, this.configSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         InvalidArgument expectedMethodFault = new InvalidArgument();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
      boolean status = true;
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}