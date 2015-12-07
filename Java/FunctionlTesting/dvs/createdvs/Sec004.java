/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_CREATE;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSFailureCriteria;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DVSSecurityPolicy;
import com.vmware.vc.DVSTrafficShapingPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.NumericRange;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkPortOrderPolicy;
import com.vmware.vc.VmwareDistributedVirtualSwitchTrunkVlanSpec;
import com.vmware.vc.VmwareUplinkPortTeamingPolicy;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.CreateDVSTestBase;

public class Sec004 extends CreateDVSTestBase
{
   private int roleId;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = DVSWITCH_CREATE;
   private AuthorizationManager authentication = null;

   @Override
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder by a"
               + " user not having DVSwitch.create privilege."
               + " The DVS parameters are to be set as follows:\n"
               + " - DVSConfigSpec.configVersion set to an empty string,\n"
               + " - DVSConfigSpec.name set to 'Create  DVS-Sec003'.");
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
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      VMwareDVSConfigSpec vmwareDVSConfigSpec = null;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      authentication = new AuthorizationManager(super.getConnectAnchor());
      String[] uplinkPortNames = null;
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_FAIL);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      vmwareDVSConfigSpec = new VMwareDVSConfigSpec();
      vmwareDVSConfigSpec.setConfigVersion("");
      vmwareDVSConfigSpec.setName(this.getClass().getName());
      String[] physicalNics = ins.getPNicIds(hostMor);
      assertNotEmpty(physicalNics, "No free physical nics found on the host");
      pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
      pnicSpec.setPnicDevice(physicalNics[0]);
      pnicSpec.setUplinkPortKey(null);
      uplinkPortNames = new String[physicalNics.length + 1];
      for (int i = 0; i <= physicalNics.length; i++) {
         uplinkPortNames[i] = "uplink" + i;
      }
      vmwareDVSConfigSpec.setMaxPorts(uplinkPortNames.length + 2);
      vmwareDVSConfigSpec.setNumStandalonePorts(uplinkPortNames.length + 1);
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      vmwareDVSConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
      VMwareDVSPortSetting portSetting = new VMwareDVSPortSetting();
      DVSTrafficShapingPolicy inShapingPolicy = null;
      DVSTrafficShapingPolicy outShapingPolicy = null;
      DVSSecurityPolicy securityPolicy = null;
      VmwareDistributedVirtualSwitchTrunkVlanSpec trunkVlanSpec = new VmwareDistributedVirtualSwitchTrunkVlanSpec();
      NumericRange vlanIDRange = new NumericRange();
      DVSFailureCriteria failureCriteria = null;
      VmwareUplinkPortTeamingPolicy uplinkTeamingPolicy = null;
      VMwareUplinkPortOrderPolicy portOrderPolicy = null;
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
      hostConfigSpecElement.setBacking(pnicBacking);
      hostConfigSpecElement.setHost(hostMor);
      hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
               uplinkPortNames.length + 1));
      hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
      vmwareDVSConfigSpec.getHost().clear();
      vmwareDVSConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
      portSetting.setBlocked(DVSUtil.getBoolPolicy(false, false));
      inShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
               (long) 102400, (long) 102400, (long) 102400);
      outShapingPolicy = DVSUtil.getTrafficShapingPolicy(false, true,
               (long) 102400, (long) 102400, (long) 102400);
      portSetting.setInShapingPolicy(inShapingPolicy);
      portSetting.setOutShapingPolicy(outShapingPolicy);
      securityPolicy = DVSUtil.getDVSSecurityPolicy(false, false, true, true);
      portSetting.setSecurityPolicy(securityPolicy);
      vlanIDRange.setStart(1);
      vlanIDRange.setEnd(20);
      trunkVlanSpec.getVlanId().clear();
      trunkVlanSpec.getVlanId().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new NumericRange[] { vlanIDRange }));
      trunkVlanSpec.setInherited(false);
      portSetting.setVlan(trunkVlanSpec);
      portOrderPolicy = DVSUtil.getPortOrderPolicy(false,
               new String[] { uplinkPortNames[0] },
               new String[] { uplinkPortNames[1] });
      failureCriteria = DVSUtil.getFailureCriteria(false, "exact", 50, true,
               true, true, 10, true);
      uplinkTeamingPolicy = DVSUtil.getUplinkPortTeamingPolicy(false,
               "loadbalance_ip", true, true, true, failureCriteria,
               portOrderPolicy);
      portSetting.setUplinkTeamingPolicy(uplinkTeamingPolicy);
      vmwareDVSConfigSpec.setDefaultPortConfig(portSetting);
      vmwareDVSConfigSpec.setMaxMtu(1500);
      configSpec = vmwareDVSConfigSpec;
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dcMor, privilege, testUser, true);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   /**
    * Method that creates the DVS.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Create a DVSwitch inside a valid folder by a"
               + " user not having DVSwitch.create privilege."
               + " The DVS parameters are to be set as follows:\n"
               + " - DVSConfigSpec.configVersion set to an empty string,\n"
               + " - DVSConfigSpec.name set to 'Create  DVS-Sec003'.")
   public void test()
      throws Exception
   {
      try {
         dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
                  configSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dcMor);
         expectedMethodFault.setPrivilegeId(DVSWITCH_CREATE);
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
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      if (authHelper != null) {
         status &= authHelper.performSecurityTestsCleanup();
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dcMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}