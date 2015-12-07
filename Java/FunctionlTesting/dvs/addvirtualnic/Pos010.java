/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addvirtualnic;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.NETWORK_SYS_MOR_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.NETWORK_SYS_MOR_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROPS_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROPS_PASS;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;
import java.util.Map.Entry;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSCreateSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.PhysicalNic;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.VNicBase;

/**
 * Create a DVS with a host having FCoE nic. Reconfigure a VM to connect to the
 * FCoE VMNetwork on DVS and check whether it’s pingable
 * Procedure:
 *  1. Create a DVS using FCoE NIC.
 *  2. Reconfigure a VM to connect to the FCoE VMNetwork.
 */
public class Pos010 extends VNicBase
{
   private HostSystem hs;
   private NetworkSystem ns;
   private VirtualMachine vm;
   private ManagedObjectReference hostMor;
   private ManagedObjectReference nwSystemMor;
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference vmFolderMor;
   private ManagedObjectReference vmMor;
   private ManagedObjectReference poolMor;
   private ManagedObjectReference portgroupMor;
   private DistributedVirtualSwitch dVSwitch;
   private VirtualMachineConfigSpec vmConfigSpec;
   private DistributedVirtualSwitch DVS;
   private DVSCreateSpec createSpec;
   private HashMap<ManagedObjectReference, List<PhysicalNic>> hMap;
   private List<PhysicalNic> fcoePnics;
   private String pgName = "AddVirtualNic-Pos010-PG2";
   private String pNic;
   private String vNic;
   private String dvsUuid;
   private String vmName;
   private String portgroupKey;
   private List<String> portKeys;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a DVS with a host having FCoE nic."
               + " Reconfigure a VM to connect to the FCoE VMNetwork on DVS and "
               + "check whether it’s pingable.");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {

      boolean setupDone = true;
      log.info("Test setup started");
      Entry<ManagedObjectReference, List<PhysicalNic>> entry = null;
      this.ns = new NetworkSystem(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.dVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.vm = new VirtualMachine(connectAnchor);
      this.vmFolderMor = this.vm.getVMFolder();
      this.dvsName = getTestId() + "-DVS";
      this.iFolder = new Folder(connectAnchor);
      this.DVS = new DistributedVirtualSwitch(connectAnchor);

      assertTrue(super.testSetUp(), "Faild to Initialize");

      this.hMap = NetworkUtil.getHostsFreeFcoeNics(connectAnchor);
      assertTrue((this.hMap != null) && !this.hMap.isEmpty(),
               "Failed to get the Hash Map");
      entry = this.hMap.entrySet().iterator().next();
      this.hostMor = entry.getKey();
      this.fcoePnics = entry.getValue();
      this.pNic = this.fcoePnics.get(0).getDevice();

      this.poolMor = this.hs.getPoolMor(this.hostMor);
      this.vmName = TestUtil.getRandomizedTestId(this.getClass().getName());

      this.nwSystemMor = this.ns.getNetworkSystem(this.hostMor);
      assertNotNull(this.nwSystemMor, NETWORK_SYS_MOR_PASS,
               NETWORK_SYS_MOR_FAIL);

      this.createSpec = DVSUtil.createDVSCreateSpec(
               DVSUtil.createDefaultDVSConfigSpec(null), null, null);
      assertNotNull(this.createSpec, "DVSCreateSpec is null");

      this.dvsMor = DVSUtil.createDVSFromCreateSpec(connectAnchor,
               this.createSpec);
      assertNotNull(this.dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");

      Map<ManagedObjectReference, String> pNicMap = new HashMap<ManagedObjectReference, String>();
      pNicMap.put(hostMor, pNic);
      assertTrue(DVSUtil.addHostsWithPnicsToDVS(connectAnchor, this.dvsMor,
               pNicMap), "Successfully added the pNic in to DVS",
               "Failed to add the pNic in to DVS");

      dvsUuid = this.dVSwitch.getConfig(dvsMor).getUuid();
      log.info("Add a standalone DVPort to connect the VNIC...");
      portKeys = this.dVSwitch.addStandaloneDVPorts(dvsMor, 1);

      DVPortgroupConfigSpec dvPGCfg = new DVPortgroupConfigSpec();
      dvPGCfg.setNumPorts(1);
      dvPGCfg.setName(pgName);
      dvPGCfg.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvPGCfg.setConfigVersion("");
      portgroupMor = iDVSwitch.addPortGroups(dvsMor,
               new DVPortgroupConfigSpec[] { dvPGCfg }).get(0);
      portgroupKey = iDVPortGroup.getKey(portgroupMor);

      assertTrue((portKeys != null) && (!portKeys.isEmpty())
               && (portgroupKey != null), "got portkeys: " + portKeys,
               "Failed to get the standalone DVPort.");
      return setupDone;
   }

   @Test(description = "Create a DVS with a host having FCoE nic."
               + " Reconfigure a VM to connect to the FCoE VMNetwork on DVS and "
               + "check whether it’s pingable.")
   public void test()
      throws Exception
   {
      DistributedVirtualSwitchPortConnection portConnection = null;
      log.info("test Begin...");

      portConnection = buildDistributedVirtualSwitchPortConnection(dvsUuid,
               portKeys.get(0), null);
      vNic = addVnic(hostMor, portConnection);
      assertNotNull(vNic, "Successfully added the VNIC.",
               "Failed to add the virtual nic");

      Vector<String> devices = new Vector<String>();
      devices.add(TestConstants.VM_CREATE_DEFAULT_DEVICE_TYPE);

      this.vmConfigSpec = this.vm.createVMConfigSpec(this.poolMor,
               this.hostMor, this.vmName,
               TestConstants.VM_DEFAULT_GUEST_WINDOWS, devices, null);
      this.vmConfigSpec.setVersion(data.getString("vmDiskVersion"));

      this.vmMor = new Folder(super.getConnectAnchor()).createVM(
               this.vmFolderMor, vmConfigSpec, this.poolMor, this.hostMor);
      assertNotNull(this.vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);
      assertTrue(this.vm.verifyPowerOps(this.vmMor, false), VM_POWEROPS_PASS,
               VM_POWEROPS_FAIL);

      assertTrue(NetworkUtil.reconfigVMToUsePortGroup(connectAnchor,
               this.vmMor, pgName),
               "Successfully reconfigured the VM with the prortgropup",
               "Failed to reconfigure the VM");
      assertTrue(this.vm.verifyPowerOps(this.vmMor, false), VM_POWEROPS_PASS,
               VM_POWEROPS_FAIL);
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanupDone = true;
      if (this.vmMor != null) {
         if (this.vm.destroy(this.vmMor)) {
            log.info(VM_DEL_PASS);
         } else {
            log.error(VM_DEL_FAIL);
            cleanupDone = false;
         }
      }
      if (vNic != null) {
         cleanupDone &= ns.removeVirtualNic(nwSystemMor, vNic);
         if (cleanupDone) {
            log.info("Successfully remove the add vNic.");
         } else {
            log.error("Failed to remove the added vNic");
            cleanupDone = false;
         }
      }
      if ((this.portKeys != null) && (this.portKeys.size() > 0)
               && (this.portKeys.get(0) != null)) {
         log.info("Sleeping for 4 seconds");
         Thread.sleep(4000);
         if (this.dVSwitch.refreshPortState(this.dvsMor,
                  new String[] { portKeys.get(0) })) {
            log.info("Successfully refreshed the port state");
         } else {
            log.error("Can not refresh the port state");
            cleanupDone = false;
         }
      }
      if (this.dvsMor != null) {
         if (this.DVS.destroy(dvsMor)) {
            log.info("Successfully deleted DVS");
         } else {
            log.error("Unable to delete DVS");
            cleanupDone = false;
         }
      }
      return cleanupDone;
   }
}