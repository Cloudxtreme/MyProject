/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vc.VirtualMachinePowerState.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

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
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
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
 * Add an early binding DVPortgroup to a DVS with scope set to Datacenter.
 */
public class Pos016 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DistributedVirtualPortgroup iDvPortgroup = null;
   private DVPortgroupConfigSpec dvPgCfg = null;
   private List<ManagedObjectReference> dvPgMors = null;
   private ManagedObjectReference hostMor = null;
   private HostSystem iHostSystem = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference networkMor = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private String portgroupKey = null;
   private ManagedObjectReference vmMor = null;
   private VirtualMachine iVirtualMachine = null;
   private Vector<ManagedObjectReference> allVMs = null;
   private VirtualMachinePowerState vmPowerState = null;
   private VirtualMachineConfigSpec[] vmDeltaCfg = null;
   private ManagedObjectReference dcMor = null;
   private boolean isEesx = false;

   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      iVirtualMachine = new VirtualMachine(connectAnchor);
      dcMor = iFolder.getDataCenter();
      assertNotNull(dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      hostMor = iHostSystem.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      log.info("Successfully found a host");
      isEesx = iHostSystem.isEesxHost(hostMor);
      networkMor = iNetworkSystem.getNetworkSystem(hostMor);
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(this.getClass().getName());
      hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMember.setHost(hostMor);
      hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostMember.setBacking(pnicBacking);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      allVMs = iHostSystem.getAllVirtualMachine(hostMor);
      assertNotNull(allVMs, VM_GET_PASS, VM_GET_FAIL);
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      iNetworkSystem.refresh(networkMor);
      Thread.sleep(10000);
      assertTrue(iNetworkSystem.updateNetworkConfig(networkMor,
               hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY),
               "Failed to update host network to DVS.");
      vmMor = allVMs.get(0);
      vmPowerState = iVirtualMachine.getVMState(vmMor);
      assertTrue(iVirtualMachine.setVMState(vmMor, POWERED_OFF, false),
               VM_POWERON_PASS, VM_POWEROFF_FAIL);
      dvPgCfg = new DVPortgroupConfigSpec();
      dvPgCfg.setConfigVersion("");
      dvPgCfg.setName(getTestId());
      dvPgCfg.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvPgCfg.setNumPorts(4);
      dvPgCfg.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvPgCfg.getScope().clear();
      dvPgCfg.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { dcMor }));
      return true;
   }

   @Override
   @Test(description = "Add an early binding DVPortgroup to a DVS with "
            + "scope set to datacenter")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      HostNetworkInfo networkInfo = null;
      HostVirtualNicSpec hostVnicSpec = null;
      DistributedVirtualSwitchPortConnection portConn;
      String vnicId = null;
      HostIpConfig ipConfig = null;
      final boolean checkGuest = DVSTestConstants.CHECK_GUEST;
      dvPgMors = iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvPgCfg });
      assertNotEmpty(dvPgMors, "Failed to add DVPortgroup");
      log.info("Successfully added the DVPortgroup");
      portgroupKey = iDvPortgroup.getKey(dvPgMors.get(0));
      log.info("Got DVPortgroup key {}", portgroupKey);
      portConn = iDVSwitch.getPortConnection(dvsMor, null, false, null,
               new String[] { portgroupKey });
      assertNotNull(portConn, "Failed to Get DVPortConnection.");
      log.info("Connect the VMKernel NIC to a free port in the DVPortgroup");
      hostVnicSpec = new HostVirtualNicSpec();
      hostVnicSpec.setDistributedVirtualPort(portConn);
      networkInfo = iNetworkSystem.getNetworkInfo(networkMor);
      assertNotNull(networkInfo, "Failed to get network info.");
      ipConfig = new HostIpConfig();
      ipConfig.setDhcp(true);
      hostVnicSpec.setIp(ipConfig);
      hostVnicSpec.setDistributedVirtualPort(portConn);
      log.info("Adding VNIC... ");
      vnicId = iNetworkSystem.addVirtualNic(networkMor, "", hostVnicSpec);
      assertNotNull(vnicId, "Failed to add VirtualNic.");
      log.info("Successfully added the VirtualNic to connect to a DVPort");
      assertTrue(iNetworkSystem.removeVirtualNic(networkMor, vnicId),
               "Failed to remove added VNic.");
      log.info("Connect a VM to the portgroup now...");
      portConn = iDVSwitch.getPortConnection(dvsMor, null, false, null,
               new String[] { portgroupKey });
      assertNotNull(portConn, "Failed to Get DVPortConnection.");
      vmDeltaCfg = DVSUtil.getVMConfigSpecForDVSPort(vmMor, connectAnchor,
               new DistributedVirtualSwitchPortConnection[] { portConn });
      assertTrue(iVirtualMachine.reconfigVM(vmMor, vmDeltaCfg[0]),
               "Failed to reconfigure the VM");
      log.info("Successfully reconfigured the VM to connect  to DVPortgroup");
      assertTrue(iVirtualMachine.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, checkGuest),
               "Failed to power on the VM");
      log.info("Successfully powered on the VM {}", vmMor);
      if (isEesx) {
         final String ip = iVirtualMachine.getIPAddress(vmMor);
         assertNotNull(ip, "Failed to get IP of VM");
         assertTrue(DVSUtil.checkNetworkConnectivity(
                  iHostSystem.getIPAddress(hostMor), ip),
                  "connectivity check failed");
      }
   }

   /**
    * Method to restore the state as it was before the test was started. Destroy
    * the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         /*
          * Restore the original power state of the VM
          */
         status &= iVirtualMachine.setVMState(vmMor, vmPowerState, false);
         /*
          * Restore the original configuration of the virtual machine
          */
         status &= iVirtualMachine.reconfigVM(vmMor, vmDeltaCfg[1]);
         /*
          * Restore the original network configuration of the host
          */
         status &= iNetworkSystem.updateNetworkConfig(networkMor,
                  hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
      } catch (final Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            /*
             * Destroy the distributed virtual switch
             */
            status &= iManagedEntity.destroy(dvsMor);
         } catch (final Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}