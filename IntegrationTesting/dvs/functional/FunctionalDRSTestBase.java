/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_DEL_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_REGISTER_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_REGISTER_PASS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.ClusterHelper;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.Task;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.StorageSystem;

/**
 * Abstract class that declares the common instance variables, common setup and
 * cleanup operations required by the tests of the dvs.functional tests package.
 */
public abstract class FunctionalDRSTestBase extends TestBase
{
   /*
    * protected data variables
    */
   protected UserSession loginSession = null;
   protected Folder iFolder = null;
   protected ClusterHelper icluster = null;
   protected ManagedEntity iManagedEntity = null;
   protected ClusterComputeResource icr = null;
   protected Task iTask = null;
   protected StorageSystem iss;
   protected NetworkSystem ins = null;
   protected HostSystem ihs = null;
   protected DistributedVirtualSwitch iDVS = null;
   protected DistributedVirtualPortgroup iDVPortgroup = null;
   protected NetworkSystem iNetworkSystem = null;
   protected VirtualMachine ivm = null;
   protected ManagedObjectReference dcMor = null;
   protected ManagedObjectReference rootFolder = null;
   protected ManagedObjectReference dvsMor = null;
   protected ManagedObjectReference pgMor = null;
   protected ManagedObjectReference nwSystemMor = null;
   protected Vector<ManagedObjectReference> allHosts = null;
   protected Vector<ManagedObjectReference> allVMs = null;
   protected String dvSwitchUUID = null;
   protected ManagedObjectReference networkFolderMor = null;
   protected ManagedObjectReference hostFolderMor = null;
   protected final int MAX_PORTS = 3;
   protected final int VM_COUNT = 3;
   protected boolean setMaxProxySwitchPorts = false;
   protected int reqdHosts = 2;
   protected int reqdVMs = 0;
   protected Datacenter dc = null;
   private Map<String, VirtualMachineConfigSpec> vmConfigspecMap = new HashMap<String, VirtualMachineConfigSpec>();
   protected ManagedObjectReference clusterMor = null;
   protected Vector<ManagedObjectReference> vmMors = null;
   protected Map<String, String> vmPathMap = new HashMap<String, String>();
   protected Map<String, ManagedObjectReference> vmResPoolMap = new HashMap<String, ManagedObjectReference>();
   protected Map<String, String> vmHostMap = new HashMap<String, String>();

   /**
    * Method that does the common setup for the functional tests, This creates a
    * DVSwitch and adds the host to that.
    *
    * @param ConnectAnchor connectAnchor
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;


         this.iFolder = new Folder(connectAnchor);
         this.icluster = new ClusterHelper(connectAnchor);
         this.icr = new ClusterComputeResource(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.ins = new NetworkSystem(connectAnchor);
         this.iDVS = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.ivm = new VirtualMachine(connectAnchor);
         this.ihs = new HostSystem(connectAnchor);
         this.iNetworkSystem = new NetworkSystem(connectAnchor);
         this.iss = new StorageSystem(connectAnchor);
         this.iTask = new Task(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
         this.dc = new Datacenter(connectAnchor);

         allHosts = this.ihs.getAllHost();
         assertTrue(allHosts != null && allHosts.size() >= reqdHosts,
                  "Found atleast " + reqdHosts + " hosts in Inventory.",
                  "This test requires atleast " + reqdHosts
                           + " hosts in inventory.");

         allHosts = this.ihs.getAllHost();
         assertTrue(allHosts != null && allHosts.size() >= reqdHosts,
                  "Found atleast " + reqdHosts + " hosts in Inventory.",
                  "This test requires atleast " + reqdHosts
                           + " hosts in inventory.");

         allVMs = ivm.getAllVM();
         hostFolderMor = iFolder.getHostFolder(dcMor);

         for (ManagedObjectReference hostMor : allHosts) {
            Vector<ManagedObjectReference> vms = ihs.getVMs(hostMor, null);
            if (vms != null && vms.size() > 0) {
               for (ManagedObjectReference vmMor : vms) {
                  String vmName = ivm.getName(vmMor);
                  /*
                   * Unregister vms here
                   */
                  vmPathMap.put(
                           this.ivm.getVMName(vmMor),
                           this.ivm.getVMConfigInfo(vmMor).getFiles().getVmPathName());
                  vmHostMap.put(this.ivm.getVMName(vmMor),
                           this.ivm.getHostName(vmMor));
                  assertTrue(ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false),
                           "Failed to PowerOff " + vmName);
                  assertTrue((this.ivm.unregisterVM(vmMor)),
                           "Successfully unregistered the VM :" + vmName,
                           "Unable to unregister the VM :" + vmName);
               }
            }
            /*
             * Create 3 vms with one nic card
             */
            this.vmMors = createVms(VM_COUNT, hostMor);
         }

         /*
          * Add DVS Switch
          */
         addDVSSwitch();

         /*
          * Add DVS Port group.
          */
         addDVSPortGroup();

         /*
          * Reconfigure each VM to use above DVS Port Group.
          *
          */
         for (ManagedObjectReference hostMor : allHosts) {
            String hostName = ihs.getHostName(hostMor);
            log.info("Host : " + hostName);
            Vector<ManagedObjectReference> vms = ihs.getVMs(hostMor, null);
            if (vms != null && vms.size() > 0) {
               for (ManagedObjectReference vmMor : vms) {
                  reconfigureVmToDVSPortGroup(vmMor);
               }
            }

         }

         setupDone = true;


      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   private void addDVSSwitch()
      throws Exception
   {
      DistributedVirtualSwitchHostMemberConfigSpec[] hostMemberList = new DistributedVirtualSwitchHostMemberConfigSpec[allHosts.size()];
      for (int i = 0; i < allHosts.size(); i++) {
         ManagedObjectReference hostMor = allHosts.elementAt(i);
         String[] freePnics = ins.getPNicIds(hostMor);
         assertTrue(freePnics != null && freePnics[0] != null,
                  "There are no free pnics on " + ihs.getHostName(hostMor));
         hostMemberList[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
         hostMemberList[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
         hostMemberList[i].setHost(hostMor);
         hostMemberList[i].setMaxProxySwitchPorts(MAX_PORTS);
         DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
         DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
         pnicSpec.setPnicDevice(freePnics[0]);
         pnicBacking.getPnicSpec().clear();
         pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
         hostMemberList[i].setBacking(pnicBacking);
      }

      /*
       * Create DVS Switch for all hosts in inventory.
       */
      DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(this.getTestId());
      dvsConfigSpec.setNumStandalonePorts(1);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostMemberList));
      String[] uplinkPortNames = new String[] { "Uplink1" };
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
      dvsConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
      this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
               this.iFolder.getNetworkFolder(this.iFolder.getDataCenter()),
               dvsConfigSpec);

      assertTrue(this.dvsMor != null
               && this.iDVS.validateDVSConfigSpec(this.dvsMor, dvsConfigSpec,
                        null), "Created DVS Switch",
               "Failed to Create DVS Switch");

      DVSConfigInfo configInfo = this.iDVS.getConfig(this.dvsMor);
      dvSwitchUUID = configInfo.getUuid();

      for (ManagedObjectReference hostMor : allHosts) {
         String hostName = ihs.getHostName(hostMor);
         this.nwSystemMor = this.ins.getNetworkSystem(hostMor);
         Assert.assertNotNull(this.nwSystemMor,
                  "NetworkSystem couldn't be retrieved for " + hostName);
         log.info("Refreshing the network state for " + hostName);
         this.ins.refresh(this.nwSystemMor);
         Thread.sleep(3000);
      }

   }

   private void addDVSPortGroup()
      throws Exception
   {

      /*
       * Add DVS Virtual Port Group
       */
      int noOfEthernetCards = 0;
      for (ManagedObjectReference vmMor : ivm.getAllVM()) {
         List<VirtualDeviceConfigSpec> vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                  vmMor, connectAnchor);
         noOfEthernetCards += vdConfigSpec.size();
      }
      DVPortgroupConfigSpec pgConfigSpec = new DVPortgroupConfigSpec();
      pgConfigSpec.setNumPorts(noOfEthernetCards);
      pgConfigSpec.setType(DVPORTGROUP_TYPE_LATE_BINDING);
      pgConfigSpec.setName(this.getTestId() + "-epg");
      pgConfigSpec.setConfigVersion("");
      List<ManagedObjectReference> pgMors = this.iDVS.addPortGroups(
               this.dvsMor, new DVPortgroupConfigSpec[] { pgConfigSpec });

      assertTrue(pgMors != null && pgMors.size() == 1,
               "Failed to add DVS Port Group");
      pgMor = pgMors.get(0);
      Assert.assertNotNull(pgMor, "Failed to add Port Group");

   }

   private void reconfigureVmToDVSPortGroup(ManagedObjectReference vmMor)
      throws Exception
   {
      String vmName = ivm.getName(vmMor);
      log.info("VM : " + vmName);
      String portgroupKey = this.iDVPortgroup.getKey(pgMor);
      List<DistributedVirtualSwitchPortConnection> ports = new ArrayList<DistributedVirtualSwitchPortConnection>();

      List<VirtualDeviceConfigSpec> vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
               vmMor, connectAnchor);
      int noOfEthernetCards = vdConfigSpec.size();
      for (int j = 0; j < noOfEthernetCards; j++) {
         DistributedVirtualSwitchPortConnection portConnection = new DistributedVirtualSwitchPortConnection();
         portConnection.setPortgroupKey(portgroupKey);
         portConnection.setSwitchUuid(dvSwitchUUID);
         ports.add(portConnection);

      }

      assertTrue(ports.size() > 0, "There are no free "
               + "ports in the late " + "binding portgroup");

      VirtualMachineConfigSpec[] vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
               vmMor,
               connectAnchor,
               ports.toArray(new DistributedVirtualSwitchPortConnection[ports.size()]));

      assertTrue(vmConfigSpec != null && vmConfigSpec.length == 2
               && vmConfigSpec[0] != null && vmConfigSpec[1] != null,
               "There should be two vmConfigSpec");
      this.vmConfigspecMap.put(this.ivm.getName(vmMor), vmConfigSpec[1]);

      assertTrue(this.ivm.reconfigVM(vmMor, vmConfigSpec[0]),
               "Reconfigured " + vmName + " to use DVS Port group",
               "Failed to reconfigure " + vmName + " to use DVS port group");
   }

   /**
    * Method to restore the state of the VC inventory. This restores the network
    * config of the host and deletes the DVS MOR created.
    *
    * @param connectAnchor ConnectAnchor
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
      Vector<ManagedObjectReference> vms = null;


         for (ManagedObjectReference hostMor : allHosts) {
            if (!iTask.monitorTasks(iTask.getActiveTasks(hostMor))) {
               cleanUpDone &= false;
               log.error("Active Tasks failed to complete on "
                        + ihs.getHostName(hostMor));
               vms = ihs.getVMs(hostMor, null);
               /*
                * poweredOff vms
                */
               assertTrue(ivm.setVMsState(vms, VirtualMachinePowerState.POWERED_OFF, false),
                        VM_POWEROFF_PASS, VM_POWEROFF_FAIL);
               /*
                * destroy vms
                */
               assertTrue(this.ivm.destroy(vms), VM_DEL_PASS, VM_DEL_FAIL);
            }
         }

         for (ManagedObjectReference vmMor : ivm.getAllVM()) {
            String vmName = this.ivm.getVMName(vmMor);

            if (!ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
               cleanUpDone &= false;
               log.error("Failed to Power off VM " + vmName);
            }

         }

         if (clusterMor != null) {
            for (ManagedObjectReference hostMor : icr.getHosts(clusterMor)) {
               if (icr.moveHostFromClusterToSAHost(clusterMor, hostMor,
                        iFolder.getHostFolder(dcMor), false)) {
                  log.info("Moved host as Standalone.");
               } else {
                  log.error("Failed to move host as Standalone.");
                  cleanUpDone = false;
               }
            }

            if (!icr.destroy(clusterMor)) {
               log.error("Failed to destroy Cluster");
               cleanUpDone = false;
            }
         }
         if (vmPathMap != null && vmPathMap.size() > 0) {
            for (Map.Entry<String, String> entry : vmPathMap.entrySet()) {
               String vmName = entry.getKey();
               ManagedObjectReference hostMor = this.ihs.getHost(this.vmHostMap.get(vmName));
               assertNotNull(new Folder(connectAnchor).registerVm(
                        this.iFolder.getVMFolder(this.dcMor), entry.getValue(),
                        vmName, false,
                        this.ihs.getResourcePool(hostMor).get(0), hostMor),
                        VM_REGISTER_PASS + vmName, VM_REGISTER_FAIL + vmName);

            }
         }
         if (this.dvsMor != null && cleanUpDone) {
            if (!this.iManagedEntity.destroy(dvsMor)) {
               log.error("Can not destroy the distributed virtual switch "
                        + this.iDVS.getConfig(this.dvsMor).getName());
               cleanUpDone = false;
            }
         }


      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }

   /**
    * Method to create required number of VMs .
    *
    * @param reqVms, required number of VMs to be created.
    * @param hostMor, in which host the VM should be created.
    * @return list of created vms.
    */
   public Vector<ManagedObjectReference> createVms(int reqVms,
                                                   ManagedObjectReference hostMor)
      throws Exception
   {
      DatastoreInformation datastoreInfo;
      String hostName = null;
      Vector<ManagedObjectReference> createdVms = new Vector<ManagedObjectReference>(
               reqVms);
      /*
       * Create a new VM
       */
      ManagedObjectReference vm = null;
      datastoreInfo = icluster.getCommonDatastore(TestUtil.vectorToArray(allHosts));
      assertNotNull(datastoreInfo,
               "Found datastore " + datastoreInfo.getName(),
               "Datastore Information is null");
      hostName = ihs.getHostName(hostMor);
      for (int i = 0; i < reqVms; i++) {
         vm = iss.createVirtualMachine(ihs, hostMor, ivm, "VM-" + i + "-"
                  + hostName, datastoreInfo);
         createdVms.add(vm);
      }
      return createdVms;
   }
}