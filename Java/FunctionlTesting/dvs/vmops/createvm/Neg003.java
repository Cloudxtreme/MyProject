/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.vmops.createvm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.NotFound;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;

import dvs.vmops.VMopsBase;

/**
 * Create a VM on a standalone host to connect to an existing standalone DVPort.
 * Build DVPortConnection with invalid DVPortKey. The device is of type
 * VirtualPCNet32,the backing is of type DVPort backing and the port connection
 * is a DVPort connection.
 */
public class Neg003 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String portKey = null;
   private String dvSwitchUuid = null;
   private ManagedObjectReference vmMor = null;

   /**
    * Set description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a VM on a Standalone host to connect to"
               + "an existing standalone DVPort.The device is of type "
               + "VirtualPCNet32.Create DVPortconnection with invalid DVPortKey.");
   }

   /**
    * Method to setup the environment for the test. 1. create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the DVPortConnection with invalid
    * DVPortKey. 4. Create the VMConfigSpec.
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
      List<String> portKeys = null;
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
                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
                  if (portKeys != null) {
                     log.info("Successfully get the standalone DVPortkeys");
                     portKey = portKeys.get(0);
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, "xyz", null);
                     vmConfigSpec = buildCreateVMCfg(dvsPortConnection,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32, hostMor);
                     log.info("Successfully created VMConfig spec.");
                     status = true;
                  } else {
                     log.error("Failed to get the standalone DVPortkeys ");
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
    * Test. 1. Create the VM with invalid DVPortKey.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Create a VM on a Standalone host to connect to"
               + "an existing standalone DVPort.The device is of type "
               + "VirtualPCNet32.Create DVPortconnection with invalid DVPortKey.")
   public void test()
      throws Exception
   {
      boolean status = true;
      MethodFault expectedFault = new NotFound();
      try {
         // Create a VM with DVSwitchUuid as null.
         vmMor = new Folder(super.getConnectAnchor()).createVM(
                  ivm.getVMFolder(), vmConfigSpec, ihs.getPoolMor(hostMor),
                  hostMor);
         if (vmMor != null) {
            log.error("Successfully create a VM."
                     + "API didn't throw any exception.");
            status = false;
         }
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         status &= TestUtil.checkMethodFault(actualMethodFault, expectedFault);
      }
      if (!status) {
         log.error("API didn't throw expected exception: "
                  + expectedFault.getClass().getSimpleName());
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
