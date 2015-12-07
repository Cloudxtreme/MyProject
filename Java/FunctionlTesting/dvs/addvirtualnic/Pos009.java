/*
 * ************************************************************************
 *
 * Copyright 2010-2011 VMware, Inc. All rights reserved. -- VMware Confidential
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
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_PASS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicManagerNicType;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.PhysicalNic;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.vim.ClusterHelper;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.VirtualNicManager;

import dvs.VNicBase;

/**
 * Create a vmknic on a DVS (with host having FCoE NIC) & do the following. (I/O
 * happens through the physical FcoE nic)
 *  a). VMotion b). Storage VMotion.
 * Procedure:
 *  1. Create a vmknic on a vSwitch connected to FCoE NIC.
 *  2. Create a VM.
 *  3. Do the Storage VMotion and VMotion.
 */
public class Pos009 extends VNicBase
{
   private HostSystem hs;
   private NetworkSystem ns;
   private Folder folder;
   private VirtualMachine vm;
   private ClusterHelper ic;
   private ManagedObjectReference srcHostMor;
   private ManagedObjectReference desHostMor;
   private ManagedObjectReference networkSysMor;
   private ManagedObjectReference srcNWSystemMor;
   private ManagedObjectReference desNWSystemMor;
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference vmFolderMor;
   private ManagedObjectReference vmMor;
   private ManagedObjectReference srcPoolMor;
   private ManagedObjectReference desPoolMor;
   private ManagedObjectReference desDSMor;
   private DatastoreInformation datastoreInfo;
   private DistributedVirtualSwitch dVSwitch;
   private VirtualNicManager iVNicMgr;
   private VirtualMachineConfigSpec vmConfigSpec;
   private VirtualMachineRelocateSpec vmRelocateSpec;
   private DistributedVirtualSwitch DVS;
   private DistributedVirtualSwitchPortConnection portConnection;
   private HostVirtualNic hostVnic;
   private HostNetworkInfo networkInfo;
   private HostVirtualNic[] hostVirtualNics;
   private HashMap<ManagedObjectReference, List<PhysicalNic>> hMap;
   private Vector<ManagedObjectReference> allHostMor;
   private List<PhysicalNic> fcoePnics;
   private String pgName = "AddVirtualNic-Pos009-PG2";
   private HostVirtualNicSpec hostVNicSpec;
   private String vNic;
   private String pNic;
   private String dvsUuid;
   private String vmName;
   private Vector vNicStatus;
   private String portgroupKey;
   private String existingdevice;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a vmknic on a DVS (with host having FCoE NIC)"
               + " & do the following.(I/O happens through the physical FcoE nic)"
               + " a). Storage VMotion b). VMotion.");
   }

   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = true;
      log.info("Test setup started");
      this.ns = new NetworkSystem(connectAnchor);
      this.hs = new HostSystem(connectAnchor);
      this.folder = new Folder(connectAnchor);
      this.dVSwitch = new DistributedVirtualSwitch(connectAnchor);
      this.vm = new VirtualMachine(connectAnchor);
      this.vmFolderMor = this.vm.getVMFolder();
      this.DVS = new DistributedVirtualSwitch(connectAnchor);
      this.iVNicMgr = new VirtualNicManager(connectAnchor);
      this.ic = new ClusterHelper(connectAnchor);

      assertTrue(super.testSetUp(), "Faild to Initialize");

      this.allHostMor = this.hs.getAllHost();
      assertTrue(this.allHostMor.size() > 0, "Hosts not found");
      this.srcHostMor = (ManagedObjectReference) this.allHostMor.elementAt(0);
      log.info("Host found = " + this.hs.getName(this.srcHostMor));
      this.srcPoolMor = this.hs.getPoolMor(this.srcHostMor);
      this.vmName = this.getTestId();
      this.desHostMor = (ManagedObjectReference) this.allHostMor.elementAt(1);
      log.info("Host found = " + this.hs.getName(this.desHostMor));
      this.desPoolMor = this.hs.getPoolMor(this.desHostMor);

      this.srcNWSystemMor = this.ns.getNetworkSystem(this.srcHostMor);
      assertNotNull(this.srcNWSystemMor, NETWORK_SYS_MOR_PASS,
               NETWORK_SYS_MOR_FAIL);
      this.desNWSystemMor = this.ns.getNetworkSystem(this.desHostMor);
      assertNotNull(this.desNWSystemMor, NETWORK_SYS_MOR_PASS,
               NETWORK_SYS_MOR_FAIL);

      this.hMap = NetworkUtil.getHostsFreeFcoeNics(connectAnchor);
      assertTrue((this.hMap != null) && !this.hMap.isEmpty(),
               "Failed to get the Hash Map");

      this.dvsMor = this.folder.createDistributedVirtualSwitch(getTestId());
      assertNotNull(this.dvsMor, "Successfully created the DVSwitch",
               "Null returned for Distributed Virtual Switch MOR");
      portgroupKey = this.dVSwitch.addPortGroup(this.dvsMor,
               DVPORTGROUP_TYPE_EARLY_BINDING, 8, pgName);
      assertNotNull(portgroupKey, "Failed to get the DVPortKeys.");

      for (ManagedObjectReference hostMors : this.hMap.keySet()) {
         this.hostMor = hostMors;
         HostIpConfig hostIpConfig = new HostIpConfig();
         hostIpConfig.setDhcp(false);
         if (this.hostMor.equals(this.srcHostMor)) {
            assertNotNull(TestDataHandler.getValue("fcoe.vnic.ip.address1",
                     null), "Did not find FCoE Vnic IP address1");
            hostIpConfig.setIpAddress(TestDataHandler.getValue(
                     "fcoe.vnic.ip.address1", null));
         } else {
            assertNotNull(TestDataHandler.getValue("fcoe.vnic.ip.address2",
                     null), "Did not find FCoE Vnic IP address2");
            hostIpConfig.setIpAddress(TestDataHandler.getValue(
                     "fcoe.vnic.ip.address2", null));
         }
         assertNotNull(TestDataHandler.getValue("fcoe.vnic.subnetmask.address",
                  null), "Did not find FCoE subnetmask address");
         hostIpConfig.setSubnetMask(TestDataHandler.getValue(
                  "fcoe.vnic.subnetmask.address", null));
         this.hostVNicSpec = new HostVirtualNicSpec();
         this.hostVNicSpec.setIp(hostIpConfig);

         Map<ManagedObjectReference, String> pNicMap;
         pNicMap = new HashMap<ManagedObjectReference, String>();
         this.fcoePnics = this.hMap.get(hostMors);
         this.pNic = this.fcoePnics.get(0).getDevice();
         log.info("add {} Host to DVS win nic {}", hs.getName(hostMors), pNic);
         pNicMap.put(this.hostMor, this.pNic);

         assertTrue(DVSUtil.addHostsWithPnicsToDVS(connectAnchor, this.dvsMor,
                  pNicMap), "Successfully added the pNic in to DVS",
                  "Failed to add the pNic in to DVS");

         dvsUuid = this.dVSwitch.getConfig(dvsMor).getUuid();
         portConnection = buildDistributedVirtualSwitchPortConnection(dvsUuid,
                  null, portgroupKey);

         vNic = addVnic(this.hostMor, portConnection);
         assertNotNull(vNic, "Successfully added the VNIC:: " + vNic,
                  "Failed to add the virtual nic:: " + vNic);

         if (this.hostMor.equals(this.desHostMor)) {
            this.networkInfo = this.ns.getNetworkInfo(this.desNWSystemMor);
            this.networkSysMor = this.desNWSystemMor;
         } else {
            this.networkInfo = this.ns.getNetworkInfo(this.srcNWSystemMor);
            this.networkSysMor = this.srcNWSystemMor;
         }
         assertNotNull(networkInfo, "host network info object is null");
         hostVirtualNics = com.vmware.vcqa.util.TestUtil.vectorToArray(networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);
         assertNotNull(hostVirtualNics, "Cannot find any vnics on the host");
         for (HostVirtualNic hostVirtualNic1 : hostVirtualNics) {
            hostVnic = hostVirtualNic1;
            if (hostVnic.getPortgroup().equalsIgnoreCase("")) {
               existingdevice = hostVnic.getDevice();
               assertNotNull(existingdevice, "The virtual nic device name is"
                        + "null");
               assertTrue(this.ins.updateVirtualNic(this.networkSysMor,
                        existingdevice, this.hostVNicSpec),
                        "Succesfully updated existing Virtual NIC"
                                 + existingdevice,
                        "Cannot update the existing Virtual Nic");
            } else {
               log.info("Cannot find the matching port " + "group");
            }
         }

         hostVirtualNics = com.vmware.vcqa.util.TestUtil.vectorToArray(this.networkInfo.getVnic(), com.vmware.vc.HostVirtualNic.class);
         Assert.assertTrue((hostVirtualNics != null)
                  && (hostVirtualNics.length > 0),
                  "The list of virtual nics is not null",
                  "The list of virtual nics is null");
         for (HostVirtualNic vnic : hostVirtualNics) {
            if (vnic.getDevice().equals(vNic)) {
               hostVnic = vnic;
            }
         }

         this.vNicStatus = this.iVNicMgr.modifyvmkNicType(this.hostMor, HostVirtualNicManagerNicType.VMOTION.value(), hostVnic, true);
         assertTrue((Boolean) this.vNicStatus.get(0),
                  "Successfully enabled the vmotion in specified host ::: "
                           + this.hs.getHostName(this.hostMor),
                  "Unable to enable the vmotion in specified host  ::: "
                           + this.hs.getHostName(this.hostMor));
         Thread.sleep(60 * 1000);
      }
      return setupDone;
   }

   @Test(description = "Create a vmknic on a DVS (with host having FCoE NIC)"
            + " & do the following.(I/O happens through the physical FcoE nic)"
            + " a). Storage VMotion b). VMotion.")
   public void test()
      throws Exception
   {
      log.info("test Begin...");
      this.datastoreInfo = this.ic.getCommonDatastore(this.allHostMor.toArray(new ManagedObjectReference[this.allHostMor.size()]));
      assertNotNull(this.datastoreInfo, "Found datastore "
               + this.datastoreInfo.getName(), "Datastore Information is null");

      Vector<String> devices = new Vector<String>();
      devices.add(TestConstants.VM_CREATE_DEFAULT_DEVICE_TYPE);
      this.vmConfigSpec = this.vm.createVMConfigSpec(this.srcPoolMor,
               this.srcHostMor, this.vmName,
               TestConstants.VM_DEFAULT_GUEST_WINDOWS, devices, null);
      this.vmConfigSpec.setVersion(data.getString("vmDiskVersion"));
      this.vm.setDatastorePath(this.vmConfigSpec, this.datastoreInfo);

      this.vmMor = new Folder(super.getConnectAnchor()).createVM(
               this.vmFolderMor, vmConfigSpec, this.srcPoolMor, this.srcHostMor);
      assertNotNull(this.vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);

      assertTrue(NetworkUtil.reconfigVMToUsePortGroup(connectAnchor,
               this.vmMor, pgName),
               "Successfully reconfigured the VM with the prortgropup",
               "Failed to reconfigure the VM");

      Vector<DatastoreInformation> dsInfo = this.hs.getDatastoresInfo(this.desHostMor);
      assertNotNull(dsInfo, "Error while getting the datastore info.");
      for (int j = 0; j < dsInfo.size(); j++) {
         if (!this.vm.getDataStoreName(this.vmMor).equals(
                  dsInfo.get(j).getName())) {
            this.desDSMor = dsInfo.get(j).getDatastoreMor();
            break;
         }
      }
      assertNotNull(this.desDSMor,
               "Successful in getting the destination datastore mor.",
               "Error while getting the destination datastore mor.");

      this.vmRelocateSpec = new VirtualMachineRelocateSpec();
      this.vmRelocateSpec.setPool(this.desPoolMor);
      this.vmRelocateSpec.setHost(this.desHostMor);
      assertTrue(this.vm.powerOnVM(this.vmMor, null, false), VM_POWERON_PASS,
               VM_POWERON_FAIL);
      assertTrue(this.vm.relocateVM(this.vmMor, this.vmRelocateSpec, VirtualMachineMovePriority.DEFAULT_PRIORITY, true),
               "Successfully done the storage VMotion",
               "Failed to relocate VM " + this.vm.getName(this.vmMor));

      this.vmRelocateSpec = new VirtualMachineRelocateSpec();
      this.vmRelocateSpec.setDatastore(this.desDSMor);

      assertTrue(this.vm.relocateVM(this.vmMor, this.vmRelocateSpec, VirtualMachineMovePriority.DEFAULT_PRIORITY, true),
               "Successfully done the VMotion", "Failed to relocate VM "
                        + this.vm.getName(this.vmMor));
      assertTrue(this.vm.powerOffVM(this.vmMor), VM_POWEROFF_PASS,
               VM_POWEROFF_FAIL);
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanupDone = true;
      VirtualMachinePowerState expState = VirtualMachinePowerState.POWERED_OFF;
      log.info("Test cleanup started");

      if (this.vmMor != null) {
         if (this.vm.setVMState(this.vmMor, expState, false)) {
            log.info("Successfully powered off the VM.");
         }
         if (this.vm.destroy(this.vmMor)) {
            log.info(VM_DEL_PASS);
         } else {
            log.error(VM_DEL_FAIL);
            cleanupDone = false;
         }
      }
      if (this.vNic != null) {
         if (this.ns.removeVirtualNic(this.srcNWSystemMor, this.vNic)) {
            log.info("Successfully remove the add vNic.");
         } else {
            log.error("Failed to remove the added vNic");
            cleanupDone = false;
         }
         if (this.ns.removeVirtualNic(this.desNWSystemMor, this.vNic)) {
            log.info("Successfully remove the add vNic.");
         } else {
            log.error("Failed to remove the added vNic");
            cleanupDone = false;
         }
      }
      if (this.dvsMor != null) {
         if (this.DVS.destroy(this.dvsMor)) {
            log.info("Successfully deleted DVS");
         } else {
            log.error("Unable to delete DVS");
            cleanupDone = false;
         }
      }
      return cleanupDone;
   }
}