/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addserviceconsolevirtualnic;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

import dvs.VNicBase;

/**
 * Add a service console vnic to connect to an existing DVPort on an lateBinding
 * DVPortgroup on an existing DVSwitch. Build the DVPortConnection with invalid
 * DVPortKey on an lateBindingPortgroup. The distributedVirtualPort is of type
 * DistributedVirtualSwitchPortConnection.
 */
public class Neg004 extends VNicBase
{
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private HostVirtualNicSpec hostVNicSpec = null;
   private String scVNicId = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a service console vnic to connect to an existing "
               + "DVPort on an existing lateBinding DVPortgroup on an existing "
               + "DVSwitch. DVPortConnection with invalid DVPortKey on an "
               + "lateBindingPortgroup. The DVPort is of type DistributedVirtualSwitchPortConnection.");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVS by using
    * the hostMor. 2. Build the DistributedVirtualSwitchPortConnection with
    * invalid DVPortKey on an lateBinding DVPortgroupKey. 3. Create the
    * HostVirtualNic Spec.
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
      String portgroupKey = null;
      List<String> portKeys = null;
      String dvSwitchUuid = null;
      String ipAddress = null;
      String alternateIPAddress = null;
      String subnetMask = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
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
         log.info("dvsMor :" + dvsMor);
         Thread.sleep(10000);// Sleep for 10 Sec
         nwSystemMor = ins.getNetworkSystem(hostMor);
         if (ins.refresh(nwSystemMor)) {
            log.info("refreshed");
         }
         // add the pnics to DVS
         hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
                  hostMor);
         if ((hostNetworkConfig != null) && (hostNetworkConfig.length == 2)
                  && (hostNetworkConfig[0] != null)
                  && (hostNetworkConfig[1] != null)) {
            log.info("Found the network config.");
            // update the network to use the DVS.
            networkUpdated = ins.updateNetworkConfig(nwSystemMor,
                     hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);
            if (networkUpdated) {
               portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                        DVPORTGROUP_TYPE_LATE_BINDING, 1, getTestId() + "-PG.");
               if (portgroupKey != null) {
                  // Get the existing DVPortKey on an earlyBinding Portgroup.
                  portKeys = fetchPortKeys(dvsMor, portgroupKey);
                  portKeys.get(0);
                  // Get the DVSUuid.
                  final DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                  dvSwitchUuid = info.getUuid();
                  // create the DistributedVirtualSwitchPortConnection
                  // object.
                  dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                           dvSwitchUuid, "xyz", portgroupKey);
                  // Get the alternateIPAddress of the host.
                  ipAddress = ihs.getIPAddress(hostMor);
                  alternateIPAddress = TestUtil.getAlternateServiceConsoleIP(ipAddress);
                  // Get the subnetMask.
                  subnetMask = getSubnetMask(hostMor);
                  if ((alternateIPAddress != null) && (subnetMask != null)) {
                     log.info("altenateIPAddrsss:" + alternateIPAddress);
                     log.info("subnetMask:" + subnetMask);
                     // Create the HostvirtualNicSpec object.
                     hostVNicSpec = buildVnicSpec(dvsPortConnection,
                              alternateIPAddress, subnetMask, false);
                  } else {
                     hostVNicSpec = buildVnicSpec(dvsPortConnection, null,null, true);
                  }
                  status = true;
               } else {
                  log.error("Failed the add the portgroups to DVS.");
               }
            } else {
               log.error("Failed to find network config.");
            }
         }
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Add a ServiceConsoleVirtualNic to the Network System.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a service console vnic to connect to an existing "
            + "DVPort on an existing lateBinding DVPortgroup on an existing "
            + "DVSwitch. DVPortConnection with invalid DVPortKey on an "
            + "lateBindingPortgroup. The DVPort is of type DistributedVirtualSwitchPortConnection.")
   public void test()
      throws Exception
   {
      boolean status = true;
      final MethodFault expectedFault = new InvalidArgument();
      try {
         // Add a ServiceConsoleVirtualNic to the Network System.
         scVNicId = ins.addServiceConsoleVirtualNic(nwSystemMor, "",
                  hostVNicSpec);
         if (scVNicId != null) {
            log.error("Successfully add the service console Virtual NIC."
                     + "API didn't throw any exception.");
            status = false;
         }
      } catch (final Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         status &= TestUtil.checkMethodFault(actualMethodFault, expectedFault);
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
            log.info("Successfully removed the service console Virtual NIC "
                     + scVNicId);
         } else {
            if (scVNicId == null) {
               log.info("Unable to find the service console virtual Nic.");
            } else {
               log.error("Unable to remove the service console Virtual NIC "
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
