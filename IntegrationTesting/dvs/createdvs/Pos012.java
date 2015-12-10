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
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vcqa.util.TestUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid folder with the following parameters set in the
 * config spec. DVSConfigSpec.configVersion is set to an empty string.
 * DVSConfigSpec.name is set to "Create DVS- Pos012" DVSConfigSpec.maxPorts is
 * set to 0 DVSConfigSpec.numPorts is set to 0 DVSConfigSpec.uplinkPortPolicy is
 * set to an array ({uplink1....uplink32}).
 */
public class Pos012 extends CreateDVSTestBase
{
   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + " the following parameters set in the config " + "spec:\n "
               + "1.DVSConfigSpec.configVersion is set to an "
               + "empty string,\n" + "2.DVSConfigSpec.name is set to "
               + "'Create DVS- Pos012',\n"
               + "3.DVSConfigSpec.maxPorts is set to 0,\n"
               + "4.DVSConfigSpec.numPorts is set to 0,\n"
               + "5.DVSConfigSpec.uplinkPortPolicy is set to an "
               + "array ({uplink1.....uplink32}).");
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
      String dvsName = this.getTestId();
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               String[] uplinkPortNames = new String[32];
               for (int i = 0; i < 32; i++) {
                  uplinkPortNames[i] = "uplink" + i;
               }
               DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(dvsName);
               this.configSpec.setMaxPorts(0);
               this.configSpec.setNumStandalonePorts(0);
               uplinkPolicyInst.getUplinkPortName().clear();
               uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
               this.configSpec.setUplinkPortPolicy(uplinkPolicyInst);
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
   @Test(description = "Create a DVSwitch inside a valid folder with"
               + " the following parameters set in the config " + "spec:\n "
               + "1.DVSConfigSpec.configVersion is set to an "
               + "empty string,\n" + "2.DVSConfigSpec.name is set to "
               + "'Create DVS- Pos012',\n"
               + "3.DVSConfigSpec.maxPorts is set to 0,\n"
               + "4.DVSConfigSpec.numPorts is set to 0,\n"
               + "5.DVSConfigSpec.uplinkPortPolicy is set to an "
               + "array ({uplink1.....uplink32}).")
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
      boolean status = true;
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}