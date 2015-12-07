/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.DVPortgroupConfigInfo;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Holds common attributes for DVS ElasticPortgroup test cases.<br>
 */
public final class ElasticPortgroupHelper
{
   private static final Logger log =
            LoggerFactory.getLogger(ElasticPortgroupHelper.class);
   private Folder folder;
   private HostSystem hostSystem;
   private VirtualMachine virtualMachine;
   private DistributedVirtualSwitch DVS;
   private DistributedVirtualPortgroup dvPortGroup;
   private ManagedObjectReference dvsMor;
   private ManagedObjectReference hostMor;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private String dvsName = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private String dvsSwitchUuid = null;
   private String dvPgKey = null;
   private Vector<ManagedObjectReference> newVms =
            new Vector<ManagedObjectReference>();
   private ConnectAnchor connectAnchor = null;
   private ManagedObjectReference vmPoolMor = null;
   private Map<String, VirtualMachineConfigSpec> vmMachineConfigSpecMap =
            new HashMap<String, VirtualMachineConfigSpec>();
   private Vector<ManagedObjectReference> snapshotVMs =
            new Vector<ManagedObjectReference>();
   private VirtualMachineConfigSpec vmConfigSpec = null;

   /**
    * Initialize the Helper using ConnectAnchor.
    *
    * @param connectAnchor ConnectAnchor.
    * @throws Exception If initialization fails.
    */
   public void init(ConnectAnchor connectAnchor)
      throws Exception
   {
      this.folder = new Folder(connectAnchor);
      this.DVS = new DistributedVirtualSwitch(connectAnchor);
      this.hostSystem = new HostSystem(connectAnchor);
      this.virtualMachine = new VirtualMachine(connectAnchor);
      this.dvPortGroup = new DistributedVirtualPortgroup(connectAnchor);
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setConfigVersion("");
      this.dvPortgroupConfigSpec.setName(TestUtil.getShortTime() + "_DVPG");
      this.hostMor = hostSystem.getConnectedHost(false);
      this.connectAnchor = connectAnchor;

   }

   /**
    * This method gets the number of ports in the portgroup
    *
    * @return number of ports in the portgroup
    *
    * @throws Exception, Methodfault
    */
   public int getNumPorts()
      throws Exception
   {
      List<DVPortgroupConfigInfo> pgConfigInfoList = this.dvPortGroup.
                                         getConfigInfo(this.dvPortgroupMorList);
      assertTrue(pgConfigInfoList.size() >= 1,"No portgroups were found on " +
         "the vds");
      return pgConfigInfoList.get(0).getNumPorts();
   }

   /**
    * This method returns DVPortgroupConfigSpec
    *
    * @throws Exception If initialization fails.
    */
   public DVPortgroupConfigSpec getDVPGConfigSpec()
   {
      return dvPortgroupConfigSpec;
   }

   /**
    * This method is used to set DVPortgroupConfigSpec
    *
    * @param spec DVPortgroupConfigSpec.
    */
   public void setDVPGConfigSpec(DVPortgroupConfigSpec spec)
   {
      dvPortgroupConfigSpec = spec;
   }

   /**
    * This method is used to initialize DVPortgroupConfigSpec with default
    * values
    *
    */
   public void resetDVPGConfigSpec()
   {
      this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
      this.dvPortgroupConfigSpec.setConfigVersion("");
      this.dvPortgroupConfigSpec.setName(TestUtil.getShortTime() + "_DVPG");
   }

   /**
    * Create DVS
    *
    * @throws Exception If failed to create DVS.
    */
   public void createDvsWithHostAttached()
      throws Exception
   {
      assertNotNull(this.connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      List<ManagedObjectReference> dvsMorList =
               new Vector<ManagedObjectReference>(1);
      dvsName = TestUtil.getShortTime() + "_DVS";
      dvsMor = folder.createDistributedVirtualSwitch(dvsName);
      assertNotNull(dvsMor, "Successfully created DVS: " + dvsName,
               "Failed to create DVS: " + dvsName);
      dvsMorList.add(dvsMor);
      assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor, hostSystem
               .getConnectedHost(false), dvsMorList),
               "Failed to add host to DVS");
      dvsSwitchUuid = DVS.getConfig(dvsMor).getUuid();
   }

   /**
    * Add PortGroups
    *
    * @throws Exception If failed to add Portgroup.
    */
   public void addDVPG()
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvPortgroupConfigSpec, "DVPortgroupConfigSpec is null");
      dvPortgroupConfigSpecArray =
               new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
      dvPortgroupMorList =
               DVS.addPortGroups(dvsMor, dvPortgroupConfigSpecArray);
      assertTrue(
               (dvPortgroupMorList != null && dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length),
               "Successfully added all the portgroups",
               "Failed to  add all the portgroups");
      dvPgKey = this.dvPortGroup.getKey(dvPortgroupMorList.get(0));
   }

   /**
    * This method is used to reconfigDVPG
    *
    * @throws Exception If failed to add Portgroup.
    */
   public void reconfigDVPG()
      throws Exception

   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(dvPortgroupConfigSpec, "DVPortgroupConfigSpec is null");
      dvPortgroupConfigSpec.setConfigVersion(this.dvPortGroup.getConfigInfo(
               dvPortgroupMorList.get(0)).getConfigVersion());
      dvPortgroupConfigSpecArray =
               new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
      assertTrue(dvPortGroup.reconfigure(dvPortgroupMorList.get(0),
               dvPortgroupConfigSpec),
               "Successfully Reconfigured  the portgroup",
               "Failed to  Reconfigure  the portgroup");
   }

   /**
    * This method creates given number of VMs( connected leagacy or DVS )on host
    *
    * @param vmCount number of VMs
    * @param isDVSPortConnection true for DVS, false for legacy.
    * @throws MethodFault
    * @throws Exception
    */
   public void createVm(int vmCount,
                        boolean isDVSPortConnection)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      DistributedVirtualSwitchPortConnection portConnection = null;
      String vmName = null;

      ManagedObjectReference vmMor = null;
      for (int i = 0; i < vmCount; i++) {
         vmName = "VM-" + i;
         log.info("Creating VM " + vmName);
         if (isDVSPortConnection) {
            portConnection = new DistributedVirtualSwitchPortConnection();
            portConnection.setPortgroupKey(dvPgKey);
            portConnection.setSwitchUuid(this.dvsSwitchUuid);
            vmConfigSpec =
                     DVSUtil.buildCreateVMCfg(connectAnchor, portConnection,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32, vmName,
                              this.hostMor);
            vmMor =
                     this.folder.createVM(virtualMachine.getVMFolder(),
                              vmConfigSpec, hostSystem.getPoolMor(hostMor),
                              null);
         } else {
            vmMor =
                     this.virtualMachine.createDefaultVM(vmName,
                              this.hostSystem.getPoolMor(this.hostMor),
                              this.hostMor);
         }
         vmPoolMor = virtualMachine.getResourcePool(vmMor);
         assertNotNull(vmMor, VM_CREATE_PASS + ":" + vmName, VM_CREATE_FAIL
                  + ":" + vmName);

         newVms.add(vmMor);
      }

   }

   /**
    * This method creates given number of VMs on host with the given
    * number of ethernet cards
    *
    * @param vmCount number of VMs
    * @param numEthernetCards number of ethernet cards
    *
    * @throws Exception, MethodFault
    */
   public void createVms(int vmCount,
                        int numEthernetCards)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      assertNotNull(hostMor,
               "Reference to the hostMor object is not null",
               "Reference to the hostMor object is null");
      newVms = DVSUtil.createVms(connectAnchor, hostMor, vmCount,
                                 numEthernetCards);
   }

   /**
    * Destroy the VM if created.
    *
    * @return true if successful, false otherwise.
    * @throws Exception If any problem occurs.
    */
   public boolean destroyVM()
      throws Exception
   {
      if (this.newVms != null && this.newVms.size() > 0) {
         this.virtualMachine.destroy(this.newVms);
      }
      return true;
   }

   /**
    * Destroy the DVS if created.
    *
    * @return true if successful, false otherwise.
    * @throws Exception If any problem occurs.
    */
   public boolean destroyDVS()
      throws Exception
   {
      if (this.dvsMor != null) {
         this.DVS.destroy(this.dvsMor);
      }
      return true;
   }

   /**
    * Reconfigures Vms to connect to DistributedVirtualSwitchPortConnection
    *
    * @return VirtualMachineConfigSpec delta VM configSpec.
    */
   public boolean reconfigVM()
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      VirtualMachineConfigSpec[] deltaVmConfigSpecs = null;
      DistributedVirtualSwitchPortConnection dvsConn = null;
      String vmName = null;
      assertTrue((this.newVms != null && this.newVms.size() > 0),
               "Failed to get vms");
      for (ManagedObjectReference vmMor : this.newVms) {
         vmName = this.virtualMachine.getVMName(vmMor);
         log.info("vmName : " + vmName);
         dvsConn = new DistributedVirtualSwitchPortConnection();
         dvsConn.setPortgroupKey(this.dvPgKey);
         dvsConn.setSwitchUuid(this.dvsSwitchUuid);
         deltaVmConfigSpecs =DVSUtil.getVMConfigSpecForDVSPort(vmMor,
                                                               connectAnchor,
                                                               new
                          DistributedVirtualSwitchPortConnection[] { dvsConn });
         assertNotNull(deltaVmConfigSpecs,
                  "Got the VM config, Now reconfiguring VM ...",
                  "VM config is null");
         assertTrue((virtualMachine.reconfigVM(vmMor, deltaVmConfigSpecs[0])),
                  "Successfully reconfigured the VM","Failed to reconfigure " +
                  		"the VM.");
         vmMachineConfigSpecMap.put(vmName, deltaVmConfigSpecs[1]);
      }
      return true;
   }

   /**
    * This method reconfigures vm to its original config spec only for the
    * given number of ethernet adapters
    *
    * @param numEthernetcards
    *
    * @return true if the vm was reconfigured to its original config spec
    *         false otherwise
    *
    * @throws Exception,MethodFault
    */
   public boolean reconfigVMToOriginalConfigSpec(int numEthernetcards)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      VirtualMachineConfigSpec[] deltaVmConfigSpecs = null;
      DistributedVirtualSwitchPortConnection dvsConn = null;
      String vmName = null;
      assertTrue((this.newVms != null && this.newVms.size() > 0),
               "Failed to get vms");
      for (ManagedObjectReference vmMor : this.newVms) {
         vmName = this.virtualMachine.getVMName(vmMor);
         log.info("vmName : " + vmName);
         dvsConn = new DistributedVirtualSwitchPortConnection();
         dvsConn.setPortgroupKey(this.dvPgKey);
         dvsConn.setSwitchUuid(this.dvsSwitchUuid);
         deltaVmConfigSpecs =DVSUtil.getVMConfigSpecForDVSPort(vmMor,
                                                               connectAnchor,
                                                               new
                          DistributedVirtualSwitchPortConnection[] { dvsConn });
         assertNotNull(deltaVmConfigSpecs,
                  "Got the VM config, Now reconfiguring VM ...",
                  "VM config is null");
         assertTrue((virtualMachine.reconfigVM(vmMor, deltaVmConfigSpecs[0])),
                  "Successfully reconfigured the VM","Failed to reconfigure " +
                        "the VM.");
         vmMachineConfigSpecMap.put(vmName, deltaVmConfigSpecs[1]);
      }
      return true;

   }

   /**
    * Reconfigures Vms to connect to DistributedVirtualSwitchPortConnection
    *
    */
   public boolean reconfigVMToOriginalVMConfigSpec()
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      String vmName = null;
      assertTrue((this.newVms != null && this.newVms.size() > 0),
               " Failed to get vms");
      for (Map.Entry<String, VirtualMachineConfigSpec> entry : vmMachineConfigSpecMap
               .entrySet()) {
         vmName = entry.getKey();
         log.info("vmName : " + vmName);
         assertTrue(this.virtualMachine.reconfigVM(this.virtualMachine
                  .getVM(vmName), this.vmMachineConfigSpecMap.get(vmName)),
                  "Successfully reconfigured the VM to disconnect from"
                           + " the DVS " + vmName);
      }

      return true;
   }


   /**
    * Reconfigures Vms to connect to DistributedVirtualSwitchPortConnection
    *
    * @return VirtualMachineConfigSpec delta VM configSpec.
    */
   public boolean cloneVM(int count)
      throws Exception
   {
      assertNotNull(connectAnchor,
               "Reference to the ConnectAnchor object is not null",
               "Reference to the ConnectAnchor object is null");
      Vector<ManagedObjectReference> clonedVms =
               new Vector<ManagedObjectReference>();
      DistributedVirtualSwitchPortConnection dvsConn = null;
      ManagedObjectReference cloneVMMor = null;
      String vmName = null;
      String cloneVMName = null;
      VirtualMachineCloneSpec cloneSpec = null;
      VirtualMachineRelocateSpec relocateSpec = null;

      assertTrue((this.newVms != null && this.newVms.size() > 0),
               " Failed to get vms");
      for (ManagedObjectReference vmMor : this.newVms) {
         dvsConn = new DistributedVirtualSwitchPortConnection();
         dvsConn.setPortgroupKey(this.dvPgKey);
         dvsConn.setSwitchUuid(this.dvsSwitchUuid);
         vmName = virtualMachine.getVMName(vmMor);
         cloneSpec = new VirtualMachineCloneSpec();
         cloneSpec.setTemplate(false);
         cloneSpec.setPowerOn(false);
         cloneSpec.setCustomization(null);
         relocateSpec = new VirtualMachineRelocateSpec();
         relocateSpec.setHost(hostMor);
         relocateSpec.setPool(vmPoolMor);
         relocateSpec.setDatastore(this.hostSystem.getDatastoresInfo(
                  this.hostMor).get(4).getDatastoreMor());
         cloneSpec.setLocation(relocateSpec);
         for (int i = 0; i < count; i++) {
            cloneVMName = vmName + "-Clone-" + i;
            cloneVMMor =
                     this.virtualMachine.cloneVM(vmMor, this.virtualMachine
                              .getVMFolder(), cloneVMName, cloneSpec);
            assertNotNull(cloneVMMor, "cloneVMMor is null");
            cloneVMName = this.virtualMachine.getVMName(cloneVMMor);
            assertTrue(DVSUtil.performVDSPortVerifcation(connectAnchor,
                     this.hostMor, cloneVMMor, dvsConn, this.dvsSwitchUuid),
                     " Failed to verify port connection  and/or PortPersistenceLocation for VM : "
                              + vmName);
            clonedVms.add(cloneVMMor);
         }

      }
      this.newVms.addAll(clonedVms);
      return true;
   }
   /**
    * Mark VM as a template
    *
    * @return true, on successful operation
    *         false, otherwise
    */
   public boolean markAsTemplate()
      throws Exception
   {
      assertTrue((this.newVms != null && this.newVms.size() > 0),
               " Failed to get vms");
      for (ManagedObjectReference vmMor : this.newVms) {
         assertTrue(
                  (this.virtualMachine.markAsTemplate(vmMor) && this.virtualMachine
                           .isTemplate(vmMor)),
                  "Succesfully converted the VM into template",
                  "Can not convert the VM into template");
      }
      return true;
   }

   /**
    * Creates a new snapshot of this virtual machine
    *
    * @return true, on successful operation
    *         false, otherwise
    */
   public boolean takeSnapShot()
      throws Exception
   {
      assertTrue((this.newVms != null && this.newVms.size() > 0),
               " Failed to get vms");

      for (ManagedObjectReference vmMor : this.newVms) {
         ManagedObjectReference snapshotMor =
                  this.virtualMachine.createSnapshot(vmMor, this.virtualMachine
                           .getVMName(vmMor)
                           + "-snapshot1", null, false, false);
         assertNotNull(snapshotMor,
                  "Failed to Create a new snapshot of this virtual machine");
         snapshotVMs.add(snapshotMor);
      }
      return true;
   }

   /**
    * Makes this snapshot the current snapshot for the virtual machine
    *
    * @return true, on successful operation
    *         false, otherwise
    */
   public boolean revertSnapShot()
      throws Exception
   {
      assertTrue((this.snapshotVMs != null && this.snapshotVMs.size() > 0),
               " Failed to get snapshots");
      for (ManagedObjectReference snapshotMor : this.snapshotVMs) {
         assertNotNull((new com.vmware.vcqa.vim.vm.Snapshot(this.connectAnchor)
                  .revertToSnapshot(snapshotMor, null, false)),
                  "Failed to revertToSnapshot");
      }
      return true;
   }

   /**
    * This method verifies portPersistenceLocation and PorttConnection On VM
    */
   public boolean verifyVMsPortConnection()
      throws Exception
   {

      assertTrue((this.newVms != null && this.newVms.size() > 0),
               " Failed to get vms");
      for (ManagedObjectReference vmMor : this.newVms) {
         DistributedVirtualSwitchPortConnection dvsConn =
                  new DistributedVirtualSwitchPortConnection();
         dvsConn.setPortgroupKey(this.dvPgKey);
         dvsConn.setSwitchUuid(this.dvsSwitchUuid);
         assertTrue(DVSUtil.performVDSPortVerifcation(connectAnchor,
                  this.hostMor, vmMor, dvsConn, this.dvsSwitchUuid),
                  " Failed to verify port connection  and/or PortPersistenceLocation for VM : "
                           + this.virtualMachine.getVMName(vmMor));

      }
      return true;
   }
}
