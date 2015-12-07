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

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder with the following configuration:
 * VmwareDVSPortSetting.blocked set to false VmwareDVSPortSetting.policy set to
 * an invalid policy
 */

public class Neg045 extends CreateDVSTestBase
{

   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + "the following configuration: \n"
               + "VmwareDVSPortSetting.blocked set to false\n"
               + "VmwareDVSPortSetting.policy set to an invalid policy\n");
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
      VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = new VmwareUplinkPortTeamingPolicy();

      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getRootFolder();
            if (this.networkFolderMor != null) {
               this.configSpec = new VMwareDVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(DVSTestConstants.DVS_CREATE_NAME_PREFIX
                        + this.getTestId());
               portSetting.setBlocked(DVSUtil.getBoolPolicy(false, false));
               uplinkTeamingPolicy.setInherited(false);
               uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
                        "@#$%^"));
               portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
               this.configSpec.setDefaultPortConfig(portSetting);
               status = true;
            } else {
               log.error("Failed to get the network folder");
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
               + "VmwareDVSPortSetting.blocked set to false\n"
               + "VmwareDVSPortSetting.policy set to an invalid policy\n")
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