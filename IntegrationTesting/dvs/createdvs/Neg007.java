/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.TestUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid folder with the following parameters set in the
 * config spec. A valid folder ManagedObjectReference
 * DVSConfigSpec.configVersion is set to an empty string. DVSConfigSpec.name is
 * set to an already existing DVSwitch name
 */
public class Neg007 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   ManagedObjectReference tempDVSmor = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS inside a valid folder with the"
               + " following parameters set in the config spec:\n"
               + "A valid folder ManagedObjectReference,\n"
               + "DVSConfigSpec.configVersion is set to an empty string,\n"
               + "DVSConfigSpec.name is set to an already existing DVSwitch name.");
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
      final DVSConfigSpec tempConfigSpec = new DVSConfigSpec();
      log.info("Test setup Begin:");
      if (super.testSetUp()) {
         networkFolderMor = iFolder.getNetworkFolder(dcMor);
         if (networkFolderMor != null) {
            tempConfigSpec.setConfigVersion("");
            tempConfigSpec.setName("DVSwitch_One");
            tempDVSmor = iFolder.createDistributedVirtualSwitch(
                     networkFolderMor, tempConfigSpec);
            configSpec = new DVSConfigSpec();
            configSpec.setConfigVersion("");
            configSpec.setName("DVSwitch_One");
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
   @Override
   @Test(description = "Create a DVS inside a valid folder with the"
            + " following parameters set in the config spec:\n"
            + "A valid folder ManagedObjectReference,\n"
            + "DVSConfigSpec.configVersion is set to an empty string,\n"
            + "DVSConfigSpec.name is set to an already existing DVSwitch name.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
                  configSpec);
         log.error("The API did not throw Exception");
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         final InvalidArgument expectedMethodFault = new InvalidArgument();
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
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (tempDVSmor != null) {
         status &= iManagedEntity.destroy(tempDVSmor);
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