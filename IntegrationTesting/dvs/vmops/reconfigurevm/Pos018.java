/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_VMXNET2;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

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
import com.vmware.vcqa.vim.dvs.DVSUtil;

import dvs.vmops.VMopsBase;

/**
 * Reconfigure 2 VM's on a standalone host to connect to an existing lateBinding
 * DVPortgroup,containing 1 unused port. The device is of type VirtualVmxNete2,
 * the backing is of type DVPort backing and the port connection is a
 * DVPortgroup connection.
 */
public class Pos018 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String dvSwitchUuid = null;
   private ManagedObjectReference vmMor1 = null;
   private ManagedObjectReference vmMor2 = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure 2 VM's on a standalone host to connect"
               + " to an existing lateBinding DVPortgroup containing 1 unused "
               + "port. The device is of type VirtualVmxNet2");
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
      boolean status = false;
      String portgroupKey = null;
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
                           DVPORTGROUP_TYPE_LATE_BINDING, 1, getTestId()
                                    + "-PG.");
                  if (portgroupKey != null) {
                     // Get DVSUuid.
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, null, portgroupKey);
                     // Create the VM.
                     vmConfigSpec = buildDefaultSpec(hostMor,
                              VM_VIRTUALDEVICE_ETHERNET_VMXNET2);
                     log.info("Successfully created default VMConfig spec.");
                     vmConfigSpec.setName(getTestId() + "-1");
                     vmMor1 = new Folder(super.getConnectAnchor()).createVM(
                              ivm.getVMFolder(), vmConfigSpec,
                              ihs.getPoolMor(hostMor), hostMor);
                     vmConfigSpec.setName(getTestId() + "-2");
                     vmMor2 = new Folder(super.getConnectAnchor()).createVM(
                              ivm.getVMFolder(), vmConfigSpec,
                              ihs.getPoolMor(hostMor), hostMor);
                     if (vmMor1 != null && vmMor2 != null) {
                        log.info("Successfully create the VM's.");
                        status = true;
                     } else {
                        log.error("Unable to create the VM's.");
                     }
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
    * Test. 1. Create the DeltaConfigSpec. 2. Reconfigure the VirtualMachine
    * Configuration. 3. Varify the VMConfigSpecs and Power-ops operations.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = " Reconfigure 2 VM's on a standalone host to connect"
               + " to an existing lateBinding DVPortgroup containing 1 unused "
               + "port. The device is of type VirtualVmxNet2")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         VirtualMachineConfigSpec deltaConfigSpec = null;
         deltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                  vmMor1,
                  connectAnchor,
                  new DistributedVirtualSwitchPortConnection[] { dvsPortConnection })[0];
         if (ivm.reconfigVM(vmMor1, deltaConfigSpec)) {
            log.info("Successfully reconfigure the first VM.");
            status = verify(vmMor1, deltaConfigSpec, vmConfigSpec);
            if (status) {
               deltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                        vmMor2,
                        connectAnchor,
                        new DistributedVirtualSwitchPortConnection[] { dvsPortConnection })[0];
               if (ivm.reconfigVM(vmMor2, deltaConfigSpec)) {
                  log.info("Successfully reconfigure the second VM.");
                  status = verify(vmMor1, deltaConfigSpec, vmConfigSpec);
                  assertTrue(status, "Test Failed");
               } else {
                  log.error("Failed to reconfigure the second VM.");
                  status = false;
               }
            }
         } else {
            log.error("Failed to reconfigure the first VM.");
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
