/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.createvm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_VMXNET;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;

import dvs.vmops.VMopsBase;

/**
 * Create a VM on a standalone host to connect to an existing DVPort on an
 * earlyBinding DVPortgroup.The device is of type VirtualVmxnet. The backing is
 * of type DVPort backing and the port connection is a DVPortgroup connection.
 */
public class Pos010 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String dvSwitchUuid = null;
   private ManagedObjectReference vmMor = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a VM on a Standalone host to connect to"
               + "an existing DVPort on an earlyBinding DVPortgroup. The"
               + "device is of type VirtualVmxNet.");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the earlyBinding DVPortgroup. 3. Create the VM ConfigSpec.
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
            log.info("Host Mor :" + hostMor);
            log.info("Host Name :" + ihs.getHostName(hostMor));
            // create the DVS by using standalone host.
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            Thread.sleep(10); // Sleep 10 Sec.
            nwSystemMor = ins.getNetworkSystem(hostMor);
            if (ins.refresh(nwSystemMor)) {
               log.info("Network refreshed.");
            }
            // add the pnics to DVS
            hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                     dvsMor, hostMor);
            if (hostNetworkConfig != null && hostNetworkConfig.length == 2) {
               log.info("Found the NetworkConfig.");
               // update the network to use the DVS.
               networkUpdated = ins.updateNetworkConfig(
                        ins.getNetworkSystem(hostMor), hostNetworkConfig[0],
                        TestConstants.CHANGEMODE_MODIFY);
               if (networkUpdated) {
                  // Get the DVPortgroupKey.
                  portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                           DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId()
                                    + "-PG");
                  if (portgroupKey != null) {
                     // Get the DVSUuid.
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     // Get the existing DVPortkey on earlyBinding DVPortgroup.
                     portKeys = fetchPortKeys(dvsMor, portgroupKey);
                     aPortKey = portKeys.get(0);
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, aPortKey, portgroupKey);
                     vmConfigSpec = buildCreateVMCfg(dvsPortConnection,
                              VM_VIRTUALDEVICE_ETHERNET_VMXNET, hostMor);
                     log.info("Successfully created VMConfig spec.");
                     status = true;
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
    * Test. 1. Create the VM. 2. Varify the ConfigSpecs and Power-ops
    * operations.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Create a VM on a Standalone host to connect to"
               + "an existing DVPort on an earlyBinding DVPortgroup. The"
               + "device is of type VirtualVmxNet.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         vmMor = new Folder(super.getConnectAnchor()).createVM(
                  ivm.getVMFolder(), vmConfigSpec, ihs.getPoolMor(hostMor),
                  hostMor);
         if (vmMor != null) {
            log.info("Successfully created VM.");
            status = verify(vmMor, null, vmConfigSpec);
         } else {
            log.error("Unable to create VM.");
         }
     
      assertTrue(status, "Test Failed");
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
      boolean status = true;
      try {
         if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            status = destroy(vmMor);// destroy the VM.
         } else {
            log.warn("VM not found");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      try {
         if (networkUpdated) {
            // Restore the network to use the DVS.
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
