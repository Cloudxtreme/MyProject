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

import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.util.TestUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder with the following configuration:
 * DVSConfigSpec.configVersion is set to an empty string. DVSConfigSpec.name is
 * set to "CreateDVS-Pos050" numPort - valid number maxPort - valid number For
 * DVPortSetting: blocked - false mtu to a valid value
 */

public class Pos050 extends CreateDVSTestBase
{
   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + "the following configuration:\n "
               + "DVSConfigSpec.configVersion is set to an empty string,\n"
               + "DVSConfigSpec.name is set to 'CreateDVS-Pos050',\n"
               + "numPort - valid number\n" + "maxPort - valid number\n"
               + "For DVPortSetting:\n" + "blocked - false\n"
               + "mtu to a valid value.");
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
      VMwareDVSConfigSpec vmwareDVSConfigSpec = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               vmwareDVSConfigSpec = new VMwareDVSConfigSpec();
               vmwareDVSConfigSpec.setConfigVersion("");
               vmwareDVSConfigSpec.setName(this.getTestId());
               vmwareDVSConfigSpec.setMaxPorts(5);
               vmwareDVSConfigSpec.setNumStandalonePorts(5);
               vmwareDVSConfigSpec.setMaxMtu(1287);
               this.configSpec = vmwareDVSConfigSpec;
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
               + "DVSConfigSpec.configVersion is set to an empty string,\n"
               + "DVSConfigSpec.name is set to 'CreateDVS-Pos050',\n"
               + "numPort - valid number\n" + "maxPort - valid number\n"
               + "For DVPortSetting:\n" + "blocked - false\n"
               + "mtu to a valid value.")
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
                  status = true;
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