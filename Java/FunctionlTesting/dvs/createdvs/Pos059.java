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

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Create a DVSwitch inside a valid folder with the following configuration:
 * configVersion - empty string name - "Create DVS-Pos059" numPort - valid
 * number maxPort - valid number For DVPortSetting: blocked - false
 * uplinkTeamingPolicy.notifySwitches - false uplinkTeamingPolicy.reversePolicy
 * - false uplinkTeamingPolicy.rollingOrder - false
 * uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort - valid array containing
 * valid uplink port names
 */

public class Pos059 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private VMwareUplinkPortOrderPolicy portOrderPolicy = null;
   private VMwareDVSPortSetting dvPort = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder with"
               + "the following configuration:\n "
               + "configVersion - empty string\n"
               + "name - 'Create DVS-Pos059'\n "
               + "numPort - valid number\n"
               + "maxPort - valid number\n"
               + "For DVPortSetting:\n"
               + "blocked - false\n"
               + "uplinkTeamingPolicy.notifySwitches - false\n "
               + "uplinkTeamingPolicy.reversePolicy - false\n"
               + "uplinkTeamingPolicy.rollingOrder - false\n"
               + "uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort - valid array"
               + "containing valid uplink port names.\n");
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
            this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                     connectAnchor);
            this.networkFolderMor = this.iFolder.getNetworkFolder(dcMor);
            if (this.networkFolderMor != null) {
               VmwareUplinkPortTeamingPolicy portTeamingPolicy = new VmwareUplinkPortTeamingPolicy();
               this.portOrderPolicy = new VMwareUplinkPortOrderPolicy();
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(getTestId());
               dvPort = new VMwareDVSPortSetting();
               dvPort.setBlocked(DVSUtil.getBoolPolicy(false, false));
               portTeamingPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(false,
                        false));
               portTeamingPolicy.setReversePolicy(DVSUtil.getBoolPolicy(false,
                        false));
               portTeamingPolicy.setRollingOrder(DVSUtil.getBoolPolicy(false,
                        false));
               this.portOrderPolicy.setInherited(false);
               this.portOrderPolicy.getActiveUplinkPort().clear();
               this.portOrderPolicy.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {
                        "uplink1", "uplink2" }));
               this.portOrderPolicy.getStandbyUplinkPort().clear();
               this.portOrderPolicy.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {}));
               portTeamingPolicy.setUplinkPortOrder(this.portOrderPolicy);
               dvPort.setUplinkTeamingPolicy(portTeamingPolicy);
               this.configSpec.setDefaultPortConfig(dvPort);
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
   @Test(description = "Create a DVSwitch inside a valid folder with"
               + "the following configuration:\n "
               + "configVersion - empty string\n"
               + "name - 'Create DVS-Pos059'\n "
               + "numPort - valid number\n"
               + "maxPort - valid number\n"
               + "For DVPortSetting:\n"
               + "blocked - false\n"
               + "uplinkTeamingPolicy.notifySwitches - false\n "
               + "uplinkTeamingPolicy.reversePolicy - false\n"
               + "uplinkTeamingPolicy.rollingOrder - false\n"
               + "uplinkTeamingPolicy.uplinkPortOrder.activeUplinkPort - valid array"
               + "containing valid uplink port names.\n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      DVSConfigInfo configInfo = null;
      VMwareDVSPortSetting portSetting = null;
      boolean status = false;
     
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
               portSetting = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
               if (iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
                        this.configSpec, null)
                        && TestUtil.compareArray(
                                 com.vmware.vcqa.util.TestUtil.vectorToArray(portSetting.getUplinkTeamingPolicy().getUplinkPortOrder().getActiveUplinkPort(), java.lang.String.class),
                                 com.vmware.vcqa.util.TestUtil.vectorToArray(this.portOrderPolicy.getActiveUplinkPort(), java.lang.String.class))) {
                  log.info("Successfully compared the actual and "
                           + "expected config spec");
                  if (super.verifyPortSettingOnHost(connectAnchor, dvPort)) {
                     log.info("Verified the dv port setting on the host");
                     status = true;
                  } else {
                     log.error("Can not verify the dv port setting on the host");
                  }
               } else {
                  log.info("The config spec of the Distributed Virtual Switch"
                           + "is not created as per specifications");
               }
            } else {
               log.error("Cannot create the distributed "
                        + "virtual switch with the config spec passed");
            }
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
      boolean status = false;
     
         status = super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}