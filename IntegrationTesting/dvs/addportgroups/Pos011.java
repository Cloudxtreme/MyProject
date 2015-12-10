/*
 * ************************************************************************
 *
 * Copyright 2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vc.VirtualMachinePowerState.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.HashMap;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Add an early binding DVPortgroup to DVS with scope set to a virtual machine
 * MOR and reconfigure the VM to connect its vNIC to this DVPortgroup.
 */
public class Pos011 extends TestBase
{
   private ManagedEntity iManagedEntity = null;
   private DistributedVirtualSwitch dvs = null;
   private VirtualMachine vm = null;
   private HostSystem iHostSystem = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference vmMor = null;
   private ManagedObjectReference nsMor = null;
   private DVPortgroupConfigSpec dvPgCfgSpec = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private HostNetworkConfig originalNetworkConfig = null;
   private VirtualMachinePowerState vmPowerState = null;
   private DistributedVirtualSwitchHostMemberConfigSpec dvsHostMember = null;
   private List<ManagedObjectReference> dvPgMors = null;
   private DistributedVirtualSwitchPortConnection portConnection = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private VirtualMachineConfigSpec[] updatedDeltaConfigSpec = null;
   private final DistributedVirtualSwitchHostMemberPnicSpec[] dvsHostMemberPnicSpec = null;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      final String dvsName = getTestId();
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      Vector<ManagedObjectReference> allVMs;
      final Folder iFolder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      vm = new VirtualMachine(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      hostMor = iHostSystem.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      nsMor = iNetworkSystem.getNetworkSystem(hostMor);
      allVMs = iHostSystem.getVMs(hostMor, null);
      assertNotEmpty(allVMs, "Failed to get a VM");
      vmMor = allVMs.get(0);
      vmPowerState = vm.getVMState(vmMor);
      assertTrue(vm.setVMState(vmMor, POWERED_OFF, false), VM_POWERON_PASS,
               VM_POWERON_FAIL);
      final DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(dvsName);
      dvsHostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      dvsHostMember.setHost(hostMor);
      dvsHostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      dvsHostMember.setBacking(pnicBacking);
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(dvsHostMemberPnicSpec));
      dvsHostMember.setBacking(pnicBacking);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { dvsHostMember }));
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      hostNetworkConfig = dvs.getHostNetworkConfigMigrateToDVS(dvsMor, hostMor);
      assertTrue(iNetworkSystem.updateNetworkConfig(nsMor,
               hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY),
               "Failed to update network config on host");
      originalNetworkConfig = hostNetworkConfig[1];
      dvPgCfgSpec = new DVPortgroupConfigSpec();
      dvPgCfgSpec.setConfigVersion("");
      dvPgCfgSpec.setName(dvsName + "-pg");
      dvPgCfgSpec.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvPgCfgSpec.setNumPorts(1);
      dvPgCfgSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvPgCfgSpec.getScope().clear();
      dvPgCfgSpec.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { vmMor }));
      return true;
   }

   @Override
   @Test(description = "Add an early binding DVPortgroup to DVS with scope "
            + "set to a virtual machine MOR and reconfigure the VM to connect "
            + "its vNIC to this DVPortgroup.\r\n")
   public void test()
      throws Exception
   {
      final DVPortgroupConfigSpec[] dvPgCfgSpecs;
      dvPgCfgSpecs = new DVPortgroupConfigSpec[] { dvPgCfgSpec };
      dvPgMors = dvs.addPortGroups(dvsMor, dvPgCfgSpecs);
      assertNotEmpty(dvPgMors, "Added '" + dvPgMors.size() + "' Portgroups.",
               "Failed to add DVPortgroups");
      assertTrue(dvPgMors.size() == dvPgCfgSpecs.length,
               "Count of added port groups is not correct");
      final String portgroupKey = iDVPortgroup.getKey(dvPgMors.get(0));
      assertNotNull(portgroupKey, "Got PG key", "Failed to get PG key");
      final HashMap<String, List<String>> usedPorts = new HashMap<String, List<String>>();
      usedPorts.put(portgroupKey, null);
      portConnection = dvs.getPortConnection(dvsMor, null, false, usedPorts,
               new String[] { portgroupKey });
      updatedDeltaConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(vmMor,
               connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConnection });
      assertNotNull(updatedDeltaConfigSpec, "Failed to get delta VM Cfg Spec");
      assertTrue(vm.reconfigVM(vmMor, updatedDeltaConfigSpec[0]),
               "Failed to connect VM to DVPortgroup");
      log.info("Successfully reconfigured VM to connect to free port in DVPortgroup");
      assertTrue(vm.setVMState(vmMor, POWERED_ON, true), VM_POWERON_PASS,
               VM_POWERON_FAIL);
      /* Configure a wait time so that the guest OS in the VM boots. */
      ThreadUtil.sleep(50000);
      final String hostIp = iHostSystem.getIPAddress(hostMor);
      final String vmIp = vm.getIPAddress(vmMor);
      assertTrue(DVSUtil.checkNetworkConnectivity(hostIp, vmIp),
               "Network connectivity check failed.");
   }

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      /* Restore the original config spec of the virtual machine */
      if (vmMor != null && updatedDeltaConfigSpec != null) {
         status &= vm.reconfigVM(vmMor, updatedDeltaConfigSpec[1]);
         /* Restore the power state of the virtual machine */
         status &= vm.setVMState(vmMor, vmPowerState, false);
      }
      if (originalNetworkConfig != null) {// Restore original network config
         status &= iNetworkSystem.updateNetworkConfig(nsMor,
                  originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
      }
      // As per bug 660229 delete PG to make sure that we can delete it.
      if (dvPgMors != null) {
         for (final ManagedObjectReference mor : dvPgMors) {
            log.info("Destroying PG  {} ", iManagedEntity.getName(mor));
            status &= iManagedEntity.destroy(mor);
         }
      }
      if (dvsMor != null) {
         status &= dvs.destroy(dvsMor);
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
