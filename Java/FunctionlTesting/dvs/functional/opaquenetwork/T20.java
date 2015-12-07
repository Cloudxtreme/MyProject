package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceBackingInfo;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VmHelper;
import com.vmware.vcqa.vim.ComputeResource;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;


/**
 * Clone a vm from one vswitch pg to opaque network
 *
 * @author sabesanp
 *
 */

public class T20 extends TestBase
{

   private Folder folder = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference srcVdsMor = null;
   private ManagedObjectReference destVdsMor = null;
   private DistributedVirtualSwitch dvs = null;
   private HostSystem hostSystem = null;
   private VmHelper vmHelper = null;
   private Datacenter dc = null;
   private List<ManagedObjectReference> hostMorList = null;
   private ComputeResource compResource = null;
   private VirtualMachine vm = null;
   private ManagedObjectReference vmMor = null;
   private DistributedVirtualPortgroup dvpg = null;
   private ManagedObjectReference dvpgMor = null;
   private List<ManagedObjectReference> vmMorList = null;
   private NetworkSystem nwSystem = null;
   private ManagedObjectReference nsMor = null;
   private ManagedObjectReference hostMor = null;
   private DatastoreSystem dataStoreSystem = null;
   private ManagedObjectReference datastoreSystemMor = null;
   private VirtualMachineConfigSpec reconfigVmSpec = null;
   private String[] dvportKey = null;
   private String[] destDvPortKey = null;
   private ManagedObjectReference dsMor = null;
   private ProvisioningOpsStorageHelper storageHelper = null;
   private ManagedObjectReference destHostMor = null;
   private ManagedObjectReference cloneVmMor = null;
   private ManagedObjectReference destdcMor = null;
   private String srcPgKey;
   private DistributedVirtualSwitch destDvs;
   private String destPgKey;
   private HashMap<String, String> ethDestMap;
   private List<String> esxIpList;
   private ManagedObjectReference srcnsmor;
   private List<HostOpaqueNetworkInfo> opaqueNetworkInfo;

   public void initialize()
      throws Exception
   {
      folder = new Folder(connectAnchor);
      dvs = new DistributedVirtualSwitch(connectAnchor);
      hostSystem = new HostSystem(connectAnchor);
      vmHelper = new VmHelper(connectAnchor);
      dc = new Datacenter(connectAnchor);
      compResource = new ComputeResource(connectAnchor);
      vm = new VirtualMachine(connectAnchor);
      dvpg = new DistributedVirtualPortgroup(connectAnchor);
      nwSystem = new NetworkSystem(connectAnchor);
      dataStoreSystem = new DatastoreSystem(connectAnchor);
      this.dcMor = folder.getDataCenter();
      if (dcMor == null) {
         dcMor = folder.createDatacenter(folder.getRootFolder(), "dc");
      }
      assertNotNull(dcMor, "Found a valid datacenter in the inventory",
                    "Failed to find a datacenter in the inventory");
      storageHelper = new ProvisioningOpsStorageHelper(connectAnchor);
   }

   public void cleanUpRelocate()
            throws Exception
   {
      cleanupVm();
      VirtualMachineRelocateSpec cleanupSpec = new VirtualMachineRelocateSpec();
      cleanupSpec.setHost(hostMor);
      cleanupSpec.setPool(hostSystem.getResourcePool(this.hostMor).get(0));
      vm.relocateVM(vmMor, cleanupSpec,
               VirtualMachineMovePriority.DEFAULT_PRIORITY);
   }

   public void cleanupVm()
      throws Exception{
      Map<String,String> ethernetCardNetworkMap = NetworkUtil.
               getEthernetCardNetworkMap(vmMor, connectAnchor);
      for(String deviceLabel : ethernetCardNetworkMap.keySet()){
         ethernetCardNetworkMap.put(deviceLabel, "VM Network");
      }
      NetworkUtil.reconfigureVMConnectToPortgroup(vmMor,
                           connectAnchor, ethernetCardNetworkMap);
   }

   public void registerVm()
            throws Exception{
      //hostMorList = hostSystem.getAllHost();
      //hostMor = hostMorList.get(0);
      int count =1;
      this.datastoreSystemMor  = dataStoreSystem.getDatastoreSystem(
               this.hostMor);
      /*
      ManagedObjectReference datastoreMor = dataStoreSystem.
               addNasVol("fvt-1", "10.115.160.201", "nfs-network",
                        this.datastoreSystemMor);*/
      vmMor = vmHelper.registerVmFromDatastore("rhel-netioc-ngo-2",
                                               "nfs-network",hostMor);
      log.info("rhel-netioc-vm-2 registered on host : " +
               hostSystem.getHostName(hostMor));
   }

   public void unregisterVms()
      throws Exception
   {
      List<ManagedObjectReference> vmMorList = vm.getAllVM();
      if(vmMorList != null && vmMorList.size() >= 1){
         for(ManagedObjectReference vm_Mor : vmMorList){
            assertTrue(vm.setVMState(vm_Mor,
                       VirtualMachinePowerState.POWERED_OFF,
                       false),"Successfully powered off the virtual machine",
                       "Failed to power off the virtual machine");
            assertTrue(vm.unregisterVM(vm_Mor),"Successfully unregistered vm : "
                       + vm_Mor,"Failed to unregister vm : " + vm_Mor);
         }
      }
   }



   public void destroyVds()
      throws Exception
   {
      dcMor = folder.getDataCenter();
      if(dcMor != null){
         List<ManagedObjectReference> vdsMorList = folder.
                  getAllDistributedVirtualSwitch(folder.
                                                 getNetworkFolder(dcMor));
         List<ManagedObjectReference> vmList = vm.getAllVM();
         if(vdsMorList != null){
            for(ManagedObjectReference m : vdsMorList){
               dvs.destroy(m);
            }
         }
      }
   }

   public void addHost(String vcip,
                       List<String> esxipList,
                       int port)
      throws Exception
   {
      /*
       * Create datacenter
       */
      //dcMor = folder.getDataCenter();
      if (dcMor == null) {
         // dvs.destroy(dcMor);
         dcMor = folder.createDatacenter(folder.getRootFolder(), "dc");
      }
      HostConnectSpec hostConnectSpec = null;
      for(String esxip : esxipList){
         ManagedObjectReference hostMor =
               hostSystem.addStandaloneHost(dc.getHostFolder(dcMor),
                     hostSystem.createHostConnectSpec(esxip, true) ,
                     null, true);
         if(hostMor != null){
            System.out.println("The host : " + esxip +
                  "was successfully added");
            }
      }
      hostMor = hostSystem.getConnectedHost(false);
      //log.info("The host size : " + hostMorList.size());
      /*List<ManagedObjectReference> vmMorList = hostSystem.
              getAllVirtualMachine(hostMor);
      if (vmMorList != null && vmMorList.size() >= 1) {
         for (ManagedObjectReference vmMor : vmMorList) {
            vm.destroy(vmMor);
         }
      }
      List<ManagedObjectReference> vdsList = folder.
               getAllDistributedVirtualSwitch(folder.getNetworkFolder(dcMor));
      if (vdsList != null && vdsList.size() >= 1) {
         dvs.destroy(srcVdsMor);
      }*/
   }

   public void removeHostFromDc()
      throws Exception
   {
      hostSystem.destroy(this.destHostMor);
   }

   public void addHostToDestinationDc(String esxip,
                                      ManagedObjectReference dc_mor)
      throws Exception
   {
      this.destHostMor = hostSystem.addStandaloneHost(dc.getHostFolder(dc_mor),
               hostSystem.createHostConnectSpec(esxip, true), null, true);
   }

   public void addPortgroups()
       throws Exception
    {
        this.srcPgKey = dvs.addPortGroup(srcVdsMor,
            DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING, 2,
            "src_pg_1");
        this.destPgKey = dvs.addPortGroup(destVdsMor,
             DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING, 2,
             "dest_pg_1");
    }

   @BeforeMethod
   public boolean testSetUp()
      throws Exception
   {
      /*
       * Create datacenter
       */
      initialize();
                try {
                        DVSUtil.startNsxa(connectAnchor, "root", "ca$hc0w", "vmnic3");
                        DVSUtil.testbedSetup(connectAnchor);
                } catch (Throwable e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                        return false;
                }


      this.hostMor = hostSystem.getAllHost().get(0);
      this.destHostMor = hostSystem.getAllHost().get(1);
          srcnsmor = nwSystem.getNetworkSystem(hostMor);
      opaqueNetworkInfo = nwSystem.
                                getNetworkInfo(srcnsmor).getOpaqueNetwork();
      assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                         "The list of opaque networks is not null",
                         "The list of opaque networks is null");

      //destroyVds();
      //addHost("10.115.174.136", esxIpList, 443);
      //addHost("10.115.174.167", esxIpList, 443);
      esxIpList = new ArrayList<String>();
      esxIpList.add(hostSystem.getIPAddress(hostMor));
      esxIpList.add(hostSystem.getIPAddress(destHostMor));
      //unregisterVms();
      //registerVm();
      this.vmMor = hostSystem.getVMs(this.hostMor,
                      VirtualMachinePowerState.POWERED_OFF).get(0);
      this.dsMor = this.storageHelper.getAllOtherDatastores(vmMor, false).
                   get(0);
      /*
       * Enable vmotion on both the host vnics
       */

      VmotionSystem vmotionSystem = new VmotionSystem(connectAnchor);
      ManagedObjectReference vmotionMor = vmotionSystem.
               getVMotionSystem(hostMor);
      HostVirtualNic vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
               hostMor);
      if(vNic == null){
         HostVirtualNic origVnic = nwSystem.getVirtualNic(nwSystem.
                  getNetworkSystem(hostMor), "Management Network", true);
         vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
      }
      vmotionMor = vmotionSystem.getVMotionSystem(destHostMor);
      vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
               this.destHostMor);
      if(vNic == null){
         HostVirtualNic origVnic = nwSystem.getVirtualNic(nwSystem.
                  getNetworkSystem(this.destHostMor), "Management Network",
                                   true);
         vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
      }
      //cleanupVm();
      destroyVds();
      destdcMor = folder.getDataCenter("dest_dc");
      if(destdcMor == null) {
         destdcMor = folder.createDatacenter(folder.getRootFolder(),
                                             "dest_dc");
      }
      removeHostFromDc();
      addHostToDestinationDc(esxIpList.get(1),this.destdcMor);
      this.dsMor = this.storageHelper.getHostDatastores(destHostMor, "NFS",
                   false).get(0);
      /*
       * Get all vms in the inventory and pick one of them
       */
      //List<ManagedObjectReference> vmMorList = vm.getAllVM();

      //assertTrue(vmMorList != null && vmMorList.size() >=1,"There is " +
            //"atleast one virtual machine in the inventory","There are no " +
            //"virtual machines in the inventory");
      assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON,
                 false),"Successfully powered on the vm","Failed to power on " +
                 "the vm");
      return true;
   }

   public void reconfigureVMConnectToVdsPortgroup()
       throws Exception
    {
        DistributedVirtualSwitchPortConnection[] portConnection = new
            DistributedVirtualSwitchPortConnection[2];
        for(int i=0;i<2;i++){
           portConnection[i] = new DistributedVirtualSwitchPortConnection();
           portConnection[i].setSwitchUuid(dvs.getConfig(srcVdsMor).getUuid());
        }
        Map<String, Map<String, Boolean>> ethernetCardMap = new
            HashMap<String,Map<String,Boolean>>();
        Map<String,String> ethMap = NetworkUtil.getEthernetCardNetworkMap(vmMor,
            connectAnchor);
        int i=0;
        for(String dev : ethMap.keySet()){
            Map<String,Boolean> portBoolMap = new HashMap<String, Boolean>();
            portBoolMap.put(this.srcPgKey, true);
            ethernetCardMap.put(dev, portBoolMap);
            i++;
        }
        this.reconfigVmSpec = DVSUtil.reconfigureVMConnectToVdsPort(vmMor,
            connectAnchor,ethernetCardMap,dvs.getConfig(srcVdsMor).
            getUuid());
    }

   public List<VirtualDeviceConfigSpec> generateEthernetDeviceChange()
       throws Exception
   {
       List<VirtualDeviceConfigSpec> ethernetCardList = DVSUtil.
           getAllVirtualEthernetCardDevices(vmMor, connectAnchor);
       assertNotNull(ethernetCardList,"Successfully found ethernet cards on " +
           "the vm","Failed to find ethernet cards on the vm");
       ethDestMap = new HashMap<String,String>();
       int i=0;
       for(VirtualDeviceConfigSpec spec : ethernetCardList){
           VirtualDevice vd = spec.getDevice();
           if(vd.getBacking() instanceof
               VirtualEthernetCardDistributedVirtualPortBackingInfo){
               VirtualEthernetCardDistributedVirtualPortBackingInfo backInfo =
                   new
                   VirtualEthernetCardDistributedVirtualPortBackingInfo();
               DistributedVirtualSwitchPortConnection portConn = new
                   DistributedVirtualSwitchPortConnection();
               portConn.setPortgroupKey(destPgKey);
               portConn.setSwitchUuid(dvs.getConfig(destVdsMor).getUuid());
               backInfo.setPort(portConn);
               vd.setBacking(backInfo);
               ethDestMap.put(vd.getDeviceInfo().getLabel(),
                   this.destPgKey);
               spec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
               i++;
           }
       }
       return ethernetCardList;
   }

   @Test
   public void test()
      throws Exception
   {
      Integer deviceKey = null;
      /*
       * Generate the vm relocate spec to connect to the opaque network
       */
      VirtualMachineRelocateSpec relocateSpec = new
          VirtualMachineRelocateSpec();
        List<VirtualDeviceConfigSpec> ethernetCardList = DVSUtil.
            getAllVirtualEthernetCardDevices(vmMor, connectAnchor);
        assertNotNull(
            ethernetCardList,
            "Successfully found ethernet cards on " + "the vm",
            "Failed to find ethernet cards on the vm");
        Map<String, String> ethDestMap = new HashMap<String, String>();
        int i = 0;
        for (VirtualDeviceConfigSpec spec : ethernetCardList) {
            VirtualDevice vd = spec.getDevice();
            if (vd.getBacking() instanceof VirtualEthernetCardNetworkBackingInfo) {
                VirtualEthernetCardNetworkBackingInfo backInfo = new
                    VirtualEthernetCardNetworkBackingInfo();
                ethDestMap.put(vd.getDeviceInfo().getLabel(), "VM Network");
                backInfo.setDeviceName(opaqueNetworkInfo.
                                get(0).getOpaqueNetworkId());
                VirtualEthernetCardOpaqueNetworkBackingInfo opaqueNetworkBacking =
                                new VirtualEthernetCardOpaqueNetworkBackingInfo();
                opaqueNetworkBacking.setOpaqueNetworkId(opaqueNetworkInfo.
                                get(0).getOpaqueNetworkId());
                opaqueNetworkBacking.setOpaqueNetworkType(opaqueNetworkInfo.
                                get(0).getOpaqueNetworkType());
                vd.setBacking(opaqueNetworkBacking);
                spec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
                i++;
            }
        }
      relocateSpec.setDeviceChange(ethernetCardList);
      relocateSpec.setFolder(this.folder.getVMFolder(this.destdcMor));
      relocateSpec.setHost(this.destHostMor);
      relocateSpec.setPool(hostSystem.getResourcePool(this.destHostMor).get(0));
      relocateSpec.setDatastore(this.dsMor);
      VirtualMachineCloneSpec cloneSpec = new VirtualMachineCloneSpec();
      cloneSpec.setLocation(relocateSpec);
      cloneSpec.setPowerOn(true);
      this.cloneVmMor = vm.cloneVM(vmMor,folder.getVMFolder(this.destdcMor),
                                   "Clone-P019-VM", cloneSpec);
          assertTrue(vm.getIPAddress(cloneVmMor) != null, "vm ip is not null", "vm ip is null");
      assertTrue(DVSUtil.checkNetworkConnectivity(
                 hostSystem.getIPAddress(hostMor),
                 vm.getIPAddress(cloneVmMor),null),
                 "VM is accessible on the network",
                 "VM is not accessible on the network");
      /*
       * Verify that the vm's ethernet card is connected to the opaque network
       */
      Map<String,String> vm_ethernet_map = NetworkUtil.
                      getEthernetCardNetworkMap(cloneVmMor, connectAnchor);
      for(String ethernet_card : vm_ethernet_map.keySet()){
         String network_id = vm_ethernet_map.get(ethernet_card);
         assertTrue(network_id.equals(opaqueNetworkInfo.get(0).
                            getOpaqueNetworkId()),"The cloned vm is connecting to " +
                            "the opaque network","The cloned vm is not connecting " +
                            "to the opaque network");
      }
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
                boolean cleanupWorked = true;
                try {
                  assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
                           true),"Successfully powered off the vm","Failed to power off " +
                           "the vm");
                  assertTrue(vm.setVMState(cloneVmMor, VirtualMachinePowerState.POWERED_OFF,
                           true),"Successfully powered off the vm","Failed to power off " +
                           "the vm");
                  cleanUpRelocate();
                  dvs.destroy(cloneVmMor);
                  removeHostFromDc();
                  addHostToDestinationDc(esxIpList.get(1), this.dcMor);
                  dvs.destroy(destdcMor);
                } catch (Throwable t) {
                        t.printStackTrace();
                        cleanupWorked = false;
                        DVSUtil.testbedTeardown(connectAnchor, true);
                }
                try {
                        DVSUtil.testbedTeardown(connectAnchor);
                } catch (Throwable e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                        cleanupWorked = false;
                }

                try {
                        DVSUtil.stopNsxa(connectAnchor, "root", "ca$hc0w");
                } catch (Throwable e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                        cleanupWorked = false;
                }
                assertTrue(cleanupWorked, "Cleanup Succeeded !", "Cleanup Failed !");
                return true;
   }
}
