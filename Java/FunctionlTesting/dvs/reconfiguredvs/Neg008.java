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

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting the ManagedObjectReference to a
 * valid DVSwitch Mor and DVSConfigSpec.configVersion to a valid config version
 * string and name to an already existing DVSwitch name
 */

public class Neg008 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   ManagedObjectReference tempDVSmor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and name"
               + " to an already existing DVSwitch name.");
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
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  DVSConfigSpec tempConfigSpec = new DVSConfigSpec();
                  tempConfigSpec.setConfigVersion("");
                  tempConfigSpec.setName("DVSwitch_One");
                  this.tempDVSmor = this.iFolder.createDistributedVirtualSwitch(
                           this.networkFolderMor, tempConfigSpec);
                  if (this.tempDVSmor != null) {
                     this.deltaConfigSpec = new DVSConfigSpec();
                     this.deltaConfigSpec.setName("DVSwitch_One");
                     status = true;
                  } else {
                     log.error("Failed to create a temporary DVSwitch.");
                  }
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
   @Test(description = "Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and name"
               + " to an already existing DVSwitch name.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
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
     
         if (this.tempDVSmor != null) {
            status &= this.iManagedEntity.destroy(this.tempDVSmor);
            if (status) {
               log.info("tempDVSmor destroyed successfully");
            } else {
               log.error("tempDVSmor could not be removed");
            }
         }
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}