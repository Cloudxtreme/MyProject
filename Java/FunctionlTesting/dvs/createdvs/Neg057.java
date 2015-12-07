/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSCapability;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DVSFeatureCapability;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Create a vDs by passing
 * capability.featuresSupported.networkResourcePoolSupported to true.
 */
public class Neg057 extends TestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private ManagedObjectReference dvsMor = null;
   private DVSCapability capability = null;

   /**
    * This method will set the Description
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a vDs by passing "
               + "capability.featuresSupported.networkResourcePoolSupported"
               + " to true.");
   }

   /**
    * Method to set up the Environment for the test.
    * 
    * @param connectAnchor Reference to the ConnectAnchor object.
    * @return True, if test set up was successful False, if test set up was not
    *         successful
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;

     
         iDistributedVirtualSwitch = new DistributedVirtualSwitch(connectAnchor);
         capability = new DVSCapability();
         DVSFeatureCapability featureCapability = new DVSFeatureCapability();
         featureCapability.setNetworkResourceManagementSupported(true);
         capability.setFeaturesSupported(featureCapability);
         assertNotNull(capability, "Successfully created  the productSpec",
                  "Null returned for productSpec");

         setupDone = true;
     
      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   /**
    * Test Logic
    * 
    * @param connectAnchor - Reference to the ConnectAnchor object
    */
   @Override
   @Test(description = "Create a vDs by passing "
               + "capability.featuresSupported.networkResourcePoolSupported"
               + " to true.")
   public void test()
      throws Exception
   {
      try {
         DVSCreateSpec createSpec = null;
         createSpec = DVSUtil.createDVSCreateSpec(
                  DVSUtil.createDefaultDVSConfigSpec(null), null, capability);
         dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor, createSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Setting the expected Exception.
    */
   @Override
   public MethodFault getExpectedMethodFault()
   {
      return new InvalidArgument();
   }

   /**
    * Method to restore the state, as it was, before setting up the test
    * environment.
    * 
    * @param connectAnchor Reference to the ConnectAnchor object
    * @return True, if test clean up was successful False, if test clean up was
    *         not successful
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanupDone = true;
     
         if (this.dvsMor != null) {
            assertTrue(
                     (cleanupDone &= this.iDistributedVirtualSwitch.destroy(dvsMor)),
                     "Successfully deleted DVS", "Unable to delete DVS");
         }

     
      assertTrue(cleanupDone, "Cleanup failed");
      return cleanupDone;
   }
}
