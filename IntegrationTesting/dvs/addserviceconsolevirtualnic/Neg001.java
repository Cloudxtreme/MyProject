/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addserviceconsolevirtualnic;

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
import com.vmware.vc.NotFound;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

import dvs.VNicBase;

/**
 * Add a service console vnic to connect to an existing standalone port on an
 * existing DVSwitch. Build a DVPortConnection with invalid DVPortKey. The
 * distributedVirtualPort is of type DistributedVirtualSwitchPortConnection.
 */
public class Neg001 extends VNicBase
{
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private HostVirtualNicSpec hostVNicSpec = null;
   private String scVNicId = null;

   /**
    * Method to setup the environment for the test.<br>
    * 1. Create the DVS by using hostMor.<br>
    * 2. Build DistributedVirtualSwitchPortConnection with invalid DVPortKey.<br>
    * 3. Create the HostVirtualNic Spec object.<br>
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      List<String> portKeys = null;
      String dvSwitchUuid = null;
      String ipAddress = null;
      String alternateIPAddress = null;
      String subnetMask = null;
      log.info("test setup Begin:");
      assertTrue(super.testSetUp(), TB_SETUP_PASS, TB_SETUP_FAIL);
      final List<ManagedObjectReference> hostMors = ihs.getAllHost();
      for (final ManagedObjectReference aHostMor : hostMors) {
         if (!ihs.isEesxHost(aHostMor)) {
            hostMor = aHostMor;
            break;
         }
      }
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      log.info("Host MOR: " + hostMor);
      log.info("Host Name: " + ihs.getHostName(hostMor));
      // create the DVS by using hostMor.
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      nwSystemMor = ins.getNetworkSystem(hostMor);
      if (ins.refresh(nwSystemMor)) {
         log.info("refreshed");
      }
      // add the pnics to DVS
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertNotEmpty(hostNetworkConfig, "Failed to get host cfg.");
      log.info("Found the network config.");
      // update the network to use the DVS.
      networkUpdated = ins.updateNetworkConfig(nwSystemMor,
               hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);
      assertTrue(networkUpdated, "Failed to update network Cfg to use DVS.");
      portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
      if (portKeys != null) {
         final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
         dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection
         // object.
         dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                  dvSwitchUuid, "xyz", null);
         // Get the alternateIPAddress of the host.
         ipAddress = ihs.getIPAddress(hostMor);
         alternateIPAddress = TestUtil.getAlternateServiceConsoleIP(ipAddress);
         // Get the subnetMask.
         subnetMask = getSubnetMask(hostMor);
         log.info("alternateIpAddress:" + alternateIPAddress);
         log.info("subnetMask : " + subnetMask);
         if ((alternateIPAddress != null) && (subnetMask != null)) {
            // Create the HostvirtualNicSpec object.
            hostVNicSpec = buildVnicSpec(dvsPortConnection, alternateIPAddress,
                     subnetMask, false);
         } else {
            hostVNicSpec = buildVnicSpec(dvsPortConnection, null,null, true);
         }
         status = true;
      } else {
         log.error("Failed to get the standalone DVPortkeys ");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Add the ServiceConsoleVirtualNic to the Network System.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a service console vnic to connect to an "
            + "existing standalone port on an existing DVSwitch. "
            + "Create a DVPortConnection with invalid DVPortKey."
            + "The distributedVirtualPort is of type DistributedVirtualSwitchPortConnection.")
   public void test()
      throws Exception
   {
      boolean status = false;
      final MethodFault expectedFault = new NotFound();
      try {
         // Add a ServiceConsoleVirtualNic to the Network System.
         scVNicId = ins.addServiceConsoleVirtualNic(nwSystemMor, "",
                  hostVNicSpec);
         if (scVNicId != null) {
            log.error("Successfully add the service console Virtual NIC."
                     + "API didn't throw any exception.");
         }
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         status = TestUtil.checkMethodFault(
                  actualMethodFault.getFaultCause().getFault(), expectedFault);
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if ((scVNicId != null)
                  && ins.removeServiceConsoleVirtualNic(nwSystemMor, scVNicId)) {
            log.info("Successfully removed the service console Virtual NIC. "
                     + scVNicId);
         } else {
            if (scVNicId == null) {
               log.info("Unable to find the service console virtual Nic.");
            } else {
               log.error("Unable to remove the service console Virtual Nic."
                        + scVNicId);
               status = false;
            }
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      }
      try {
         if (networkUpdated) {
            // restore the network to use the DVS.
            status &= ins.updateNetworkConfig(nwSystemMor,
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (final Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
