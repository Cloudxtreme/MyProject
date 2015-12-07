package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

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
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;


/**
 * Clone a vm from one opaque network on one host to another within the same
 * datacenter
 *
 * @author sabesanp
 *
 */

public class T14On extends TestBase
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
   private List<HostOpaqueNetworkInfo> opaqueNetworkInfo;
private VirtualMachineConfigSpec origVMConfigSpec;

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
                        DVSUtil.startNsxa(connectAnchor, "root", "ca$hc0w", "vmnic1");
                        DVSUtil.testbedSetup(connectAnchor);
                } catch (Throwable e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                        return false;
                }

      //destroyVds();
      List<String> esxIpList = new ArrayList<String>();
      esxIpList.add("10.135.14.210");
      esxIpList.add("10.135.14.231");
      //addHost("10.115.174.136", esxIpList, 443);
      //addHost("10.115.174.167", esxIpList, 443);
      this.hostMor = hostSystem.getAllHost().get(0);
      this.destHostMor = hostSystem.getAllHost().get(1);
      //unregisterVms();
      //registerVm();
      nsMor = nwSystem.getNetworkSystem(hostMor);
      opaqueNetworkInfo = nwSystem.
                                getNetworkInfo(nsMor).getOpaqueNetwork();
      assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                         "The list of opaque networks is not null",
                         "The list of opaque networks is null");
      this.vmMor = hostSystem.getVMs(this.hostMor,
                      VirtualMachinePowerState.POWERED_OFF).get(0);


                /*
                 * Power on the vm
                 */
                assertTrue(vm.setVMState(vmMor,
                                  VirtualMachinePowerState.POWERED_ON,
                                  false),"Successfully powered on the virtual machine",
                                   "Failed to power on the virtual machine");


      Map<String,String> vmEthernetMap = NetworkUtil.
                                getEthernetCardNetworkMap(vmMor, connectAnchor);
      Set<String> ethernetCardDevicesSet = vmEthernetMap.keySet();
      /*
       * Compute a new ethernet card network map
       */
      Map<String,HostOpaqueNetworkInfo> ethernetCardNetworkMap = new
                      HashMap<String,HostOpaqueNetworkInfo>();
      for(String ethernetCard : ethernetCardDevicesSet){
                        ethernetCardNetworkMap.put(ethernetCard, opaqueNetworkInfo.get(0));
      }

      /*
       * Reconfigure the virtual machine to connect to opaque network
       */
      this.origVMConfigSpec = NetworkUtil.
                                               reconfigureVMConnectToOpaqueNetwork(vmMor,
                                               ethernetCardNetworkMap, connectAnchor);

      this.dsMor = this.storageHelper.getVMConfigDatastore(vmMor);
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
      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      /*
       * Generate the vm relocate spec to connect to the destination dvport
       */
      VirtualMachineRelocateSpec relocateSpec = new
               VirtualMachineRelocateSpec();
      relocateSpec.setFolder(this.folder.getVMFolder(dcMor));
      relocateSpec.setHost(this.destHostMor);
      relocateSpec.setPool(hostSystem.getResourcePool(this.destHostMor).get(0));
      relocateSpec.setDatastore(this.dsMor);
      VirtualMachineCloneSpec cloneSpec = new VirtualMachineCloneSpec();
      cloneSpec.setLocation(relocateSpec);
      cloneSpec.setPowerOn(true);
      this.cloneVmMor = vm.cloneVM(vmMor,folder.getVMFolder(dcMor),
                                   "Clone-S011-VM", cloneSpec);
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
         System.out.println("\n ####### network_id = " + network_id);
         System.out.println("\n ####### getOpaqueNetworkId = " +
         opaqueNetworkInfo.get(0).getOpaqueNetworkId());
         /*assertTrue(network_id.equals(opaqueNetworkInfo.get(0).
                            getOpaqueNetworkId()),"The cloned vm is connecting to " +
                            "the opaque network","The cloned vm is not connecting " +
                            "to the opaque network");*/
      }
   }

   public void deselectVnic() throws Exception {
              VmotionSystem vmotionSystem = new VmotionSystem(connectAnchor);
              ManagedObjectReference vmotionMor = vmotionSystem.
                      getVMotionSystem(hostMor);
              HostVirtualNic vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
                       hostMor);
              vmotionSystem.deselectVnic(vmotionMor);
              vmotionMor = vmotionSystem.
                      getVMotionSystem(destHostMor);
              vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
                      destHostMor);
              vmotionSystem.deselectVnic(vmotionMor);
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
           boolean cleanupWorked = true;
           try {
              if (vmMor != null) {
                  if (vm.getVMState(vmMor).
                          equals(VirtualMachinePowerState.POWERED_ON)) {
                          assertTrue(vm.setVMState(vmMor,
                                  VirtualMachinePowerState.POWERED_OFF,
                                  true),"Successfully powered off the vm",
                                  "Failed to power off the vm");
                  }
                  /*
                   * Restore the vm configuration
                   */
                  if (origVMConfigSpec != null) {
                      assertTrue(vm.reconfigVM(vmMor, origVMConfigSpec),
                              "Reconfigured the vm to its original settings",
                              "Failed to reconfigure the vm to its original settings");
                  }
              }
              if (cloneVmMor != null) {
                      if (vm.getVMState(cloneVmMor).
                              equals(VirtualMachinePowerState.POWERED_ON)) {
                          assertTrue(vm.setVMState(cloneVmMor,
                                  VirtualMachinePowerState.POWERED_OFF,
                                   true),"Successfully powered off the vm",
                                   "Failed to power off the vm");
                      }
                  dvs.destroy(cloneVmMor);
              }
              deselectVnic();
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
