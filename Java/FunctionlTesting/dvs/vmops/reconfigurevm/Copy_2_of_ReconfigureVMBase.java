/*
 * ************************************************************************
 *
 * Copyright 2008-2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vc.VirtualDeviceConfigSpecOperation.REMOVE;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.TestConstants.CHANGEMODE_MODIFY;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.VersionConstants.ESX4x;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_RECONFIG_FAIL;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.CHECK_GUEST;

import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;

import dvs.vmops.VMopsBase;

/**
 * Base class for all DVS reconfigure VM tests.<br>
 * SETUP:<br>
 * 1. Get a connected host and get a VM from it.<br>
 * 2. If VM is not present then create one.<br>
 * 3. Create a DVSwitch and add the host to DVS using free pNIC's.<br>
 * 4. If dvPortGroupType is specified then create the PortGroup else create one
 * standalone DVPort.<br>
 * 5. Reconfigure the VM to make sure that it has only the required network
 * adopter as specified by "deviceType".<br>
 * <br>
 * TEST:<br>
 * 1. Reconfigure the VM to use the created dvPort / vdPortGroup<br>
 * 2. Verify by comparing the config specs.<br>
 * 3. Power on the VM.<br>
 * 4. Verify Port Persistence Location on host & Port Connection on VM.<br>
 * 5. Check network connectivity if CHECK_GUEST is true.<br>
 * 6. Reconfigure the VM to remove the adopter to prepare for hot add.<br>
 * 7. Power on the VM and hot add the adopter and repeat #4 & #5<br>
 * <br>
 * CLEANUP:<br>
 * 8. Power off the VM.<br>
 * 9. Delete the VM if it was created else restore it's original Config.<br>
 * 10.Remove the host from DVS.<br>
 * <br>
 * 
 * @param connectAnchor ConnectAnchor object
 * @return boolean true, if setup is successful. false, otherwise.
 * @see #deviceType
 * @see DVSTestConstants#CHECK_GUEST
 */
public abstract class Copy_2_of_ReconfigureVMBase extends VMopsBase
{
   protected String deviceType = null;
   protected DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   protected String dvSwitchUuid = null;
   protected String portKey = null;
   protected ManagedObjectReference vmMor = null;
   protected String vmName = null;
   protected VirtualMachineConfigSpec originalVMConfigSpec = null;
   protected String hostIPAddress = null;
   protected String testHostName = null;
   protected String portgroupType = null;
   protected boolean connectToPort = true;
   protected boolean vmCreated;

   @Override
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      List<String> portKeys = null;
      String portgroupKey = null;
      Map<ManagedObjectReference, HostSystemInformation> allHosts;
      Vector<ManagedObjectReference> hostVMs;
      ManagedObjectReference portgroupMor;
      assertTrue(super.testSetUp(), "Super setup failed.");
      allHosts = ihs.getAllHosts(ESX4x, CONNECTED);
      assertNotNull(allHosts, HOST_GET_PASS, HOST_GET_FAIL);
      hostMor = allHosts.keySet().iterator().next();
      hostIPAddress = ihs.getIPAddress(hostMor);
      testHostName = ihs.getHostName(hostMor);
      log.info("Host MOR: " + hostMor + "   Host Name: " + testHostName);
      hostVMs = ihs.getVMs(hostMor, null);
      /* If no VM's are found create one */
      if (hostVMs == null || hostVMs.isEmpty()) {
         log.warn("No VMs found in host: " + testHostName
                  + ", Creating...");
         vmName = getTestId() + "-vDS";
         vmMor = ivm.createDefaultVM(vmName, ihs.getPoolMor(hostMor), null);
         assertNotNull(vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);
         vmCreated = true;
      } else {
         vmMor = hostVMs.get(0);
         vmName = ivm.getName(vmMor);
      }
      log.info("Was VM created: " + vmCreated + ", CheckGuest: "
               + CHECK_GUEST);
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      dvSwitchUuid = iDVSwitch.getConfig(dvsMor).getUuid();
      log.info("Sleep for 10 sec's to make sure that host and VC are in sync");
      ThreadUtil.sleep(1000);
      nwSystemMor = ins.getNetworkSystem(hostMor);
      assertTrue(ins.refresh(nwSystemMor), "Failed to refresh host network");
      // Get the net cfg to migrate only free nics to DVS.
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertTrue(hostNetworkConfig[0] != null && hostNetworkConfig[1] != null,
               "Network Cfg to use DVS was not found!");
      log.info("Found the network Cfg, updating it now... ");
      networkUpdated = ins.updateNetworkConfig(nwSystemMor,
               hostNetworkConfig[0], CHANGEMODE_MODIFY);
      assertTrue(networkUpdated, "Failed to update network system to use DVS");
      log.info("Given vDS PortGroup type: " + portgroupType);
      if (portgroupType == null) {
         log.info("NO PortGroup TYPE is given, so adding standalone dvPort.");
         portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
      } else {// Create the vDS PortGroup Cfg.
         final DVPortgroupConfigSpec dvPGCfg = new DVPortgroupConfigSpec();
         dvPGCfg.setNumPorts(1);
         dvPGCfg.setConfigVersion("");
         dvPGCfg.setName(getTestId() + "-pg");
         dvPGCfg.setType(portgroupType);
         dvPGCfg.setConfigVersion("");
         portgroupMor = iDVSwitch.addPortGroups(dvsMor,
                  new DVPortgroupConfigSpec[] { dvPGCfg }).get(0);
         portgroupKey = iDVPortGroup.getKey(portgroupMor);
         if (connectToPort) {
            portKeys = iDVPortGroup.getPortKeys(portgroupMor);
         }
      }
      assertTrue(portKeys != null || portgroupKey != null,
               "Failed to get vDS Port / PortGroup");
      log.info("Successfully got vDS Port / PortGroup");
      if (portKeys != null && portKeys.size() > 0) {
         portKey = portKeys.get(0);
      }
      dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
               dvSwitchUuid, portKey, portgroupKey);
      assertTrue(ivm.setVMState(vmMor, POWERED_OFF, false),
               "Can not power off the VM: " + vmName);
      final VirtualMachineConfigSpec[] vmCfgSpecs;
      // Here we get delta cfg which will contain only required adopter.
      vmCfgSpecs = getVMReconfigSpec(vmMor, connectAnchor, deviceType);
      if (vmCfgSpecs[0] == null && vmCfgSpecs[1] != null) {
         status = true; // VM is already having adopter of required type!
         originalVMConfigSpec = vmCfgSpecs[1];
      } else if (vmCfgSpecs[0] != null && vmCfgSpecs[1] != null) {
         log.info("Successfully obtained the VM config"
                  + " spec to update to");
         originalVMConfigSpec = vmCfgSpecs[1];
         log.info("Now reconfigure the VM to have required adopter only");
         assertTrue(ivm.reconfigVM(vmMor, vmCfgSpecs[0]), VM_RECONFIG_FAIL);
         log.info("Now VM has '" + deviceType + "' Ethernet adapter");
         // To remove the added adopter we have set its key.
         List<VirtualDeviceConfigSpec> currentEthCards;
         currentEthCards = DVSUtil.getAllVirtualEthernetCardDevices(vmMor,
                  connectAnchor);
         VirtualDeviceConfigSpec[] cfg = com.vmware.vcqa.util.TestUtil.vectorToArray(originalVMConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class);
         if (cfg != null && cfg.length > 0) {
            for (VirtualDeviceConfigSpec vdCfg : cfg) {
               if (vdCfg.getOperation().equals(REMOVE)) {
                  for (VirtualDeviceConfigSpec anEthCard : currentEthCards) {
                     VirtualDevice ethCard = anEthCard.getDevice();
                     if (vdCfg.getDevice().getClass().equals(ethCard.getClass())) {
                        log.info("Added ethCard is: "
                                 + ethCard.getClass()
                                 + "  Setting device key: " + ethCard.getKey());
                        vdCfg.getDevice().setKey(ethCard.getKey());
                     }
                  }
               }
            }
            status = true;
         }
      } else {
         log.error("Can not obtain the VM configuration to update to");
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test that reconfigures a powered off VM to connect to the DVSwitch and
    * also verifies that the hot add virtual nic works.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test
   public void test()
      throws Exception
   {
      VirtualMachineConfigSpec vmConfigSpec[] = null;
      VirtualMachineConfigSpec deltaCfg = null;
      VirtualMachineConfigSpec originalVMCfg = null;
      originalVMCfg = ivm.getVMConfigSpec(vmMor);
      deltaCfg = DVSUtil.getVMConfigSpecForDVSPort(
               vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { dvsPortConnection })[0];
      assertNotNull(deltaCfg, "Failed to get VM Cfg to reconfigure to vDS");
      log.info("Obtained the delta config spec for the VM: " + vmName);
      assertTrue(ivm.reconfigVM(vmMor, deltaCfg), "Failed re-configure VM.");
      log.info("Successfully reconfigured the VM: " + vmName);
      log.info("Comparing VM ConfigSpec... ");
      final VirtualMachineConfigSpec newCfg = ivm.getVMConfigSpec(vmMor);
      assertTrue(ivm.compareVMConfigSpec(originalVMCfg, deltaCfg, newCfg), "");
      log.info("Verified that VM has been reconfigured as per spec: "
               + vmName);
      assertTrue(ivm.setVMState(vmMor, POWERED_ON, false), VM_POWERON_PASS
               + vmName, VM_POWERON_FAIL + vmName);
      log.info("Verify Persistence Location of dvPort...");
      assertTrue(InternalDVSHelper.verifyPortPersistenceLocation(new ConnectAnchor(
               testHostName, data.getInt(TestConstants.TESTINPUT_PORT)),
               vmName, dvSwitchUuid),
               "Verification for PortPersistenceLocation failed");
      log.info("Now verify dvPort Connection on VM...");
      assertTrue(DVSUtil.verifyPortConnectionOnVM(connectAnchor, vmMor,
               dvsPortConnection),
               "Verification for PortPersistenceLocation failed");
      if (!vmCreated && CHECK_GUEST) {
         final String ipAddr = ivm.getIPAddress(vmMor);
         assertNotNull(ipAddr, "Failed to get IP of the VM: " + vmName);
         assertTrue(DVSUtil.checkNetworkConnectivity(hostIPAddress, ipAddr,
                  true), "VM is not connected to network: " + vmName);
         log.info("Verified the network connectivity to VM: " + vmName);
      } else {
         log.info("Didn't check for network connectivity.");
      }
      assertTrue(ivm.setVMState(vmMor, POWERED_OFF, false), VM_POWEROFF_FAIL);
      log.info("Succesfully powered off the VM " + vmName);
      vmConfigSpec = getHotAddVMSpec(deltaCfg);
      assertTrue(vmConfigSpec[0] != null && vmConfigSpec[1] != null,
               "Failed to get VMCfg for hot add");
      log.info("Now reconfig the VMCfg to prepare for hot add...");
      assertTrue(ivm.reconfigVM(vmMor, vmConfigSpec[0]),
               "Failed to prepare for hot add.");
      log.info("Successfully removed the VM ethernet adapter");
      assertTrue(ivm.setVMState(vmMor, POWERED_ON, false), VM_POWERON_FAIL);
      log.info("Successfully powered on the VM: " + vmName);
      assertTrue(ivm.reconfigVM(vmMor, vmConfigSpec[1]),
               "Can not hot add the VM network adopter: " + deviceType);
      log.info("Hot add Successful for adopter: " + deviceType);
      log.info("Verify Persistence Location of dvPort...");
      assertTrue(InternalDVSHelper.verifyPortPersistenceLocation(new ConnectAnchor(
               testHostName, data.getInt(TestConstants.TESTINPUT_PORT)),
               vmName, dvSwitchUuid),
               "Verification for PortPersistenceLocation failed");
      log.info("Now verify dvPort Connection on VM...");
      assertTrue(DVSUtil.verifyPortConnectionOnVM(connectAnchor, vmMor,
               dvsPortConnection), "Verification for PortConnectionOnVM failed");
      if (!vmCreated && DVSTestConstants.CHECK_GUEST) {
         final String ipAddr = ivm.getIPAddress(vmMor);
         assertNotNull(ipAddr, "Failed to get IP of the VM: " + vmName);
         assertTrue(DVSUtil.checkNetworkConnectivity(hostIPAddress, ipAddr,
                  true), "VM is not connected to network: " + vmName);
      } else {
         log.info("Did't check for network connectivity after hot add.");
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
         if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            log.info("Successfully powered off the vm " + vmName);
            if (vmCreated) {
               log.info("Destroying the created VM: " + vmName);
               status &= ivm.destroy(vmMor);
            } else if (originalVMConfigSpec != null) {
               log.info("Reconfiguring the VM to its original state");
               if (ivm.reconfigVM(vmMor, originalVMConfigSpec)) {
                  log.info("VM in its original state now! : " + vmName);
               } else {
                  log.error("Failed to restore VM to original state: "
                           + vmName);
                  status = false;
               }
            }
         } else {
            log.warn("VM not found");
         }
      } catch (Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      try {
         if (networkUpdated) {
            log.info("Restore the network to use vSwitch...");
            status &= ins.updateNetworkConfig(nwSystemMor,
                     hostNetworkConfig[1], CHANGEMODE_MODIFY);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Returns the virtualMachineConfigSpec to hot add the vm ethernet adapter
    * 
    * @param vmConfigSpec VirtualMachineConfigSpec
    * @return VirtualMachineConfigSpec[]
    */
   private VirtualMachineConfigSpec[] getHotAddVMSpec(VirtualMachineConfigSpec vmConfigSpec)
      throws Exception
   {
      VirtualMachineConfigSpec[] vmConfigSpecs = new VirtualMachineConfigSpec[2];
      VirtualMachineConfigSpec deltaConfigSpec = null;
      if (vmConfigSpec != null) {
         deltaConfigSpec = (VirtualMachineConfigSpec) TestUtil.deepCopyObject(vmConfigSpec);
         if (com.vmware.vcqa.util.TestUtil.vectorToArray(vmConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class) != null
                  && com.vmware.vcqa.util.TestUtil.vectorToArray(vmConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class).length > 0) {
            for (VirtualDeviceConfigSpec vdConfigSpec : com.vmware.vcqa.util.TestUtil.vectorToArray(vmConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class)) {
               if (vdConfigSpec.getDevice() != null
                        && vdConfigSpec.getDevice() instanceof VirtualEthernetCard) {
                  vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
                  vmConfigSpecs[0] = vmConfigSpec;
                  break;
               }
            }
            for (VirtualDeviceConfigSpec vdConfigSpec : com.vmware.vcqa.util.TestUtil.vectorToArray(deltaConfigSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class)) {
               if (vdConfigSpec.getDevice() != null
                        && vdConfigSpec.getDevice() instanceof VirtualEthernetCard) {
                  vdConfigSpec.setOperation(VirtualDeviceConfigSpecOperation.ADD);
                  vmConfigSpecs[1] = deltaConfigSpec;
                  break;
               }
            }
         }
      }
      return vmConfigSpecs;
   }
}