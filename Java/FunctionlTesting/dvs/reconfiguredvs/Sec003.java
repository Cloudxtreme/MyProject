/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.PrivilegeConstants.*;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by configuring two hosts by user having
 * "DVSwitch.Hostop","DVSwitch.Modify","Host.Config.Network" privilege.
 * Configure two hosts (H1, and H2)
 */
public class Sec003 extends CreateDVSTestBase
{
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference[] hostMors = null;
   private DVSConfigSpec deltaCfg = null;
   private NetworkSystem iNetworkSystem = null;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String[] privileges = new String[] { DVSWITCH_MODIFY,
            DVSWITCH_HOSTOP, HOST_CONFIG_NETWORK };

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DistributedVirtualSwitchHostMemberPnicBacking hostPnicBacking;
      DVSConfigInfo configInfo;
      DistributedVirtualSwitchHostMemberConfigSpec[] hostMembers;
      hostMors = new ManagedObjectReference[2];
      hostMembers = new DistributedVirtualSwitchHostMemberConfigSpec[1];
      final String dvsName = getTestId();
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      ihs = new HostSystem(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      allHosts = ihs.getAllHost();
      assertNotEmpty(allHosts, "Failed to get hosts");
      assertTrue(allHosts.size() >= 2, "Failed to get required num of hosts");
      assertTrue(ihs.isHostConnected(allHosts.get(0)), "Host1 is not connected");
      assertTrue(ihs.isHostConnected(allHosts.get(1)), "Host2 is not connected");
      hostMors[0] = allHosts.get(0);
      hostMors[1] = allHosts.get(1);
      networkFolderMor = iFolder.getNetworkFolder(dcMor);
      configSpec = new DVSConfigSpec();
      configSpec.setName(dvsName);
      hostMembers[0] = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMembers[0].setHost(hostMors[0]);
      hostMembers[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      /*hostPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      hostPnicBacking.getPnicSpec().clear();
      hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.
    	   arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostMembers[0].setBacking(hostPnicBacking);*/
      configSpec.getHost().clear();
      configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.
    		  arrayToVector(hostMembers));
      dvsMOR = iFolder.createDistributedVirtualSwitch(networkFolderMor,
               configSpec);
      assertNotNull(dvsMOR, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      configInfo = iDistributedVirtualSwitch.getConfig(dvsMOR);
      deltaCfg = new DVSConfigSpec();
      final DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new
    		  DVSNameArrayUplinkPortPolicy();
      deltaCfg.setConfigVersion(configInfo.getConfigVersion());
      deltaCfg.setName(dvsName);
      final String[] uplinkPortNames = new String[] { "Uplink1" };
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.
    		  TestUtil.arrayToVector(uplinkPortNames));
      deltaCfg.setUplinkPortPolicy(uplinkPolicyInst);
      deltaCfg.setMaxPorts(5);
      deltaCfg.setNumStandalonePorts(1);
      String[] hostPhysicalNics = null;
      hostMembers = new DistributedVirtualSwitchHostMemberConfigSpec[2];
      for (int i = 0; i < 2; i++) {
         hostMembers[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMembers[i].setHost(hostMors[i]);
         if (i == 0) {
            hostMembers[i].setOperation(TestConstants.CONFIG_SPEC_REMOVE);
         } else {
            hostPhysicalNics = iNetworkSystem.getPNicIds(hostMors[i]);
            if (hostPhysicalNics != null) {
               final DistributedVirtualSwitchHostMemberPnicSpec hostPnicSpec =
            		   new DistributedVirtualSwitchHostMemberPnicSpec();
               hostPnicSpec.setPnicDevice(hostPhysicalNics[0]);
               hostPnicBacking = new
            		   DistributedVirtualSwitchHostMemberPnicBacking();
               hostPnicBacking.getPnicSpec().clear();
               hostPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.
            		   TestUtil.arrayToVector(new
            		   DistributedVirtualSwitchHostMemberPnicSpec[] {
            		   hostPnicSpec }));
               hostMembers[i].setBacking(hostPnicBacking);
               hostMembers[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
            } else {
               log.error("No free pnics found on the host.");
            }
         }
      }
      deltaCfg.getHost().clear();
      deltaCfg.getHost().addAll(com.vmware.vcqa.util.TestUtil.
    		  arrayToVector(hostMembers));
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(),
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dcMor, privileges, testUser, true);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Override
   @Test(description = "Reconfigure an existing DVSwitch by configuring "
            + "two hosts by user having DVSwitch.Hostop, privilege. "
            + "Configure two hosts (H1, and H2)")
   public void test()
      throws Exception
   {
      assertTrue(iDistributedVirtualSwitch.reconfigure(dvsMOR, deltaCfg),
               "Failed to reconfigure DVS with necessary privileges.");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         if (authHelper != null) {
            status = authHelper.performSecurityTestsCleanup();
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      } finally {
         status = super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
