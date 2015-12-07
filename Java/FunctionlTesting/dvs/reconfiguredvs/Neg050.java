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

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting - ManagedObjectReference to a
 * valid DVSwitch Mor - DVSConfigSpec.configVersion to a valid config version
 * string - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid
 * number - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid
 * number - DVSPortSetting .blocked to false - uplinkTeamingPolicy.policy to an
 * invalid policy
 */

public class Neg050 extends CreateDVSTestBase
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
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch by setting:\n "
               + " - ManagedObjectReference to a valid DVSwitch Mor,\n"
               + " - DVSConfigSpec.configVersion to a valid config version string,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid number,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid number,\n"
               + " - DVSPortSetting .blocked to false,\n"
               + " - uplinkTeamingPolicy.policy to an invalid policy.");
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
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      VMwareDVSPortSetting portSetting = null;
      DVSConfigInfo dvsInfo = null;

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
                  this.deltaConfigSpec = new DVSConfigSpec();
                  dvsInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  portSetting = (VMwareDVSPortSetting) dvsInfo.getDefaultPortConfig();
                  if (portSetting == null) {
                     portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(null);
                  }
                  uplinkTeamingPolicy = portSetting.getUplinkTeamingPolicy();
                  if (uplinkTeamingPolicy == null) {
                     /*
                      * create uplinkTeamingPolicy
                      */
                     uplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(
                              false, "@#$%^", null, null, null, null, null);
                  } else {
                     uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(
                              false, "@#$%^"));
                  }
                  String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  this.deltaConfigSpec.setMaxPorts(6);
                  this.deltaConfigSpec.setNumStandalonePorts(4);
                  portSetting.setBlocked(DVSUtil.getBoolPolicy(false, false));
                  portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
                  this.deltaConfigSpec.setDefaultPortConfig(portSetting);
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
   @Test(description = "Reconfigure an existing DVSwitch by setting:\n "
               + " - ManagedObjectReference to a valid DVSwitch Mor,\n"
               + " - DVSConfigSpec.configVersion to a valid config version string,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid number,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid number,\n"
               + " - DVSPortSetting .blocked to false,\n"
               + " - uplinkTeamingPolicy.policy to an invalid policy.")
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
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}