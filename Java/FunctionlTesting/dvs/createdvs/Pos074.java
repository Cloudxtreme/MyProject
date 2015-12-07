/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortSetting;
import com.vmware.vc.DVSFailureCriteria;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.NumericRange;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareDistributedVirtualSwitchTrunkVlanSpec;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

public class Pos074 extends CreateDVSTestBase
{
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;
   private VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder."
               + " Enable LBT(Dynamic Load Balancer in NIC Teaming) as"
               + " the teaming policy");
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
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      VMwareDVSConfigSpec vmwareDVSConfigSpec = null;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      String[] uplinkPortNames = null;
      log.info("Test setup Begin:");
      status = super.testSetUp();
      this.ihs = new HostSystem(connectAnchor);
      this.iNetworkSystem = new NetworkSystem(connectAnchor);
      allHosts = this.ihs.getAllHost();
      assertNotNull(allHosts, "No hosts were found in inventory");
      this.hostMor = (ManagedObjectReference) allHosts.get(0);
      this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
      assertNotNull(this.networkFolderMor, "The network folder mor is null");
      vmwareDVSConfigSpec = new VMwareDVSConfigSpec();
      vmwareDVSConfigSpec.setConfigVersion("");
      vmwareDVSConfigSpec.setName(this.getClass().getName());
      String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
      if (physicalNics != null) {
         pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(physicalNics[0]);
         pnicSpec.setUplinkPortKey(null);
         uplinkPortNames = new String[physicalNics.length + 1];
         for (int i = 0; i <= physicalNics.length; i++) {
            uplinkPortNames[i] = "uplink" + i;
         }
         vmwareDVSConfigSpec.setMaxPorts(2 * uplinkPortNames.length + 1);
         vmwareDVSConfigSpec.setNumStandalonePorts(uplinkPortNames.length + 1);
         uplinkPolicyInst.getUplinkPortName().clear();
         uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
         vmwareDVSConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
         pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
         VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
         DVSTrafficShapingPolicy inShapingPolicy = null;
         DVSTrafficShapingPolicy outShapingPolicy = null;
         DVSSecurityPolicy securitPolicy = new DVSSecurityPolicy();
         VmwareDistributedVirtualSwitchTrunkVlanSpec trunkVlanSpec = new VmwareDistributedVirtualSwitchTrunkVlanSpec();
         NumericRange vlanIDRange = new NumericRange();
         DVSFailureCriteria failureCriteria = null;
         VMwareUplinkPortOrderPolicy portOrderPolicy = null;
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         hostConfigSpecElement.setBacking(pnicBacking);
         hostConfigSpecElement.setHost(this.hostMor);
         hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
                  uplinkPortNames.length + 1));
         hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
         vmwareDVSConfigSpec.getHost().clear();
         vmwareDVSConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
         portSetting.setBlocked(DVSUtil.getBoolPolicy(false, true));
         inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                  (long) 102400, (long) 102400, (long) 102400);
         outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
                  (long) 102400, (long) 102400, (long) 102400);
         portSetting.setInShapingPolicy(inShapingPolicy);
         portSetting.setOutShapingPolicy(outShapingPolicy);
         securitPolicy = DVSUtil.getDVSSecurityPolicy(false, false, true, true);
         portSetting.setSecurityPolicy(securitPolicy);
         vlanIDRange.setStart(1);
         vlanIDRange.setEnd(20);
         trunkVlanSpec.getVlanId().clear();
         trunkVlanSpec.getVlanId().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new NumericRange[] { vlanIDRange }));
         trunkVlanSpec.setInherited(false);
         portSetting.setVlan(trunkVlanSpec);
         failureCriteria = DVSUtil.getFailureCriteria(false, "exact", 50, true,
                  true, true, 10, true);
         portOrderPolicy = DVSUtil.getPortOrderPolicy(false,
                  new String[] { uplinkPortNames[0] },
                  new String[] { uplinkPortNames[1] });
         uplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(false,
                  "loadbalance_loadbased", true, true, true, failureCriteria,
                  portOrderPolicy);
         portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
         vmwareDVSConfigSpec.setDefaultPortConfig(portSetting);
         vmwareDVSConfigSpec.setMaxMtu(1500);
         this.configSpec = vmwareDVSConfigSpec;
      } else {
         log.info("No physical nics found on the host");
      }
      return true;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    * @throws Exception
    */
   @Test(description = "Create a DVSwitch inside a valid folder."
               + " Enable LBT(Dynamic Load Balancer in NIC Teaming) as"
               + " the teaming policy")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
               this.networkFolderMor, this.configSpec);
      assertNotNull(this.dvsMOR, "Successfully created the distributed "
               + "virtual switch",
               "Failed to create the distributed virtual switch");
      VmwareUplinkPortTeamingPolicy actualUplinkPortTeamingPolicy = null;
      DVPortSetting actualSetting = this.iDistributedVirtualSwitch.getConfig(
               this.dvsMOR).getDefaultPortConfig();
      assertTrue(
               actualSetting instanceof VMwareDVSPortSetting,
               "The port "
                        + "setting on the vds is not an instance of the VMwareDVSPortSetting");
      VMwareDVSPortSetting actualVMPortSetting = (VMwareDVSPortSetting) actualSetting;
      actualUplinkPortTeamingPolicy = actualVMPortSetting.getUplinkTeamingPolicy();
      assertNotNull(actualUplinkPortTeamingPolicy, "The uplink teaming "
               + "policy on vds port setting is null");
      assertTrue(TestUtil.compareObject(actualUplinkPortTeamingPolicy,
               uplinkTeamingPolicy, null),
               "The uplink teaming policy was set on " + "the vds",
               "The uplink teaming policy was not set on the vds");
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
      return super.testCleanUp();
   }

}