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
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting the ManagedObjectReference to a
 * valid DVSwitch Mor and DVSConfigSpec.configVersion to a valid config version
 * string and name to a name containing alphabets, numeric characters, and
 * special characters.
 */

public class Pos075 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("Reconfigure an existing DVSwitch by setting "
                        + "the ManagedObjectReference to a valid DVSwitch Mor and "
                        + "DVSConfigSpec.configVersion to a v a name containing alphabets, "
                        + "  numeric characters, and special characters");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      log.info("Test setup Begin:");

      if (super.testSetUp()) {
         this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
         if (this.networkFolderMor != null) {
            this.iDistributedVirtualSwitch =
                     new DistributedVirtualSwitch(connectAnchor);
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setName(this.getClass().getName());
            this.dvsMOR =
                     this.iFolder.createDistributedVirtualSwitch(
                              this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               this.deltaConfigSpec = new DVSConfigSpec();
               String validConfigVersion =
                        this.iDistributedVirtualSwitch.getConfig(dvsMOR)
                                 .getConfigVersion();
               this.deltaConfigSpec.setConfigVersion(validConfigVersion);

               this.deltaConfigSpec
                        .setName(DVSTestConstants.NAME_ALPHA_NUMERIC_SPECIAL_CHARS);
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
   @Override
   @Test(description = "Reconfigure an existing DVSwitch by setting "
                        + "the ManagedObjectReference to a valid DVSwitch Mor and "
                        + "DVSConfigSpec.configVersion to a v a name containing alphabets, "
                        + "  numeric characters, and special characters")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
               this.deltaConfigSpec);
      this.deltaConfigSpec =
               this.iDistributedVirtualSwitch.getConfigSpec(dvsMOR);
      if (iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
               this.deltaConfigSpec, null)) {
         log.info(" Successfully reconfigured DVS");
         status = true;
      } else {
         log.error("The config spec of the Distributed Virtual Switch"
                  + "is not created as per specifications");
      }

      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

      status &= super.testCleanUp();

      assertTrue(status, "Cleanup failed");
      return status;
   }
}