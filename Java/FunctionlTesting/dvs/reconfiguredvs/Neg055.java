/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.*;

import java.util.HashMap;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting - ManagedObjectReference to a
 * valid DVSwitch Mor - DVSConfigSpec.configVersion to a valid config version
 * string - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid
 * number - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid
 * number - DVSPortSetting.blocked to false - DVSPortSetting.pvlanid to a number
 * that exists in the pvlan entry map
 */

public class Neg055 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private VMwareDVSConfigSpec deltaConfigSpec = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch by setting:\n "
               + " - ManagedObjectReference to a valid DVSwitch Mor,\n"
               + " - DVSConfigSpec.configVersion to a valid config version string,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid number,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid number,\n"
               + " - DVSPortSetting.blocked to false,\n"
               + " - DVSPortSetting.pvlanid to a number that exists in the pvlan entry "
               + "map.");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      VMwareDVSPortSetting portSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      Map<String, Object> settingsMap = null;
      log.info("Test setup Begin:");

         if (super.testSetUp()) {
            networkFolderMor = iFolder.getNetworkFolder(dcMor);
            if (networkFolderMor != null) {
               configSpec = new  DVSConfigSpec();
               configSpec.setName(this.getClass().getName());
               dvsMOR = iFolder.createDistributedVirtualSwitch(
                        networkFolderMor, configSpec);
               if (dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");

                  deltaConfigSpec = new VMwareDVSConfigSpec();
                  pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
                  pvlanSpec.setPvlanId(10);

                  settingsMap = new HashMap<String, Object>();
                  settingsMap.put(DVSTestConstants.VLAN_KEY, pvlanSpec);
                  portSetting = DVSUtil.getDefaultVMwareDVSPortSetting(settingsMap);
                  portSetting.setVlan(pvlanSpec);
                  final String validConfigVersion = iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  deltaConfigSpec.setConfigVersion(validConfigVersion);
                  deltaConfigSpec.setDefaultPortConfig(portSetting);
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
   @Test(description = "Reconfigure an existing DVSwitch by setting:\n "
               + " - ManagedObjectReference to a valid DVSwitch Mor,\n"
               + " - DVSConfigSpec.configVersion to a valid config version string,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid number,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid number,\n"
               + " - DVSPortSetting.blocked to false,\n"
               + " - DVSPortSetting.pvlanid to a number that exists in the pvlan entry "
               + "map.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         iDistributedVirtualSwitch.reconfigure(dvsMOR,
                  deltaConfigSpec);
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