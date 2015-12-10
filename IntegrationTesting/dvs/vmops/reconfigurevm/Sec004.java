/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.PrivilegeConstants.NETWORK_ASSIGN;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.vmops.VMopsBase;

/**
 * Reconfigure a VM on a standalone host to connect to an existing earlyBinding
 * DVPortgroup by an user not having network.assign privilege
 */
public class Sec004 extends VMopsBase
{
   private VirtualMachineConfigSpec deltaConfigSpec = null;
   private ManagedObjectReference vmMor = null;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = NETWORK_ASSIGN;
   private ManagedObjectReference dvpgMor;
   private AuthorizationManager authentication = null;

   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a VM on a standalone host to "
               + "connect to an existing earlyBinding DVPortgroup by an user "
               + " not having network.assign privilege");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the lateBinding DVPortgroup. 3. Create the VMConfigSpec.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      String portgroupKey = null;
      DistributedVirtualSwitchPortConnection dvsPortConnection;
      authentication = new AuthorizationManager(connectAnchor);
      assertTrue(super.testSetUp(), MessageConstants.TB_SETUP_FAIL);
      hostMor = ihs.getStandaloneHost();
      log.info("Host Name: " + ihs.getHostName(hostMor));
      // create the DVS by using standalone host.
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      Thread.sleep(10000);// Sleep for 10 Sec
      nwSystemMor = ins.getNetworkSystem(hostMor);
      if (ins.refresh(nwSystemMor)) {
         log.info("refreshed");
      }
      // add the pnics to DVS
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertNotEmpty(hostNetworkConfig, "Failed to get network Cfg");
      assertTrue(hostNetworkConfig.length == 2,
               "Failed to get net Cfg to migrate to DVS");
      log.info("Found the network config.");
      // update the network to use the DVS.
      networkUpdated = ins.updateNetworkConfig(nwSystemMor,
               hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);
      assertTrue(networkUpdated, "Failed to update network Cfg");
      portgroupKey = iDVSwitch.addPortGroup(dvsMor,
               DVPORTGROUP_TYPE_EARLY_BINDING, 4, getTestId() + "-PG.");
      assertNotNull(portgroupKey, "Failed the add the portgroups to DVS.");
      List<ManagedObjectReference> pgs = iDVSwitch.getPortgroup(dvsMor);
      for (int i = 0; i < pgs.size(); i++) {
         DVPortgroupConfigInfo cfgInfo = iDVPortGroup.getConfigInfo(pgs.get(i));
         if (portgroupKey.equals(cfgInfo.getKey())) {
            dvpgMor = pgs.get(i);
            break;
         }
      }
      // Get DVSUuid.
      DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
      String dvSwitchUuid = info.getUuid();
      // create the DistributedVirtualSwitchPortConnection object.
      dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
               dvSwitchUuid, null, portgroupKey);
      // Create the VM.
      VirtualMachineConfigSpec vmCfg = buildDefaultSpec(hostMor,
               VM_VIRTUALDEVICE_ETHERNET_PCNET32);
      vmCfg.setName(getTestId());
      vmMor = iFolder.createVM(ivm.getVMFolder(), vmCfg,
               ihs.getPoolMor(hostMor), hostMor);
      assertNotNull(vmMor, MessageConstants.VM_CREATE_FAIL);
      log.info("Successfully crated a VM.");
      deltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
               vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { dvsPortConnection })[0];
      //
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));

      authHelper.setPermissions(vmMor, privilege, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   /**
    * Test. 1. Create the DeltaConfigSpec. 2. Reconfigure the VirtualMachine
    * Configuration. 3. Varify the VMConfigSpecs and Power-ops operations.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = " Reconfigure a VM on a standalone host to "
               + "connect to an existing earlyBinding DVPortgroup by an user "
               + " not having network.assign privilege")
   public void test()
      throws Exception
   {
      try {
         ivm.reconfigVM(vmMor, deltaConfigSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, getExpectedMethodFault()),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (authHelper != null) {
            status &= authHelper.performSecurityTestsCleanup();
         }
         if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            status &= destroy(vmMor);// destroy the VM.
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      try {
         if (networkUpdated) {
            // restore the network to use the DVS.
            status &= ins.updateNetworkConfig(nwSystemMor,
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(dvpgMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}
