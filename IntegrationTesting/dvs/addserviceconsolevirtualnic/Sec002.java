/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addserviceconsolevirtualnic;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NoPermission;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.PrivilegeConstants;

import dvs.VNicBase;

/**
 * Add a service console vnic to connect to an existing standalone port on an
 * existing DVSwitch by an user not having network.assign privilege
 */
public class Sec002 extends VNicBase
{
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private HostVirtualNicSpec hostVNicSpec = null;
   private String scVNicId = null;
   private String alternateIPAddress = null;
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;
   private final String privilege = PrivilegeConstants.HOST_CONFIG_NETWORK;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a service console vnic to connect to an "
               + "existing standalone port on an existing DVSwitch "
               + "by an user not  having network.assign privilage");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch by
    * using hostMor. 2. Create the Standalone DVPort. 3. Create
    * HostVirtualNicSpec Object.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      String dvSwitchUuid = null;
      List<String> portKeys = null;
      String ipAddress = null;
      String subnetMask = null;
      assertTrue(super.testSetUp(), TB_SETUP_FAIL);
      final List<ManagedObjectReference> hostMors = ihs.getAllHost();
      for (final ManagedObjectReference aHostMor : hostMors) {
         if (!ihs.isEesxHost(aHostMor)) {
            hostMor = aHostMor;
            break;
         }
      }
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      log.info("Host Name: " + ihs.getHostName(hostMor));
      // create the DVS by using hostMor.
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      assertNotNull(dvsMor, "Failed to create the DVS: " + dvsName);
      Thread.sleep(10000);// Sleep for 10 Sec
      nwSystemMor = ins.getNetworkSystem(hostMor);
      assertTrue(ins.refresh(nwSystemMor), "Failed to refresh network system");
      // add the pnics to DVS
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertNotEmpty(hostNetworkConfig, "Failed to get config.");
      assertTrue(hostNetworkConfig.length == 2, "Failed to get cfg.");
      log.info("Got the network config.");
      // update the network to use the DVS.
      networkUpdated = ins.updateNetworkConfig(nwSystemMor,
               hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);
      assertTrue(networkUpdated, "Failed to update network config.");
      portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
      assertNotEmpty(portKeys, "Failed to add standalone port.");
      log.info("Successfully added the standalone DVPort");
      final String portKey = portKeys.get(0);
      final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
      dvSwitchUuid = info.getUuid();
      // create the DistributedVirtualSwitchPortConnection object.
      dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
               dvSwitchUuid, portKey, null);
      ipAddress = ihs.getIPAddress(hostMor);
      // Get the alternateIPAddress of the host.
      alternateIPAddress = TestUtil.getAlternateServiceConsoleIP(ipAddress);
      log.info("alternateIPAddress: " + alternateIPAddress);
      subnetMask = getSubnetMask(hostMor); // Get the subnetMask.
      log.info("SubnetMask: " + subnetMask);
      if(alternateIPAddress != null){
         hostVNicSpec = buildVnicSpec(dvsPortConnection, alternateIPAddress,
                  subnetMask, false);
      } else {
         hostVNicSpec = buildVnicSpec(dvsPortConnection, null,
                  null, true);
      }
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(ihs.getParentNode(hostMor), privilege,
               testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   /**
    * Test. 1. Add the ServiceConsoleVirtualNic to the NetworkSystem. 2. Check
    * the network connectivity.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a service console vnic to connect to an "
               + "existing standalone port on an existing DVSwitch "
               + "by an user not  having network.assign privilage")
   public void test()
      throws Exception
   {
      try {
         scVNicId = ins.addServiceConsoleVirtualNic(nwSystemMor, "", hostVNicSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NoPermission();
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
      } catch (final Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      try {
         if (networkUpdated) { // restore the network to use the DVS.
            status &= ins.updateNetworkConfig(nwSystemMor,
                     hostNetworkConfig[1], CHANGEMODE_MODIFY);
         }
      } catch (final Exception e) {
         status = false;
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
      final NoPermission expectedFault = new NoPermission();
      expectedFault.setObject(hostMor);
      expectedFault.setPrivilegeId(privilege);
      return expectedFault;
   }
}
