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

import com.vmware.vc.CannotAccessNetwork;
import com.vmware.vc.CannotUseNetwork;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMotionAcrossNetworkNotSupported;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.NetworkUtil;
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
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;

import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vc.HostVirtualNic;

/**
 * Move the vm from one dvportgroup to an opaque network
 *
 * @author sabesanp
 *
 */

public class T19 extends TestBase
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
   private ManagedObjectReference srcnsmor;
   private ManagedObjectReference destnsmor;
   private List<HostOpaqueNetworkInfo> opaqueNetworkInfo;
   private List<ManagedObjectReference> dvpgmorlist;
private String dvpgkey;

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
               this.destHostMor);
      ManagedObjectReference datastoreMor = dataStoreSystem.
               addNasVol("fvt-1", "10.115.160.201", "nfs-network",
                        this.datastoreSystemMor);
      /*vmMor = vmHelper.registerVmFromDatastore("rhel-netioc-vm-2",
                                               "nfs-network",hostMor);
      log.info("rhel-netioc-vm-2 registered on host : " +
               hostSystem.getHostName(hostMor));*/
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
      //unregisterVms();
      //destroyVds();
      List<String> esxIpList = new ArrayList<String>();
      esxIpList.add("10.115.174.131");
      esxIpList.add("10.115.174.132");
      //addHost("10.115.174.251", esxIpList, 443);
      //addHost("10.115.174.167", esxIpList, 443);
      /*
       * TODO : Fill in the host details here
       */
      this.hostMor = hostSystem.getAllHost().get(0);
      this.destHostMor = hostSystem.getAllHost().get(1);
      this.vmMor = hostSystem.getVMs
                      (hostMor, VirtualMachinePowerState.POWERED_OFF).get(0);
      this.dsMor = this.storageHelper.getVMConfigDatastore(vmMor);
      //registerVm();
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
      /*
       * Create vds version 6.0.0
       */
      DVSConfigSpec vdsConfigSpec = new DVSConfigSpec();
      vdsConfigSpec.setName("CV_S001_srcVds");
      vdsConfigSpec.setNumStandalonePorts(10);
      srcVdsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), vdsConfigSpec);
      assertNotNull(srcVdsMor,"Successfully created the source vds",
                    "Failed to create the source vds");
      vdsConfigSpec.setName("CV_S001_destVds");
      destVdsMor = folder.createDistributedVirtualSwitch(
               folder.getNetworkFolder(dcMor), vdsConfigSpec);
      assertNotNull(destVdsMor,"Successfully created the destination vds",
                    "Failed to create the destination vds");
      srcnsmor = nwSystem.getNetworkSystem(hostMor);
      destnsmor = nwSystem.getNetworkSystem(destHostMor);
      /*
       * Get all vms in the inventory and pick one of them
       */
      //List<ManagedObjectReference> vmMorList = vm.getAllVM();

      //assertTrue(vmMorList != null && vmMorList.size() >=1,"There is " +
              //"atleast one virtual machine in the inventory","There are no " +
              //"virtual machines in the inventory");
      opaqueNetworkInfo = nwSystem.
                                getNetworkInfo(srcnsmor).getOpaqueNetwork();
      assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                         "The list of opaque networks is not null",
                         "The list of opaque networks is null");
      /*
       * Add a host to vds
       */
      List<ManagedObjectReference> dvsMorList = new
               ArrayList<ManagedObjectReference>();
      dvsMorList.add(srcVdsMor);
      //dvsMorList.add(destVdsMor);
      assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor, hostMor,
                 dvsMorList),"Successfully added the host to both the " +
                 "source and destination vdses","Failed to add the host " +
                 "to both the source and the destination vds");
      dvsMorList = new ArrayList<ManagedObjectReference>();
      dvsMorList.add(destVdsMor);
      assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor,
               this.destHostMor,dvsMorList),
               "Successfully added the host to " +
               "both the source and destination vdses",
               "Failed to add the " +
               "host to both the source and the destination vds");
      /*
       * Get the number of ethernet card devices on the vm
       */
      int numCards = DVSUtil.getAllVirtualEthernetCardDevices(vmMor,
                     connectAnchor).size();
      this.dvportKey = new String[numCards];
      //this.dvportKeyArray = new String[numCards];
      /*
       * Reconfigure the virtual machine to connect to a dvportgroup
       */
      DVPortgroupConfigSpec dvpgconfigspec = new DVPortgroupConfigSpec();
      dvpgconfigspec.setName("dvpg-1");
      dvpgconfigspec.setNumPorts(10);
      dvpgconfigspec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvpgmorlist = dvs.addPortGroups(srcVdsMor,
                                new DVPortgroupConfigSpec[]{dvpgconfigspec});
      dvpgkey = dvpg.getConfigInfo(dvpgmorlist.get(0)).getKey();
      DistributedVirtualSwitchPortConnection[] portConnection = new
               DistributedVirtualSwitchPortConnection[numCards];
      for(int i=0;i<numCards;i++){
         portConnection[i] = new DistributedVirtualSwitchPortConnection();
         portConnection[i].setSwitchUuid(dvs.getConfig(srcVdsMor).getUuid());
      }
      this.dvportKey[0] = dvs.getFreeStandaloneDVPortKey(srcVdsMor,null);
      portConnection[0].setPortKey(this.dvportKey[0]);
      HashMap<String, List<String>> excludedPorts = new HashMap<String,
               List<String>>();
      ArrayList<String> listExcludedPorts = new ArrayList<String>();
      listExcludedPorts.add(this.dvportKey[0]);
      excludedPorts.put(null, listExcludedPorts);
      //this.dvportKey[1] = dvs.getFreeStandaloneDVPortKey(srcVdsMor,
      //         excludedPorts);
      //portConnection[1].setPortKey(this.dvportKey[1]);
      Map<String, Map<String, Boolean>> ethernetCardMap = new
               HashMap<String,Map<String,Boolean>>();
      Map<String,String> ethMap = NetworkUtil.getEthernetCardNetworkMap(vmMor,
               connectAnchor);
      int i=0;
      for(String dev : ethMap.keySet()){
         Map<String,Boolean> portBoolMap = new HashMap<String, Boolean>();
         portBoolMap.put(this.dvpgkey, true);
         ethernetCardMap.put(dev, portBoolMap);
         i++;
      }
      this.reconfigVmSpec = DVSUtil.reconfigureVMConnectToVdsPort(vmMor,
               connectAnchor,ethernetCardMap,dvs.getConfig(srcVdsMor).
               getUuid());
      assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON,
                 true),"Successfully powered on the vm","Failed to power on " +
                 "the vm");
      return true;
   }

   @Test
   public void test()
      throws Exception
   {
      Integer deviceKey = null;
      this.destDvPortKey = new String[1];
      this.destDvPortKey[0] = dvs.getFreeStandaloneDVPortKey(destVdsMor, null);
      HashMap<String,List<String>> excludedPorts = new
               HashMap<String,List<String>>();
      ArrayList<String> excludedPortsList = new ArrayList<String>();
      excludedPortsList.add(this.destDvPortKey[0]);
      excludedPorts.put(null,excludedPortsList);
      //this.destDvPortKey[1] = dvs.getFreeStandaloneDVPortKey(destVdsMor,
      //         excludedPorts);
      /*
       * Generate the vm relocate spec to connect to the destination dvport
       */
      VirtualMachineRelocateSpec relocateSpec = new
               VirtualMachineRelocateSpec();
      List<VirtualDeviceConfigSpec> ethernetCardList = DVSUtil.
              getAllVirtualEthernetCardDevices(vmMor, connectAnchor);
     assertNotNull(ethernetCardList,"Successfully found ethernet cards on " +
             "the vm","Failed to find ethernet cards on the vm");
     Map<String,String> ethDestMap = new HashMap<String,String>();
     int i=0;
     for(VirtualDeviceConfigSpec spec : ethernetCardList){
        VirtualDevice vd = spec.getDevice();
        VirtualEthernetCardOpaqueNetworkBackingInfo opaqueNetworkBackingInfo
        = NetworkUtil.createOpaqueNetworkBackingInfo(
                opaqueNetworkInfo.get(0).getOpaqueNetworkId(),
                opaqueNetworkInfo.get(0).getOpaqueNetworkType());
        vd.setBacking(opaqueNetworkBackingInfo);
        if (vd.getConnectable() != null) {
           vd.getConnectable().setStartConnected(true);
        }
        spec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
     }
      relocateSpec.setDeviceChange(ethernetCardList);
      relocateSpec.setFolder(this.folder.getVMFolder(dcMor));
      relocateSpec.setHost(this.destHostMor);
      relocateSpec.setPool(hostSystem.getResourcePool(this.destHostMor).
                           get(0));
      relocateSpec.setDatastore(this.dsMor);
      try{
          vm.relocateVM(vmMor, relocateSpec,
                     VirtualMachineMovePriority.DEFAULT_PRIORITY);
          throw new Exception("Relocation of vm to host without " +
                          "opaque network passed but it should have failed");
       }catch(Exception excep){
           com.vmware.vc.MethodFault actualMethodFault =
               com.vmware.vcqa.util.TestUtil.getFault(excep);
           com.vmware.vc.MethodFault expectedMethodFault = new
                           CannotUseNetwork();
           com.vmware.vcqa.util.Assert.assertTrue(
                        com.vmware.vcqa.util.TestUtil.checkMethodFault(
                        actualMethodFault, expectedMethodFault),
                        "MethodFault mismatch!");
       }
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
          boolean cleanupWorked = true;
          try {
                  if (vmMor != null) {
                          if (vm.getVMState(vmMor).equals(VirtualMachinePowerState.POWERED_ON)) {
                              assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
                                       true),"Successfully powered off the vm","Failed to power off " +
                                       "the vm");
                              cleanUpRelocate();
                          }
                  }
                  if (srcVdsMor != null) {
                          dvs.destroy(srcVdsMor);
                  }
                  if (destVdsMor != null) {
                          dvs.destroy(destVdsMor);
                  }
      // dvs.destroy(dcMor);
          } catch (Throwable t) {
                  t.printStackTrace();
                  cleanupWorked = false;
              cleanUpRelocate();
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

