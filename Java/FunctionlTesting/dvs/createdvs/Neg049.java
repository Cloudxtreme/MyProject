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

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder with the following configuration:
 * configVersion - empty string name - "Create DVS-Pos069" For DVPortSetting:
 * qosTag is -2
 */

public class Neg049 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   VMwareUplinkPortOrderPolicy portOrderPolicy = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + "the following configuration:\n "
               + "configVersion - empty string\n"
               + "name - 'Create DVS-Neg049'\n " + "For DVPortSetting:\n"
               + "qosTag is -2\n");
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
      VMwareDVSPortSetting dvPort = new VMwareDVSPortSetting();
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(getTestId());
               dvPort.setQosTag(DVSUtil.getIntPolicy(false, -2));
               this.configSpec.setDefaultPortConfig(dvPort);
               status = true;
            } else {
               log.error("Failed to create the network folder");
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
               + "the following configuration:\n "
               + "configVersion - empty string\n"
               + "name - 'Create DVS-Neg049'\n " + "For DVPortSetting:\n"
               + "qosTag is -2\n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.error("The dvswitch should not have been created");
            } else {
               log.error("Exception should have been thrown");
            }
         }
      } catch (Exception mfExcep) {
         MethodFault mf = com.vmware.vcqa.util.TestUtil.getFault(mfExcep);
         MethodFault expectedFault = new InvalidArgument();
         status = TestUtil.checkMethodFault(mf, expectedFault);
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