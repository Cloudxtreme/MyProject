package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ClusterConfigSpec;
import com.vmware.vc.ClusterDrsConfigInfo;
import com.vmware.vc.ClusterRuleSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.TaskInfo;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualDeviceConnectInfo;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.LogUtil;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.VmHelper;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.ComputeResource;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.Datastore;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.Task;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.cluster.EvcHelper;
import com.vmware.vcqa.vim.cluster.TransitionalEVCManager;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreInformation;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;
import com.vmware.vcqa.vim.xvcprovisioning.XvcProvisioningHelper;


/**
 * Move the vm connected to an opaque network across
 * across hosts connected to different VCs
 *
 */

public class T16XVC extends TestBase {

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
    private XvcProvisioningHelper xvcProvisioningHelper = null;
    private HostSystem destHostSystem = null;
    private Folder destFolder = null;
    private ManagedObjectReference destDcMor = null;
    private DistributedVirtualSwitch destDvs = null;
    private VirtualMachine destVm = null;
    private String vmName = null;
    private ManagedObjectReference destVmMor = null;
    private SessionManager sessionManager = null;
    private ManagedObjectReference sessionMgrMor = null;
    private UserSession vcLoginSession = null;
    private ManagedObjectReference destDsMor = null;
    private DatastoreSystem destDataStoreSystem = null;
    private ManagedObjectReference destDataStoreSystemMor = null;
    private Datastore destDatastore = null;
    private String srcPgKey;
    private String destPgKey;
    private HashMap<String, String> ethDestMap;
        private NetworkSystem ins;
        private List<HostOpaqueNetworkInfo> opaqueNetworkInfo;
        private UserSession hostLoginSession;
        private ManagedObjectReference hostFolderMor;
        private ManagedObjectReference clusterMor;
        private ManagedObjectReference tevcManagerMor;
        private ConnectAnchor destConnectAnchor;
        private NetworkSystem destNwSystem;
        
        private String dest_host_ip;
        private String dest_vc_ip;

    public void initialize() throws Exception {
        /*
         * Set all the source parameters
         * corresponding to connectAnchor
         */
        folder = new Folder(connectAnchor);
        dvs = new DistributedVirtualSwitch(connectAnchor);
        hostSystem = new HostSystem(connectAnchor);
        ins = new NetworkSystem(connectAnchor);
        vmHelper = new VmHelper(connectAnchor);
        dc = new Datacenter(connectAnchor);
        compResource = new ComputeResource(connectAnchor);
        vm = new VirtualMachine(connectAnchor);
        dvpg = new DistributedVirtualPortgroup(connectAnchor);
        nwSystem = new NetworkSystem(connectAnchor);
        dataStoreSystem = new DatastoreSystem(connectAnchor);
        this.dcMor = folder.getDataCenter();
        hostFolderMor = folder.getHostFolder(folder.getDataCenter());
        /*
         * Verify that there is atleast one datacenter in the
         * inventory
         */
        assertNotNull(
            dcMor,
            "Found a valid datacenter in the first vc server",
            "Failed to find a datacenter in the first vc server");
        storageHelper = new ProvisioningOpsStorageHelper(connectAnchor);
        /*
         * Set all the destination parameters
         * corresponding to connectAnchor
         */
                //String dest_host_ip = DVSUtil.getl3HostIP();
                //String dest_vc_ip = DVSUtil.getDestVCIP();
        
        dest_host_ip = "10.24.20.168";
        dest_vc_ip = "10.24.20.164";
        this.destConnectAnchor = new ConnectAnchor(dest_vc_ip, 443);
        this.sessionManager = new SessionManager(this.destConnectAnchor);
        this.sessionMgrMor = this.sessionManager.getSessionManager();
        this.vcLoginSession = this.sessionManager.login(sessionMgrMor, "administrator@vsphere.local", "Admin!23", null);
        this.xvcProvisioningHelper = new XvcProvisioningHelper(connectAnchor, this.destConnectAnchor);
        this.destHostSystem = new HostSystem(this.destConnectAnchor);
        this.destFolder = new Folder(this.destConnectAnchor);
        this.destDcMor = this.destFolder.getDataCenter();
        this.destDvs = new DistributedVirtualSwitch(this.destConnectAnchor);
        this.destDataStoreSystem = new DatastoreSystem(this.destConnectAnchor);
        this.destVm = new VirtualMachine(this.destConnectAnchor);
        this.destDatastore = new Datastore(this.destConnectAnchor);
        this.destNwSystem = new NetworkSystem(this.destConnectAnchor);
    }

    @BeforeMethod
    public boolean testSetUp() throws Exception {
        /*
         * Create datacenter
         */
        initialize();
                try {
                        DVSUtil.testbedSetup(connectAnchor);
                        DVSUtil.startNsxa(connectAnchor, "root", "ca$hc0w", "vmnic2");
                } catch (Throwable e) {
                        e.printStackTrace();
                        return false;
                }
        /*
         * Set all source parameters
         */
        this.hostMor = hostSystem.getAllHost().get(1);
        this.vmMor = hostSystem.getVMs(this.hostMor,
                          VirtualMachinePowerState.POWERED_OFF).get(0);
        this.vmName = this.vm.getVMName(vmMor);
        assertTrue(
            vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, true),
            "Successfully powered off the vm",
            "Failed to power off " + "the vm");
        List<String> esxIpList = new ArrayList<String>();
        esxIpList.add(dest_host_ip);
        this.destHostMor = this.destHostSystem.getAllHost().get(0);
                DVSUtil.startNsxa(destConnectAnchor, "root", "ca$hc0w", "vmnic2");
        this.dsMor = this.storageHelper.getVMConfigDatastore(vmMor);


        hostFolderMor = folder.getHostFolder(folder.getDataCenter());

        /*
         * Get the number of ethernet card devices on the vm
         */
        int numCards = DVSUtil.getAllVirtualEthernetCardDevices(vmMor, connectAnchor).size();
        /*
         * Reconfigure the virtual machine to connect to an opaque network
         */
        nsMor = ins.getNetworkSystem(hostMor);
                opaqueNetworkInfo = ins.getNetworkInfo(nsMor).getOpaqueNetwork();
                assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                          "The list of opaque networks is not null",
                          "The list of opaque networks is null");
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
        NetworkUtil.reconfigureVMConnectToOpaqueNetwork(vmMor,
                            ethernetCardNetworkMap, connectAnchor);
        assertTrue(
            vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON, true),
            "Successfully powered on the vm",
            "Failed to power on " + "the vm");

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
         vmotionSystem = new VmotionSystem(destConnectAnchor);
         vmotionMor = vmotionSystem.getVMotionSystem(destHostMor);
         vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
         this.destHostMor);
         if(vNic == null){
                 HostVirtualNic origVnic = this.destNwSystem.getVirtualNic(this.destNwSystem.
                                 getNetworkSystem(this.destHostMor), "Management Network",
                                 true);
                 vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
         }

         return true;
    }

    @Test
    public void test() throws Exception {
        Integer deviceKey = null;
        /*
         * Generate the vm relocate spec to connect to the destination dvpg
         */
        VirtualMachineRelocateSpec relocateSpec = new VirtualMachineRelocateSpec();
        //relocateSpec.setDeviceChange(ethernetCardList);
        relocateSpec.setFolder(this.destFolder.getVMFolder(this.destDcMor));
        relocateSpec.setHost(this.destHostMor);
        relocateSpec.setPool(this.destHostSystem.getResourcePool(this.destHostMor).get(0));
        relocateSpec.setService(this.xvcProvisioningHelper.getServiceLocator
                        ("administrator@vsphere.local", "Admin!23"));
        /*this.destDsMor = this.destDatastore.getDatastore(this.destHostMor, "vdnetSharedStorage");
        this.destDsMor = this.destDatastore.getDatastore(this.destHostMor, "vdnetSharedStorage");
        
        Vector<DatastoreInformation> destDsMorList = destDatastore.getDatastoresInfo(destHostMor);
        List<ManagedObjectReference> destDsMorList = destDatastore.getDatastore(destHostMor);
        DatastoreInformation DsInfo;
        
        for(int i=0; i<destDsMorList.size(); i++){
        	DsInfo = destDatastore.getDatastoreInfo(destDsMorList.get(i));
        	if(DsInfo.isAccessible()){
        		this.destDsMor = destDsMorList.get(i);
        		break;
        	}
        }
        */
        this.destDsMor = this.destDatastore.getDatastore(this.destHostMor, "vmstores");
        
        
        relocateSpec.setDatastore(this.destDsMor);
        LogUtil.printDetailedObject(relocateSpec, ":");
        relocateVM(vmMor, relocateSpec, connectAnchor);
        /*
         * Get the destination vm mor from the vmname on the destination
         * datacenter
         */
        this.destVmMor = this.destVm.getVM(this.vmName);
        /*
         * Verify that the vm is still connected to the opaque network
         */
        Map<String,String>  ethernetCardMap = NetworkUtil.
                        getEthernetCardNetworkMap(destVmMor, destConnectAnchor);
        for(String ethernetCardDevice : ethernetCardMap.keySet()){
                String network_id = ethernetCardMap.get(ethernetCardDevice);
                assertTrue(network_id.equals(opaqueNetworkInfo.get(0).
                                   getOpaqueNetworkId()),"The vm is still " +
                                   "connected to the opaque network on the destination " +
                                   "host","The vm is not connected to the opaque " +
                                   "network on the destination host");
        }
    }

    @AfterMethod
    public boolean testCleanUp() throws Exception {
             boolean cleanupWorked = true;
            try {

                if(this.destVmMor != null){
                    assertTrue(
                        this.destVm.setVMState(this.destVmMor,
                        VirtualMachinePowerState.POWERED_OFF, true),
                        "Successfully powered off the vm",
                        "Failed to power off the vm");
                    cleanUpRelocate();
                } else if (this.vmMor != null) {
                        assertTrue(
                                        this.vm.setVMState(this.vmMor,
                                        VirtualMachinePowerState.POWERED_OFF, true),
                                        "Successfully powered off the vm",
                                        "Failed to power off the vm");
                }
            } catch(Throwable t) {
                        t.printStackTrace();
                        cleanupWorked = false;
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
                        DVSUtil.stopNsxa(this.destConnectAnchor, "root", "ca$hc0w");
                } catch (Throwable e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                        cleanupWorked = false;
                }
                assertTrue(cleanupWorked, "Cleanup Succeeded !", "Cleanup Failed !");
        this.sessionManager.logout(sessionMgrMor);
        return true;
    }

    private void relocateVM(ManagedObjectReference vmMor, VirtualMachineRelocateSpec relocateSpec,
        ConnectAnchor vmConnectAnchor) throws Exception {
        VirtualMachine virtualMachine = new VirtualMachine(vmConnectAnchor);
        ManagedObjectReference taskMor = virtualMachine.asyncRelocateVM(
            vmMor,
            relocateSpec,
            VirtualMachineMovePriority.DEFAULT_PRIORITY);
        final Task mTasks = new Task(vmConnectAnchor);
        boolean taskSuccess = mTasks.monitorTask(taskMor);
        final TaskInfo taskInfo = mTasks.getTaskInfo(taskMor);
        if (!taskSuccess) {
            log.warn("Relocate Task failed");
            throw new com.vmware.vc.MethodFaultFaultMsg("", taskInfo.getError().getFault());
        }
    }

    public void cleanupVm() throws Exception {
        Map<String,String> ethernetCardNetworkMap = null;
        if(this.destVmMor != null){
            ethernetCardNetworkMap = NetworkUtil.
                             getEthernetCardNetworkMap(this.destVmMor,
                                                       this.destConnectAnchor);
            for (String deviceLabel : ethernetCardNetworkMap.keySet()) {
                ethernetCardNetworkMap.put(deviceLabel, "VM Network");
            }
            NetworkUtil.reconfigureVMConnectToPortgroup(this.destVmMor,
                this.destConnectAnchor, ethernetCardNetworkMap);

        } else {
            ethernetCardNetworkMap = NetworkUtil.
                getEthernetCardNetworkMap(this.vmMor,
                                          this.connectAnchor);
            for (String deviceLabel : ethernetCardNetworkMap.keySet()) {
                ethernetCardNetworkMap.put(deviceLabel, "VM Network");
            }
            NetworkUtil.reconfigureVMConnectToPortgroup(this.vmMor,
                this.connectAnchor, ethernetCardNetworkMap);
        }
    }

    public void cleanUpRelocate() throws Exception {
        cleanupVm();
        VirtualMachineRelocateSpec cleanupSpec = new VirtualMachineRelocateSpec();
        cleanupSpec.setHost(this.hostMor);
        cleanupSpec.setPool(hostSystem.getResourcePool(this.hostMor).get(0));
        cleanupSpec.setFolder(this.folder.getVMFolder(this.dcMor));
        this.xvcProvisioningHelper = new XvcProvisioningHelper(this.destConnectAnchor, this.connectAnchor);
        cleanupSpec.setService(this.xvcProvisioningHelper.getServiceLocator("administrator@vsphere.local", "Admin!23"));
        cleanupSpec.setDatastore(this.dsMor);
        relocateVM(this.destVmMor, cleanupSpec, this.destConnectAnchor);
        //this.sessionManager.logout(sessionMgrMor);
    }
}
