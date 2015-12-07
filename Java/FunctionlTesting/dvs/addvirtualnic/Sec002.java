/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addvirtualnic;

import static com.vmware.vcqa.TestConstants.GENERIC_USER;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.TB_SETUP_FAIL;
import static com.vmware.vcqa.vim.PrivilegeConstants.NETWORK_ASSIGN;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.AuthorizationManager;

import dvs.VNicBase;

/**
 * Add a VNIC to connect to a standalone port on a DVSwitch by an user not
 * having "Network.Assign" privilege.
 */
public class Sec002 extends VNicBase
{
   private HostNetworkConfig origHostNetworkConfig = null;
   private List<String> portKeys = null;
   private String vNic = null;
   String dvSwitchUuid = null;
   private final String testUser = GENERIC_USER;
   private AuthorizationHelper authHelper;
   private final String privilege = NETWORK_ASSIGN;
   private AuthorizationManager authentication = null;

   /**
    * Set test description.
    */
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
      authentication = new AuthorizationManager(super.getConnectAnchor());
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      hostMor = ihs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_FAIL);
      nwSystemMor = ins.getNetworkSystem(hostMor);
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      assertNotNull(dvsMor, "Failed to create DVS");
      log.info("Add a standalone DVPort to connect the VNIC...");
      portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
      assertNotEmpty(portKeys, "Failed to add the standalone DVPort.");
      log.info("Got portkeys: " + portKeys);
      dvSwitchUuid = iDVSwitch.getConfig(dvsMor).getUuid();
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertNotEmpty(hostNetworkConfig, "Failed to get host network cfg");
      origHostNetworkConfig = hostNetworkConfig[1];
      log.info("Updating the host to use the DVS...");
      assertTrue(ins.updateNetworkConfig(nwSystemMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY), "Failed to update network cfg");
      log.info("Successfully updated the host network.");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(ihs.getParentNode(hostMor), privilege,
               testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   /**
    * Test.<br>
    * 1. Create the hostVirtualNic and add the VirtualNic to the NetworkSystem.<br>
    * 2. Get the HostVNic Id and select the VNic for VMotion <br>
    * 3. Migrate the VM.<br>
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
         portConnection.setPortKey(portKeys.get(0));
         vNicSpec = ins.createVNicSpecification();
         vNicSpec.setDistributedVirtualPort(portConnection);
         vNicSpec.setPortgroup(null);
         vNic = ins.addVirtualNic(nwSystemMor, "pg", vNicSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
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
         }
      }
      // if ((portKeys != null) && (portKeys.size() > 0)) {
      // log.info("Sleeping for 4 seconds");
      // Thread.sleep(4000);
      // if (iDVSwitch.refreshPortState(dvsMor,
      // new String[] { portKeys.get(0) })) {
      // log.info("Successfully refreshed the port state");
      // } else {
      // testError("Can not refresh the port state");
      // status = false;
      // }
      // }
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
      expectedFault.setObject(dvsMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}
