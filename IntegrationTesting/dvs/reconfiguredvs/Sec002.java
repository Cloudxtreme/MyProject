/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSContactInfo;
import com.vmware.vc.DVSFailureCriteria;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.NoPermission;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.PrivilegeConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch with a valid config version by users having
 * no privileges.
 */
public class Sec002 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private VMwareDVSConfigSpec deltaConfigSpec = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private int roleId;
   private ManagedObjectReference authManagerMor;
   final String[] privileges =
            { "DVSwitch.Modify", PrivilegeConstants.DVSWITCH_PORTSETTING,
                     PrivilegeConstants.DVSWITCH_POLICYOP };
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private AuthorizationManager authentication = null;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch with a valid"
               + " config version by users having no privileges.");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVSNameArrayUplinkPortPolicy uplinkPortPolicy = null;
      log.info("Test setup Begin:");

      if (super.testSetUp()) {
         this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
         if (this.networkFolderMor != null) {
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setName(this.getClass().getName());
            this.dvsMOR =
                     this.iFolder.createDistributedVirtualSwitch(
                              this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               this.deltaConfigSpec = new VMwareDVSConfigSpec();
               VMwareDVSPortSetting portSetting =
                        (VMwareDVSPortSetting) this.iDistributedVirtualSwitch
                                 .getConfig(this.dvsMOR).getDefaultPortConfig();
               DVSTrafficShapingPolicy inShapingPolicy =
                        new DVSTrafficShapingPolicy();
               DVSTrafficShapingPolicy outShapingPolicy =
                        new DVSTrafficShapingPolicy();
               DVSSecurityPolicy security = new DVSSecurityPolicy();
               DVSFailureCriteria failureCriteria = new DVSFailureCriteria();
               VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy =
                        new VmwareUplinkPortTeamingPolicy();
               VMwareUplinkPortOrderPolicy portOrderPolicy =
                        new VMwareUplinkPortOrderPolicy();
               String dvsDescription =
                        DVSTestConstants.DVS_RECONFIG_NAME_PREFIX
                                 + "Pos005 Description";
               this.deltaConfigSpec.setDescription(dvsDescription);
               this.deltaConfigSpec.setMaxPorts(11);
               this.deltaConfigSpec.setNumStandalonePorts(3);
               DVSContactInfo contactInfo = new DVSContactInfo();
               contactInfo
                        .setName("Contact "
                                 + DVSTestConstants.DVS_RECONFIG_NAME_PREFIX
                                 + " Pos012");
               contactInfo.setContact("Contact "
                        + DVSTestConstants.DVS_RECONFIG_NAME_PREFIX
                        + "Pos012 Description");
               this.deltaConfigSpec.setContact(contactInfo);
               this.deltaConfigSpec.setMaxMtu(9000);
               portSetting.setBlocked(DVSUtil.getBoolPolicy(false, new Boolean(
                        false)));
               inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                        new Boolean(true)));
               inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false,
                        (long) 102400));
               inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(false,
                        (long) 102400));
               inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                        (long) 102400));
               outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                        new Boolean(true)));
               outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(false,
                        (long) 102400));
               outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                        false, (long) 102400));
               outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                        (long) 102400));
               portSetting.setInShapingPolicy(inShapingPolicy);
               portSetting.setOutShapingPolicy(outShapingPolicy);
               security.setAllowPromiscuous(DVSUtil.getBoolPolicy(false,
                        new Boolean(false)));
               security.setMacChanges(DVSUtil.getBoolPolicy(false, new Boolean(
                        true)));
               security.setForgedTransmits(DVSUtil.getBoolPolicy(false,
                        new Boolean(true)));
               portSetting.setSecurityPolicy(security);
               failureCriteria.setCheckBeacon(DVSUtil.getBoolPolicy(false,
                        new Boolean(true)));
               failureCriteria.setCheckDuplex(DVSUtil.getBoolPolicy(false,
                        new Boolean(true)));
               failureCriteria.setCheckErrorPercent(DVSUtil.getBoolPolicy(
                        false, new Boolean(true)));
               failureCriteria.setCheckSpeed(DVSUtil.getStringPolicy(false,
                        "exact"));
               failureCriteria.setFullDuplex(DVSUtil.getBoolPolicy(false,
                        new Boolean(true)));
               failureCriteria.setPercentage(DVSUtil.getIntPolicy(false, 10));
               failureCriteria.setSpeed(DVSUtil.getIntPolicy(false, 50));
               uplinkTeamingPolicy.setFailureCriteria(failureCriteria);
               uplinkTeamingPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(
                        false, new Boolean(true)));
               uplinkTeamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
                        "loadbalance_ip"));
               uplinkTeamingPolicy.setReversePolicy(DVSUtil.getBoolPolicy(
                        false, new Boolean(true)));
               uplinkTeamingPolicy.setRollingOrder(DVSUtil.getBoolPolicy(false,
                        new Boolean(true)));
               portOrderPolicy.getActiveUplinkPort().clear();
               portOrderPolicy.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { "uplink1",
                        "uplink2" }));
               portOrderPolicy.getStandbyUplinkPort().clear();
               portOrderPolicy.getStandbyUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { "uplink3",
                        "uplink4" }));
               uplinkTeamingPolicy.setUplinkPortOrder(portOrderPolicy);
               portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
               this.deltaConfigSpec.setDefaultPortConfig(portSetting);
               uplinkPortPolicy = new DVSNameArrayUplinkPortPolicy();
               uplinkPortPolicy.getUplinkPortName().clear();
               uplinkPortPolicy.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { "uplink1",
                        "uplink2", "uplink3", "uplink4" }));
               this.deltaConfigSpec.setUplinkPortPolicy(uplinkPortPolicy);
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               List<ManagedObjectReference> dvPortgroupMorList = null;
               this.dvPortgroupConfigSpec.setName(this.getTestId());
               this.dvPortgroupConfigSpec
                        .setType(DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value());
               this.dvPortgroupConfigSpec.setNumPorts(4);
               this.dvPortgroupConfigSpec
                        .setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
               dvPortgroupMorList =
                        this.iDistributedVirtualSwitch
                                 .addPortGroups(
                                          this.dvsMOR,
                                          new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
               if (dvPortgroupMorList != null
                        && dvPortgroupMorList.get(0) != null) {
                  log.info("The portgroup was successfully"
                           + " added to the dvswitch");
                  this.deltaConfigSpec
                           .setConfigVersion(this.iDistributedVirtualSwitch
                                    .getConfig(this.dvsMOR).getConfigVersion());
                  this.deltaConfigSpec.getUplinkPortgroup().clear();
                  this.deltaConfigSpec.getUplinkPortgroup()
                           .addAll(com.vmware.vcqa.util.TestUtil.arrayToVector((ManagedObjectReference[]) TestUtil
                                    .vectorToArray((Vector) dvPortgroupMorList)));

                  authHelper =
                           new AuthorizationHelper(
                                    connectAnchor,
                                    getTestId(),
                                    true,
                                    data
                                             .getString(TestConstants.TESTINPUT_USERNAME),
                                    data
                                             .getString(TestConstants.TESTINPUT_PASSWORD));
                  authHelper
                           .setPermissions(dvsMOR, privileges, testUser, false);
                  return authHelper.performSecurityTestsSetup(testUser);

               } else {
                  log.error("Failed to add the portgroup to" + " the dvswitch");
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
   @Test(description = "Reconfigure an existing DVSwitch with a valid"
               + " config version by users having no privileges.")
   public void test()
      throws Exception
   {
      try {
         log.info("Test Begin:");
         boolean status = false;
         status =
                  this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                           this.deltaConfigSpec);
         assertTrue(status, "Test Failed");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvsMOR);
         expectedMethodFault.setPrivilegeId(PrivilegeConstants.DVSWITCH_MODIFY);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         if (authHelper != null) {
            status = authHelper.performSecurityTestsCleanup();
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

}
