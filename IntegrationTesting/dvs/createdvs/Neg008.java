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
import com.vmware.vcqa.util.TestUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS with parameters set as follows: - ManagedObjectReference set to
 * a valid folder object - DVSConfigSpec.configVersion is set to an empty
 * string. - DVSConfigSpec.name is set to "Create DVS-Neg008" -
 * DVSConfigSpec.maxPorts set to a valid number that is less than numPorts. -
 * DVSConfigSpec.numPorts set to a valid number.
 */
public class Neg008 extends CreateDVSTestBase
{
   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS with parameters set as "
               + "follows:\n"
               + " - ManagedObjectReference set to a valid folder object, \n"
               + " - DVSConfigSpec.configVersion is set to an empty string, \n"
               + " - DVSConfigSpec.name is set to 'Create DVS-Neg008', \n"
               + " - DVSConfigSpec.maxPorts set to a valid number that is less than"
               + " numPorts, \n"
               + " - DVSConfigSpec.numPorts set to a valid number.");
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
               this.configSpec = new VMwareDVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(this.getTestId());
               this.configSpec.setMaxPorts(5);
               this.configSpec.setNumStandalonePorts(6);
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
   @Test(description = "Create a DVS with parameters set as "
               + "follows:\n"
               + " - ManagedObjectReference set to a valid folder object, \n"
               + " - DVSConfigSpec.configVersion is set to an empty string, \n"
               + " - DVSConfigSpec.name is set to 'Create DVS-Neg008', \n"
               + " - DVSConfigSpec.maxPorts set to a valid number that is less than"
               + " numPorts, \n"
               + " - DVSConfigSpec.numPorts set to a valid number.")
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
     
         if (this.dvsMOR == null) {

         } else {
            status &= super.testCleanUp();
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}