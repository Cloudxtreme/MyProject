/*
 * ************************************************************************
 *
 * Copyright 2008-2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.ResourceInUse;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.vmops.VMopsBase;

/**
 * Reconfigure 2 VM's on a standalone host to connect to an previously unused
 * DVPort on an earlyBinding protgroup.The device is of type VirtualPCNet32, the
 * backing is of type DVPort backing and the port connection is a DVPort
 * connection.
 */
public class Neg005 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec1 = null;
   private VirtualMachineConfigSpec vmConfigSpec2 = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private ManagedObjectReference vmMor1 = null;
   private ManagedObjectReference vmMor2 = null;
   private String dvSwitchUuid = null;

   /**
    * Method to setup the environment for the test. 1. create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the 2 VM's.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      String portgroupKey = null;
      List<String> portKeys = null;
      String aPortKey = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {

            hostMor = ihs.getStandaloneHost();
            log.info("Host MOR: " + hostMor);
            log.info("Host Name: " + ihs.getHostName(hostMor));
            // create the DVS by using standalone host.
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            Thread.sleep(10000);// Sleep for 10 Sec
            nwSystemMor = ins.getNetworkSystem(hostMor);
            if (ins.refresh(nwSystemMor)) {
               log.info("refreshed");
            }
            // add the pnics to DVS
            hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                     dvsMor, hostMor);
            if (hostNetworkConfig != null && hostNetworkConfig.length == 2) {
               log.info("Found the network config.");
               // update the network to use the DVS.
               networkUpdated = ins.updateNetworkConfig(nwSystemMor,
                        hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);
               if (networkUpdated) {
                  portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                           DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId()
                                    + "-PG.");
                  if (portgroupKey != null) {
                     // Get the existing DVPortkey on earlyBinding DVPortgroup.
                     portKeys = fetchPortKeys(dvsMor, portgroupKey);
                     aPortKey = portKeys.get(0);
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, aPortKey, portgroupKey);
                     // create the VM's.
                     vmConfigSpec1 = buildDefaultSpec(hostMor,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32);
                     vmConfigSpec1.setName(getTestId() + "-1");
                     vmMor1 = new Folder(super.getConnectAnchor()).createVM(
                              ivm.getVMFolder(), vmConfigSpec1,
                              ihs.getPoolMor(hostMor), hostMor);
                     vmConfigSpec2 = buildDefaultSpec(hostMor,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32);
                     vmConfigSpec2.setName(getTestId() + "-2");
                     vmMor2 = new Folder(super.getConnectAnchor()).createVM(
                              ivm.getVMFolder(), vmConfigSpec2,
                              ihs.getPoolMor(hostMor), hostMor);
                     if (vmMor1 != null && vmMor2 != null) {
                        log.info("Successfully created 2 VM's.");
                        status = true;
                     } else {
                        log.error("Failed to crete 2 VM's.");
                     }
                  } else {
                     log.error("Failed to add the portgroup to DVS.");
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
    * Test. Prepare the reconfigVmSpec.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Reconfigure 2 VM's on a Standalone host to connect to"
            + " an previously unused DVPort on an earlyBinding protgroup."
            + " The device is of type VirtualPCNet32")
   public void test()
      throws Exception
   {
      try {
         // Reconfigure the VM's
         VirtualMachineConfigSpec deltaConfigSpec = null;
         deltaConfigSpec =
                  DVSUtil
                           .getVMConfigSpecForDVSPort(
                                    vmMor1,
                                    connectAnchor,
                                    new DistributedVirtualSwitchPortConnection[] { dvsPortConnection })[0];
         assertTrue(ivm.reconfigVM(vmMor1, deltaConfigSpec),
                  "Successfully reconfigure the first VM.",
                  "Failed to reconfigure the first VM.");
         assertTrue(verify(vmMor1, deltaConfigSpec, vmConfigSpec1),
                  "Failed to verfiy deltaConfigSpec of  VM.");
         deltaConfigSpec =
                  DVSUtil
                           .getVMConfigSpecForDVSPort(
                                    vmMor2,
                                    connectAnchor,
                                    new DistributedVirtualSwitchPortConnection[] { dvsPortConnection })[0];
         ivm.reconfigVM(vmMor2, deltaConfigSpec);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new ResourceInUse();
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
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         if (vmMor1 != null && ivm.setVMState(vmMor1, POWERED_OFF, false)) {
            status = destroy(vmMor1);// destroy the VM1.
         }
         if (vmMor2 != null && ivm.setVMState(vmMor2, POWERED_OFF, false)) {
            status &= destroy(vmMor2);// destroy the VM2.
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
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
}
