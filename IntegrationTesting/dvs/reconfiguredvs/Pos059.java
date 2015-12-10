/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.NumericRange;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VmwareDistributedVirtualSwitchTrunkVlanSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS as follows: - Set the DVSConfigSpec.configVersion
 * to a valid config version string - Set DVPortSetting.blocked to false - Set
 * DVPortSetting.mtu to 102400 - Set DVPortSetting.securityPolicy to a valid
 * policy - Set DVPortSetting.vlan to a vlan Trunking vlan id range [1 - 20]
 */
public class Pos059 extends CreateDVSTestBase
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
      super.setTestDescription("Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set DVPortSetting.blocked to true,\n"
               + "  - Set DVPortSetting.mtu to 102400,\n"
               + "  - Set DVPortSetting.securityPolicy to a valid policy,\n"
               + "  - Set DVPortSetting.vlan to a vlan Trunking vlan id range [1 - 20].");
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
      DVSConfigInfo configInfo = null;
      DVSSecurityPolicy securityPolicy = null;
      VmwareDistributedVirtualSwitchTrunkVlanSpec trunkVlanSpec = null;
     
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
                  configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  if (configInfo.getDefaultPortConfig() instanceof VMwareDVSPortSetting) {
                     this.deltaConfigSpec = new DVSConfigSpec();
                     VMwareDVSPortSetting portSetting = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
                     securityPolicy = portSetting.getSecurityPolicy();
                     if (securityPolicy == null) {
                        securityPolicy = DVSUtil.getDVSSecurityPolicy(false,
                                 Boolean.FALSE, Boolean.TRUE, Boolean.TRUE);
                     } else {
                        securityPolicy.setAllowPromiscuous(DVSUtil.getBoolPolicy(
                                 false, Boolean.FALSE));
                        securityPolicy.setForgedTransmits(DVSUtil.getBoolPolicy(
                                 false, Boolean.TRUE));
                        securityPolicy.setMacChanges(DVSUtil.getBoolPolicy(
                                 false, Boolean.TRUE));
                     }
                     trunkVlanSpec = new VmwareDistributedVirtualSwitchTrunkVlanSpec();
                     trunkVlanSpec.setInherited(false);

                     NumericRange vlanIDRange = new NumericRange();
                     String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                              dvsMOR).getConfigVersion();
                     this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                     Boolean True = Boolean.valueOf(true);
                     Boolean False = Boolean.valueOf(false);
                     portSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                              Boolean.FALSE));
                     portSetting.setSecurityPolicy(securityPolicy);
                     vlanIDRange.setStart(1);
                     vlanIDRange.setEnd(20);
                     trunkVlanSpec.getVlanId().clear();
                     trunkVlanSpec.getVlanId().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new NumericRange[] { vlanIDRange }));
                     portSetting.setVlan(trunkVlanSpec);
                     this.deltaConfigSpec.setDefaultPortConfig(portSetting);
                     status = true;
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
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set DVPortSetting.blocked to true,\n"
               + "  - Set DVPortSetting.mtu to 102400,\n"
               + "  - Set DVPortSetting.securityPolicy to a valid policy,\n"
               + "  - Set DVPortSetting.vlan to a vlan Trunking vlan id range [1 - 20].")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         if (status) {
            log.info("Successfully reconfigured DVS");
            Vector<String> ignoredProperties = TestUtil.getIgnorePropertyList(
                     this.deltaConfigSpec, false);
            if (!ignoredProperties.contains(DVSTestConstants.DVS_CONFIGVERSION)) {
               ignoredProperties.add(DVSTestConstants.DVS_CONFIGVERSION);
            }
            if ((TestUtil.compareObject(
                     iDistributedVirtualSwitch.getConfigSpec(dvsMOR),
                     this.deltaConfigSpec, ignoredProperties))) {
               status = true;
            } else {
               log.info("The config spec of the Distributed Virtual Switch"
                        + "is not reconfigured as per specifications");
               status = false;
            }
         } else {
            log.error("Failed to reconfigure dvs");
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