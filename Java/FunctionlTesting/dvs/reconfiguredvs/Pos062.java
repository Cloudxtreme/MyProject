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
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchPvlanSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS as follows: - Set the DVSConfigSpec.configVersion
 * to a valid config version string - Set DVPortSetting.blocked to false - Set
 * DVPortSetting.pvlanID to a primary pvlanId that belongs to the pvlanMapEntry,
 * community type.
 */
public class Pos062 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private DistributedVirtualSwitchHelper iVmwareDVS = null;
   public static final int PVLAN1_SEC_1 = 101;
   public static final int PVLAN1_PRI_1 = 10;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS as follows:\n"
               + " - Set the DVSConfigSpec.configVersion to a valid config version "
               + "string,\n"
               + " - Set DVPortSetting.blocked to false,\n"
               + " - Set DVPortSetting.pvlanID to a primary pvlanId that belongs to the"
               + " pvlanMapEntry, community type.");
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
      VMwareDVSPortSetting portSetting = null;
      VmwareDistributedVirtualSwitchPvlanSpec pvlanSpec = null;
      DVSConfigInfo configInfo = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               iVmwareDVS = new DistributedVirtualSwitchHelper(connectAnchor);
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  if (configInfo.getDefaultPortConfig() instanceof VMwareDVSPortSetting) {
                     this.deltaConfigSpec = new DVSConfigSpec();
                     portSetting = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
                     if (iVmwareDVS.addSecondaryPvlan(this.dvsMOR,
                              DVSTestConstants.PVLAN_TYPE_COMMINITY,
                              PVLAN1_PRI_1, PVLAN1_SEC_1, true)) {
                        String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                                 dvsMOR).getConfigVersion();
                        this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                        portSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                                 new Boolean(true)));
                        pvlanSpec = new VmwareDistributedVirtualSwitchPvlanSpec();
                        pvlanSpec.setPvlanId(PVLAN1_SEC_1);
                        portSetting.setVlan(pvlanSpec);
                        this.deltaConfigSpec.setDefaultPortConfig(portSetting);
                        status = true;
                     } else {
                        log.error("Unable to add primary PVLAN.");
                     }
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
   @Test(description = "Reconfigure an existing DVS as follows:\n"
               + " - Set the DVSConfigSpec.configVersion to a valid config version "
               + "string,\n"
               + " - Set DVPortSetting.blocked to false,\n"
               + " - Set DVPortSetting.pvlanID to a primary pvlanId that belongs to the"
               + " pvlanMapEntry, community type.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         assertTrue(status, "Test Failed");
     
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