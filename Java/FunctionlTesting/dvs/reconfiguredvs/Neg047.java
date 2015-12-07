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

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting - ManagedObjectReference to a
 * valid DVSwitch Mor - DVSConfigSpec.configVersion to a valid config version
 * string - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid
 * number - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid
 * number - DVSPortSetting .blocked to false - outShapingPolicy.enabled to true
 * - outShapingPolicy.averageBandWidth set to a negative number
 */

public class Neg047 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
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
               + " - outShapingPolicy.enabled to true,\n"
               + " - outShapingPolicy.averageBandWidth to a negative value.");
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
      DVSConfigInfo dvsInfo = null;
      DVPortSetting portSetting = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
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
                  this.deltaConfigSpec = new DVSConfigSpec();
                  dvsInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  portSetting = dvsInfo.getDefaultPortConfig();
                  if (portSetting == null) {
                     portSetting = (VMwareDVSPortSetting) DVSUtil.getDefaultVMwareDVSPortSetting(null);
                  }
                  outShapingPolicy = portSetting.getInShapingPolicy();
                  if (outShapingPolicy == null) {
                     outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false,
                              true, new Long(-1), null, null);
                  } else {
                     outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                              true));
                     outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                              false, new Long(-1)));
                  }
                  String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  this.deltaConfigSpec.setMaxPorts(6);
                  this.deltaConfigSpec.setNumStandalonePorts(4);
                  portSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                           new Boolean(false)));
                  portSetting.setOutShapingPolicy(outShapingPolicy);
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
               + " - outShapingPolicy.enabled to true,\n"
               + " - outShapingPolicy.averageBandWidth to a negative value.")
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