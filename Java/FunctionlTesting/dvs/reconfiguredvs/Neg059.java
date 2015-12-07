/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting the ManagedObjectReference to a
 * valid DVSwitch Mor and DVSConfigSpec.configVersion to a valid config version
 * string and uplinkPortgroup to an invalid array.
 */

public class Neg059 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DVSConfigSpec deltaConfigSpec = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpec = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and "
               + "uplinkPortgroup to an invalid array.");
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
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  ;
                  this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec[2];
                  for (int i = 0; i < 2; i++) {
                     this.dvPortgroupConfigSpec[i] = new DVPortgroupConfigSpec();
                  }
                  List<ManagedObjectReference> dvPortgroupMorList = null;
                  this.dvPortgroupConfigSpec[0].setName(this.getTestId() + "2");
                  this.dvPortgroupConfigSpec[0].setType(DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value());
                  this.dvPortgroupConfigSpec[0].setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
                  this.dvPortgroupConfigSpec[1].setName(this.getTestId());
                  this.dvPortgroupConfigSpec[1].setType(DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value());
                  this.dvPortgroupConfigSpec[1].setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
                  dvPortgroupMorList = this.iDistributedVirtualSwitch.addPortGroups(
                           this.dvsMOR, this.dvPortgroupConfigSpec);
                  this.iManagedEntity.destroy(dvPortgroupMorList.get(1));
                  if (dvPortgroupMorList != null
                           && dvPortgroupMorList.get(0) != null) {
                     log.info("The portgroup was successfully"
                              + " added to the dvswitch");
                     this.deltaConfigSpec = new DVSConfigSpec();
                     String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                              dvsMOR).getConfigVersion();
                     this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                     this.deltaConfigSpec.getUplinkPortgroup().clear();
                     this.deltaConfigSpec.getUplinkPortgroup().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector((ManagedObjectReference[]) TestUtil.vectorToArray((Vector) dvPortgroupMorList)));
                     status = true;
                  } else {
                     log.error("Failed to add the portgroup to the"
                              + " dvswitch");
                  }
                  status = true;
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         }
     
      Assert.assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing DVSwitch by setting "
               + "the ManagedObjectReference to a valid DVSwitch Mor and "
               + "DVSConfigSpec.configVersion to a valid config version string and "
               + "uplinkPortgroup to an invalid array.")
   public void test()
      throws Exception
   {
      try {
         this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new ManagedObjectNotFound();
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
      return new ManagedObjectNotFound();
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
     
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }
}