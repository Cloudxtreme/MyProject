/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addvirtualnic;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.PrivilegeConstants.NETWORK_ASSIGN;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;

import dvs.VNicBase;

/**
 * Add a VNIC to connect to a standalone port on a DVSwitch by an user not
 * having network.assign privilege.
 */
public class Sec004 extends VNicBase
{
   private HostNetworkConfig origHostNetworkConfig = null;
   private String vNic = null;
   private String portgroupKey = null;
   private String dvSwitchUuid = null;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = NETWORK_ASSIGN;
   ManagedObjectReference pgMor = null;
   private AuthorizationManager authentication = null;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a vmkernel vnic to connect to an "
               + "existing standalone port on an existing DVSwitch"
               + " by an user not having network.assign privilege  ");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return true if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      log.info("Test setup begin... ");
      authentication = new AuthorizationManager(connectAnchor);
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_FAIL);
      ihs.getAllHosts(VersionConstants.ESX4x, CONNECTED);
      nwSystemMor = ins.getNetworkSystem(hostMor);
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      assertNotNull(dvsMor, "Failed to create the DVS");
      log.info("Add a DVPortGroup to connect the VNIC...");
      portgroupKey = iDVSwitch.addPortGroup(dvsMor,
               DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId() + "-pg1");
      assertNotNull(portgroupKey, "Failed to add DVPortGroup.");
      List<ManagedObjectReference> dvpgMors = iDVSwitch.getPortgroup(dvsMor);
      if ((dvpgMors != null) && (dvpgMors.size() > 0)) {
         for (int i = 0; i < dvpgMors.size(); i++) {
            pgMor = dvpgMors.get(i);
            String key = iDVPortGroup.getKey(pgMor);
            if ((key != null) && key.equalsIgnoreCase(portgroupKey)) {
               break;
            }
         }
      }
      assertNotNull(pgMor, "Got the DVPortGroup MOR.");
      DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertNotNull(hostNetworkConfig, "Failed to get host Config");
      origHostNetworkConfig = hostNetworkConfig[1];
      log.info("Updating the host to use the DVS...");
      assertTrue(ins.updateNetworkConfig(nwSystemMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY), "Failed to update net Cfg");
      log.info("Successfully updated the host network.");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(ihs.getParentNode(hostMor), privilege,
               testUser, true);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   /**
    * Test. 1. Create the hostVirtualNic and add the VirtualNic to the
    * NetworkSystem. 2. Get the HostVNic Id and select the VNic for VMotion 3.
    * Migrate the VM.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a vmkernel vnic to connect to an "
               + "existing standalone port on an existing DVSwitch"
               + " by an user not having network.assign privilege  ")
   public void test()
      throws Exception
   {
      try {
         DistributedVirtualSwitchPortConnection portConnection = null;
         HostVirtualNicSpec vNicSpec = null;
         portConnection = new DistributedVirtualSwitchPortConnection();
         portConnection.setSwitchUuid(dvSwitchUuid);
         portConnection.setPortgroupKey(portgroupKey);
         vNicSpec = ins.createVNicSpecification();
         vNicSpec.setDistributedVirtualPort(portConnection);
         vNicSpec.setPortgroup(null);
         vNic = ins.addVirtualNic(nwSystemMor, "pg", vNicSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NoPermission();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, getExpectedMethodFault()),
                  "MethodFault mismatch!");
      }
   }

   /**
    * Method to restore the state as it was before the test is started. 1.
    * Migrate the VM back to Source host. 3. Remove the vNic and DVSMor.
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
      if (authHelper != null) {
         status &= authHelper.performSecurityTestsCleanup();
      }
      if (vNic != null) {
         status &= ins.removeVirtualNic(nwSystemMor, vNic);
         if (status) {
            log.info("Successfully remove the add vNic.");
         } else {
            log.error("Failed to remove the added vNic");
            status = false;
         }
      }
      // testInfo("Sleeping for 4 seconds");
      // Thread.sleep(4000);
      if (origHostNetworkConfig != null) {
         log.info("Updating host network config to use vSwitch");
         status &= ins.updateNetworkConfig(nwSystemMor, origHostNetworkConfig,
                  TestConstants.CHANGEMODE_MODIFY);
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }

   @Override
   public MethodFault getExpectedMethodFault()
   {
      NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(pgMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}
