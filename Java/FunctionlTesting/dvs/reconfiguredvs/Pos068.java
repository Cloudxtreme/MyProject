/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSFailureCriteria;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualPortgroupPortgroupType;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.NumericRange;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareDistributedVirtualSwitchTrunkVlanSpec;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting - ManagedObjectReference to a
 * valid DVSwitch Mor - DVSConfigSpec.configVersion to a valid config version
 * string - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid
 * number - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid
 * number - DVSPortSetting.blocked to false - DVSPortSetting.pvlanIdRange to an
 * invalid vlan id range.
 */

public class Pos068 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor1 = null;
   private ManagedObjectReference hostMor2 = null;
   private HostSystem ihs = null;
   private NetworkSystem iNetworkSystem = null;

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
               + " - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid "
               + "number,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid "
               + "number,\n"
               + " - DVSPortSetting.blocked to false,\n"
               + " - DVSPortSetting.pvlanIdRange to an invalid vlan id range.");
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
      DistributedVirtualSwitchHostMemberPnicSpec hostOnepnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking hostOnePnicBacking = null;
      String[] uplinkPortNames = null;
      DVSConfigInfo configInfo = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.iNetworkSystem = new NetworkSystem(connectAnchor);
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               allHosts = this.ihs.getAllHost();

               if (allHosts != null) {
                  this.hostMor1 = (ManagedObjectReference) allHosts.get(0);
                  this.hostMor2 = (ManagedObjectReference) allHosts.get(1);
               } else {
                  log.error("Valid Host MOR not found");
               }
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               DistributedVirtualSwitchHostMemberConfigSpec initialHostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               initialHostConfigSpecElement.setHost(this.hostMor2);
               initialHostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { initialHostConfigSpecElement }));
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  if (configInfo.getDefaultPortConfig() instanceof VMwareDVSPortSetting) {
                     DistributedVirtualSwitchHostMemberConfigSpec[] hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec[2];
                     DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
                     String dvsName = DVSTestConstants.DVS_RECONFIG_NAME_PREFIX
                              + "Pos002";
                     this.deltaConfigSpec = new DVSConfigSpec();
                     this.deltaConfigSpec.setName(dvsName);
                     String[] hostOnephysicalNics = iNetworkSystem.getPNicIds(this.hostMor1);
                     if (hostOnephysicalNics != null) {
                        hostOnepnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                        hostOnepnicSpec.setPnicDevice(hostOnephysicalNics[0]);
                        hostOnepnicSpec.setUplinkPortKey(null);
                     }
                     uplinkPortNames = new String[hostOnephysicalNics.length];
                     for (int i = 0; i < hostOnephysicalNics.length; i++)
                        uplinkPortNames[i] = "Uplink" + i;
                     uplinkPolicyInst.getUplinkPortName().clear();
                     uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                     this.deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
                     VMwareDVSPortSetting portSetting = (VMwareDVSPortSetting) configInfo.getDefaultPortConfig();
                     VmwareDistributedVirtualSwitchTrunkVlanSpec trunkVlanSpec = new VmwareDistributedVirtualSwitchTrunkVlanSpec();
                     NumericRange vlanIDRange = new NumericRange();
                     DVSTrafficShapingPolicy inShapingPolicy = new DVSTrafficShapingPolicy();
                     DVSTrafficShapingPolicy outShapingPolicy = new DVSTrafficShapingPolicy();
                     VmwareUplinkPortTeamingPolicy teamingPolicy = new VmwareUplinkPortTeamingPolicy();
                     DVSFailureCriteria failureCriteria = new DVSFailureCriteria();
                     DVSSecurityPolicy securitPolicy = new DVSSecurityPolicy();
                     VMwareUplinkPortOrderPolicy portOrderPolicy = new VMwareUplinkPortOrderPolicy();
                     uplinkPolicyInst.getUplinkPortName().clear();
                     uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                     // set the max ports to be the sum of the number of uplink
                     // ports, and the standalone ports, and number of ports in
                     // the
                     // port group.
                     this.deltaConfigSpec.setMaxPorts(hostOnephysicalNics.length + 4 + 2);
                     this.deltaConfigSpec.setNumStandalonePorts(4);
                     for (int i = 0; i < hostConfigSpecElement.length; i++) {
                        hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                     }
                     hostOnePnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                     hostOnePnicBacking.getPnicSpec().clear();
                     hostOnePnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { hostOnepnicSpec }));
                     hostConfigSpecElement[0].setBacking(hostOnePnicBacking);
                     hostConfigSpecElement[0].setHost(this.hostMor1);
                     hostConfigSpecElement[1].setHost(this.hostMor2);
                     hostConfigSpecElement[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
                     hostConfigSpecElement[1].setOperation(TestConstants.CONFIG_SPEC_REMOVE);
                     hostConfigSpecElement[0].setMaxProxySwitchPorts(uplinkPortNames.length + 1);
                     this.deltaConfigSpec.getHost().clear();
                     this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
                     portSetting.setBlocked(DVSUtil.getBoolPolicy(false,
                              new Boolean(false)));
                     this.deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
                     inShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                              true));
                     inShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(
                              false, (long) 102400));
                     inShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                              false, (long) 102400));
                     inShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                              (long) 102400));
                     outShapingPolicy.setEnabled(DVSUtil.getBoolPolicy(false,
                              new Boolean(true)));
                     outShapingPolicy.setPeakBandwidth(DVSUtil.getLongPolicy(
                              false, (long) 102400));
                     outShapingPolicy.setAverageBandwidth(DVSUtil.getLongPolicy(
                              false, (long) 102400));
                     outShapingPolicy.setBurstSize(DVSUtil.getLongPolicy(false,
                              (long) 102400));
                     portSetting.setInShapingPolicy(inShapingPolicy);
                     portSetting.setOutShapingPolicy(outShapingPolicy);
                     failureCriteria.setCheckBeacon(DVSUtil.getBoolPolicy(
                              false, new Boolean(true)));
                     failureCriteria.setCheckDuplex(DVSUtil.getBoolPolicy(
                              false, new Boolean(true)));
                     failureCriteria.setCheckErrorPercent(DVSUtil.getBoolPolicy(
                              false, new Boolean(true)));
                     failureCriteria.setCheckSpeed(DVSUtil.getStringPolicy(
                              false, "exact"));
                     failureCriteria.setFullDuplex(DVSUtil.getBoolPolicy(false,
                              new Boolean(true)));
                     failureCriteria.setPercentage(DVSUtil.getIntPolicy(false,
                              10));
                     failureCriteria.setSpeed(DVSUtil.getIntPolicy(false, 50));
                     teamingPolicy.setFailureCriteria(failureCriteria);
                     teamingPolicy.setNotifySwitches(DVSUtil.getBoolPolicy(
                              false, true));
                     teamingPolicy.setReversePolicy(DVSUtil.getBoolPolicy(
                              false, true));
                     teamingPolicy.setRollingOrder(DVSUtil.getBoolPolicy(false,
                              true));
                     teamingPolicy.setPolicy(DVSUtil.getStringPolicy(false,
                              "loadbalance_ip"));
                     this.deltaConfigSpec.setDefaultPortConfig(portSetting);
                     portOrderPolicy.getActiveUplinkPort().clear();
                     portOrderPolicy.getActiveUplinkPort().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                     teamingPolicy.setUplinkPortOrder(portOrderPolicy);
                     portSetting.setUplinkTeamingPolicy(teamingPolicy);
                     securitPolicy.setAllowPromiscuous(DVSUtil.getBoolPolicy(
                              false, true));
                     securitPolicy.setForgedTransmits(DVSUtil.getBoolPolicy(
                              false, true));
                     securitPolicy.setMacChanges(DVSUtil.getBoolPolicy(false,
                              true));
                     portSetting.setSecurityPolicy(securitPolicy);
                     vlanIDRange.setStart(1);
                     vlanIDRange.setEnd(20);
                     trunkVlanSpec.getVlanId().clear();
                     trunkVlanSpec.getVlanId().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new NumericRange[] { vlanIDRange }));
                     portSetting.setVlan(trunkVlanSpec);
                     this.deltaConfigSpec.setDefaultPortConfig(portSetting);
                     this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
                     List<ManagedObjectReference> dvPortgroupMorList = null;
                     this.dvPortgroupConfigSpec.setName(this.getClass().getName()
                              + "-upg");
                     this.dvPortgroupConfigSpec.setType(DistributedVirtualPortgroupPortgroupType.EARLY_BINDING.value());
                     this.dvPortgroupConfigSpec.setNumPorts(2);
                     this.dvPortgroupConfigSpec.setPortNameFormat(DVSTestConstants.DVPORTGROUP_PORTNAMEFORMAT_PORTINDEX);
                     dvPortgroupMorList = this.iDistributedVirtualSwitch.addPortGroups(
                              this.dvsMOR,
                              new DVPortgroupConfigSpec[] { this.dvPortgroupConfigSpec });
                     if (dvPortgroupMorList != null
                              && dvPortgroupMorList.get(0) != null) {
                        log.info("The portgroup was successfully"
                                 + " added to the dvswitch");
                        this.deltaConfigSpec.getUplinkPortgroup().clear();
                        this.deltaConfigSpec.getUplinkPortgroup().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { dvPortgroupMorList.get(0) }));
                        this.deltaConfigSpec.setConfigVersion(this.iDistributedVirtualSwitch.getConfig(
                                 this.dvsMOR).getConfigVersion());
                        status = true;
                     } else {
                        log.error("Failed to add the portgroup to the"
                                 + " dvswitch");
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
   @Test(description = "Reconfigure an existing DVSwitch by setting:\n "
               + " - ManagedObjectReference to a valid DVSwitch Mor,\n"
               + " - DVSConfigSpec.configVersion to a valid config version string,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.maxPorts to a valid "
               + "number,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.numPorts to a valid "
               + "number,\n"
               + " - DVSPortSetting.blocked to false,\n"
               + " - DVSPortSetting.pvlanIdRange to an invalid vlan id range.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
     
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