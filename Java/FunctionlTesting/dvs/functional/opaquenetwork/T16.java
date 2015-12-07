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

import com.vmware.vc.ClusterConfigSpec;
import com.vmware.vc.ClusterDrsConfigInfo;
import com.vmware.vc.ClusterRuleSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DrsBehavior;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostOpaqueNetworkInfo;
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
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;
import com.vmware.vcqa.vim.xvcprovisioning.XvcProvisioningHelper;


/**
 * Move the vm connected to an opaque network across
 * across hosts over L3 network
 *
 * @author sabesanp
 *
 */

public class T16 extends TestBase {

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
        String dest_host_ip = DVSUtil.getl3HostIP();
        //this.connectAnchor = new ConnectAnchor(dest_host_ip, 443);
        //this.sessionManager = new SessionManager(this.connectAnchor);
        //this.sessionMgrMor = this.sessionManager.getSessionManager();
        //this.hostLoginSession = this.sessionManager.login
        //                      (sessionMgrMor, "root", "ca$hc0w", null);
        //this.xvcProvisioningHelper = new XvcProvisioningHelper
        //                      (this.connectAnchor, this.connectAnchor);
        //this.destHostSystem = new HostSystem(this.connectAnchor);
        //this.destFolder = new Folder(this.connectAnchor);
        //this.destDcMor = this.destFolder.getDataCenter();
        this.destDvs = new DistributedVirtualSwitch(this.connectAnchor);
        this.destDataStoreSystem = new DatastoreSystem(this.connectAnchor);
        this.destVm = new VirtualMachine(this.connectAnchor);
        this.destDatastore = new Datastore(this.connectAnchor);
    }

    /**
     * Method to create the cluster
     *
     * @param clusterName name of the cluster
     * @return clusterMor
     */
    private ManagedObjectReference createCluster(String clusterName)
               throws Exception
            {

               ClusterComputeResource icr = new ClusterComputeResource(connectAnchor);
               ManagedObjectReference clusterMor = null;
               if (hostFolderMor != null) {
                  log.info("Got the host folder");
                  ClusterConfigSpec clusterSpec = folder.createClusterSpec();
                  ClusterDrsConfigInfo drsConfig = new ClusterDrsConfigInfo();
                  drsConfig.setEnabled(false);
                  drsConfig.setDefaultVmBehavior(DrsBehavior.FULLY_AUTOMATED);
                  clusterSpec.setDrsConfig(drsConfig);
                  ClusterRuleSpec ruleSpec[] = new ClusterRuleSpec[0];
                  clusterSpec.getRulesSpec().clear();
                  clusterSpec.getRulesSpec().addAll(
                            com.vmware.vcqa.util.TestUtil.arrayToVector(ruleSpec));
                  clusterSpec.getDasConfig().setEnabled(new Boolean(false));
                  clusterSpec.getDasConfig().setAdmissionControlEnabled(
                           new Boolean(false));
                  clusterMor = folder.createCluster(hostFolderMor, clusterName,
                           clusterSpec);
                  ManagedObjectReference[] a = new ManagedObjectReference[
                                                hostSystem.getAllHost().size()];
                  icr.moveInto(clusterMor, hostSystem.getAllHost().toArray(a));
               }
               return clusterMor;
            }

    public void cleanUpRelocate() throws Exception {
        cleanupVm();
        VirtualMachineRelocateSpec cleanupSpec = new VirtualMachineRelocateSpec();
        cleanupSpec.setHost(this.hostMor);
        cleanupSpec.setPool(hostSystem.getResourcePool(this.hostMor).get(0));
        cleanupSpec.setFolder(this.folder.getVMFolder(this.dcMor));
        //this.xvcProvisioningHelper
        //  = new XvcProvisioningHelper(this.connectAnchor, this.connectAnchor);
        //cleanupSpec.setService(
        //   this.xvcProvisioningHelper.getServiceLocator("root", "vmware"));
        cleanupSpec.setDatastore(this.dsMor);
        relocateVM(this.destVmMor, cleanupSpec, this.connectAnchor);
        // this.sessionManager.logout(sessionMgrMor);
    }

    public void cleanupVm() throws Exception {
        Map<String,String> ethernetCardNetworkMap = null;
        if(this.destVmMor != null){
            ethernetCardNetworkMap = NetworkUtil.
                             getEthernetCardNetworkMap(this.destVmMor,
                                                       this.connectAnchor);
            for (String deviceLabel : ethernetCardNetworkMap.keySet()) {
                ethernetCardNetworkMap.put(deviceLabel, "VM Network");
            }
            NetworkUtil.reconfigureVMConnectToPortgroup(this.destVmMor,
                this.connectAnchor, ethernetCardNetworkMap);

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

    public void registerVm() throws Exception {
        // hostMorList = hostSystem.getAllHost();
        // hostMor = hostMorList.get(0);
        int count = 1;
        this.datastoreSystemMor
            = dataStoreSystem.getDatastoreSystem(this.destHostMor);
        ManagedObjectReference datastoreMor = dataStoreSystem.addNasVol(
            "fvt-1",
            "10.115.160.201",
            "nfs-network",
            this.datastoreSystemMor);
        /*
         * vmMor = vmHelper.registerVmFromDatastore("rhel-netioc-vm-2",
         * "nfs-network",hostMor);
         * log.info("rhel-netioc-vm-2 registered on host : " +
         * hostSystem.getHostName(hostMor));
         */
    }

    public void unregisterVms() throws Exception {
        List<ManagedObjectReference> vmMorList = vm.getAllVM();
        if (vmMorList != null && vmMorList.size() >= 1) {
            for (ManagedObjectReference vm_Mor : vmMorList) {
                assertTrue(
                    vm.setVMState(vm_Mor,
                    VirtualMachinePowerState.POWERED_OFF, false),
                    "Successfully powered off the virtual machine",
                    "Failed to power off the virtual machine");
                assertTrue(
                    vm.unregisterVM(vm_Mor),
                    "Successfully unregistered vm : " + vm_Mor,
                    "Failed to unregister vm : " + vm_Mor);
            }
        }
    }

    public void destroyVds() throws Exception {
        dcMor = folder.getDataCenter();
        if (dcMor != null) {
            List<ManagedObjectReference> vdsMorList
                    = folder.getAllDistributedVirtualSwitch(folder
                .getNetworkFolder(dcMor));
            List<ManagedObjectReference> vmList = vm.getAllVM();
            if (vdsMorList != null) {
                for (ManagedObjectReference m : vdsMorList) {
                    dvs.destroy(m);
                }
            }
        }
    }

    public void destroyDestVds() throws Exception {
        destDcMor = destFolder.getDataCenter();
        if (destDcMor != null) {
            List<ManagedObjectReference> vdsMorList = destFolder.
                getAllDistributedVirtualSwitch(destFolder
                .getNetworkFolder(destDcMor));
            List<ManagedObjectReference> vmList = destVm.getAllVM();
            if (vdsMorList != null) {
                for (ManagedObjectReference m : vdsMorList) {
                    destDvs.destroy(m);
                }
            }
        }
    }

    public List<ManagedObjectReference> addHost(String vcip,
            List<String> esxipList, int port) throws Exception {
        /*
         * Create datacenter
         */
        List<ManagedObjectReference> hostMorList
        = new ArrayList<ManagedObjectReference>();
        dcMor = folder.getDataCenter();
        if (dcMor == null) {
            // dvs.destroy(dcMor);
            dcMor = folder.createDatacenter(folder.getRootFolder(), "dc");
        }
        HostConnectSpec hostConnectSpec = null;
        for (String esxip : esxipList) {
            ManagedObjectReference hostMor = hostSystem.addStandaloneHost(
                dc.getHostFolder(dcMor),
                hostSystem.createHostConnectSpec(esxip, true),
                null,
                true);
            if (hostMor != null) {
                System.out.println("The host : " +
                        esxip + "was successfully added");
            }
            hostMorList.add(hostMor);
        }
        hostMor = hostSystem.getConnectedHost(false);
        // log.info("The host size : " + hostMorList.size());
        /*
         * List<ManagedObjectReference> vmMorList = hostSystem.
         * getAllVirtualMachine(hostMor);
         * if (vmMorList != null && vmMorList.size() >= 1) {
         * for (ManagedObjectReference vmMor : vmMorList) {
         * vm.destroy(vmMor);
         * }
         * }
         * List<ManagedObjectReference> vdsList = folder.
         * getAllDistributedVirtualSwitch(folder.getNetworkFolder(dcMor));
         * if (vdsList != null && vdsList.size() >= 1) {
         * dvs.destroy(srcVdsMor);
         * }
         */
        return hostMorList;
    }

    public void setSourceParameters() throws Exception {
        this.hostMor = hostSystem.getHost("10.67.230.172");
        this.vmMor = vm.getAllVM().elementAt(0);
        this.vmName = this.vm.getVMName(vmMor);
        this.dsMor = this.storageHelper.getVMConfigDatastore(vmMor);
        // registerVm();
        /*
         * Enable vmotion on both the host vnics
         */
        /*
         * VmotionSystem vmotionSystem = new VmotionSystem(connectAnchor);
         * ManagedObjectReference vmotionMor = vmotionSystem.
         * getVMotionSystem(hostMor);
         * HostVirtualNic vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
         * hostMor);
         * if(vNic == null){
         * HostVirtualNic origVnic = nwSystem.getVirtualNic(nwSystem.
         * getNetworkSystem(hostMor), "Management Network", true);
         * vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
         * }
         * vmotionMor = vmotionSystem.getVMotionSystem(destHostMor);
         * vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
         * this.destHostMor);
         * if(vNic == null){
         * HostVirtualNic origVnic = nwSystem.getVirtualNic(nwSystem.
         * getNetworkSystem(this.destHostMor), "Management Network",
         * true);
         * vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
         * }
         */
        // cleanupVm();
        destroyVds();
        /*
         * Create vds version 6.0.0
         */
        DVSConfigSpec vdsConfigSpec = new DVSConfigSpec();
        vdsConfigSpec.setName("CV_S001_srcVds");
        vdsConfigSpec.setNumStandalonePorts(10);
        srcVdsMor = folder.createDistributedVirtualSwitch(
                                folder.getNetworkFolder(dcMor),
                                vdsConfigSpec);
        assertNotNull(srcVdsMor, "Successfully created the source vds",
                                 "Failed to create the source vds");
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

    public void reconfigureVMConnectToVdsPort() throws Exception {

        DistributedVirtualSwitchPortConnection[] portConnection
                        = new DistributedVirtualSwitchPortConnection[2];
        for (int i = 0; i < 2; i++) {
            portConnection[i] = new DistributedVirtualSwitchPortConnection();
            portConnection[i].setSwitchUuid(dvs.getConfig(srcVdsMor).getUuid());
        }
        this.dvportKey[0] = dvs.getFreeStandaloneDVPortKey(srcVdsMor, null);
        portConnection[0].setPortKey(this.dvportKey[0]);
        HashMap<String, List<String>> excludedPorts
                        = new HashMap<String, List<String>>();
        ArrayList<String> listExcludedPorts = new ArrayList<String>();
        listExcludedPorts.add(this.dvportKey[0]);
        excludedPorts.put(null, listExcludedPorts);
        this.dvportKey[1] = dvs.getFreeStandaloneDVPortKey(srcVdsMor, excludedPorts);
        portConnection[1].setPortKey(this.dvportKey[1]);
        Map<String, Map<String, Boolean>> ethernetCardMap
                = new HashMap<String, Map<String, Boolean>>();
        Map<String, String> ethMap
                = NetworkUtil.getEthernetCardNetworkMap(vmMor, connectAnchor);
        int i = 0;
        for (String dev : ethMap.keySet()) {
            Map<String, Boolean> portBoolMap = new HashMap<String, Boolean>();
            portBoolMap.put(this.dvportKey[i], false);
            ethernetCardMap.put(dev, portBoolMap);
            i++;
        }
        this.reconfigVmSpec = DVSUtil.reconfigureVMConnectToVdsPort(vmMor,
                                                                    connectAnchor,
                                                                    ethernetCardMap,
                                                dvs.getConfig(srcVdsMor).getUuid());
    }


    @BeforeMethod
    public boolean testSetUp() throws Exception {
        /*
         * Create datacenter
         */
        initialize();
        try {
            DVSUtil.testbedSetup(connectAnchor);
        } catch (Throwable e) {
            e.printStackTrace();
            return false;
        }
        // unregisterVms();
        // destroyVds();
        // addHost("10.115.174.167", esxIpList, 443);
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
        esxIpList.add(DVSUtil.getl3HostIP());
        this.destHostMor = addHost(connectAnchor.getHostName(), esxIpList, 443).get(0);

        DVSUtil.startNsxa(connectAnchor, "root", "ca$hc0w", "vmnic2");
        DVSUtil.registerVMsToHost(connectAnchor, destHostMor, 7);
        //cleanupVm();
        this.dsMor = this.storageHelper.getVMConfigDatastore(vmMor);


        hostFolderMor = folder.getHostFolder(folder.getDataCenter());
        clusterMor = createCluster("cl-1");
        TransitionalEVCManager tevcManager = new TransitionalEVCManager(connectAnchor);
        tevcManagerMor = tevcManager.getTransitionalEVCManager(clusterMor);
        tevcManager.configureEVC(tevcManagerMor, "intel-nehalem");

        // registerVm();
        /*
         * Enable vmotion on both the host vnics
         */
        /*
         * VmotionSystem vmotionSystem = new VmotionSystem(connectAnchor);
         * ManagedObjectReference vmotionMor = vmotionSystem.
         * getVMotionSystem(hostMor);
         * HostVirtualNic vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
         * hostMor);
         * if(vNic == null){
         * HostVirtualNic origVnic = nwSystem.getVirtualNic(nwSystem.
         * getNetworkSystem(hostMor), "Management Network", true);
         * vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
         * }
         * vmotionMor = vmotionSystem.getVMotionSystem(destHostMor);
         * vNic = vmotionSystem.getVmotionVirtualNic(vmotionMor,
         * this.destHostMor);
         * if(vNic == null){
         * HostVirtualNic origVnic = nwSystem.getVirtualNic(nwSystem.
         * getNetworkSystem(this.destHostMor), "Management Network",
         * true);
         * vmotionSystem.selectVnic(vmotionMor, origVnic.getDevice());
         * }
         */
        // cleanupVm();
        destroyVds();
        //destroyDestVds();
        /*
         * Create vds version 6.0.0
         */
        DVSConfigSpec vdsConfigSpec = new DVSConfigSpec();
        vdsConfigSpec.setName("CV_P005_srcVds");
        vdsConfigSpec.setNumStandalonePorts(10);
        srcVdsMor = folder.createDistributedVirtualSwitch(
                    folder.getNetworkFolder(dcMor),
                    vdsConfigSpec);
        assertNotNull(srcVdsMor,
                      "Successfully created the source vds",
                      "Failed to create the source vds");

        /*
         * Get all vms in the inventory and pick one of them
         */
        // List<ManagedObjectReference> vmMorList = vm.getAllVM();

        // assertTrue(vmMorList != null && vmMorList.size() >=1,"There is " +
        // "atleast one virtual machine in the inventory","There are no " +
        // "virtual machines in the inventory");
        /*
         * Add a host to vds
         */
        List<ManagedObjectReference> dvsMorList
                = new ArrayList<ManagedObjectReference>();
        dvsMorList.add(srcVdsMor);
        // dvsMorList.add(destVdsMor);
        assertTrue(
            DVSUtil.addSingleFreePnicAndHostToDVS(connectAnchor, hostMor, dvsMorList),
            "Successfully added the host to both the " + "source and destination vdses",
            "Failed to add the host " + "to both the source and the destination vds");
        /*
         * Set the destination parameters
         */
        vdsConfigSpec.setName("CV_P005_destVds");
        destVdsMor = this.folder.createDistributedVirtualSwitch(
            this.folder.getNetworkFolder(this.dcMor),
            vdsConfigSpec);
        assertNotNull(destVdsMor, "Successfully created the destination vds",
                                  "Failed to create the destination vds");
        dvsMorList = new ArrayList<ManagedObjectReference>();
        dvsMorList.add(destVdsMor);
        assertTrue(
            DVSUtil.addSingleFreePnicAndHostToDVS(this.connectAnchor,
                                                  this.destHostMor,
                                                  dvsMorList),
            "Successfully added the host to " + "both the source and destination vdses",
            "Failed to add the " + "host to both the source and the destination vds");
        addPortgroups();

        /*
         * Get the number of ethernet card devices on the vm
         */
        int numCards = DVSUtil.getAllVirtualEthernetCardDevices(vmMor,
                                                                connectAnchor).size();
        this.dvportKey = new String[numCards];
        // this.dvportKeyArray = new String[numCards];
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
        return true;
    }

    public void addPortgroups()
        throws Exception
     {
         this.srcPgKey = dvs.addPortGroup(srcVdsMor,
             DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING, 2,
             "src_pg_1");
         this.destPgKey = destDvs.addPortGroup(destVdsMor,
              DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING, 2,
              "dest_pg_1");
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
                portConn.setSwitchUuid(destDvs.getConfig(destVdsMor).getUuid());
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

    public List<VirtualDeviceConfigSpec> generateEthernetDeviceChangeForVdsPort()
        throws Exception
    {
        this.destDvPortKey = new String[2];
        this.destDvPortKey[0] = destDvs.getFreeStandaloneDVPortKey(destVdsMor,
            null);
        HashMap<String,List<String>> excludedPorts = new
                 HashMap<String,List<String>>();
        ArrayList<String> excludedPortsList = new ArrayList<String>();
        excludedPortsList.add(this.destDvPortKey[0]);
        excludedPorts.put(null,excludedPortsList);
        this.destDvPortKey[1] = destDvs.getFreeStandaloneDVPortKey(destVdsMor,
                 excludedPorts);
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
                portConn.setPortKey(this.destDvPortKey[i]);
                portConn.setSwitchUuid(destDvs.getConfig(destVdsMor).getUuid());
                backInfo.setPort(portConn);
                vd.setBacking(backInfo);
                ethDestMap.put(vd.getDeviceInfo().getLabel(),
                    this.destDvPortKey[i]);
                spec.setOperation(VirtualDeviceConfigSpecOperation.EDIT);
                i++;
            }
        }
        return ethernetCardList;
    }

    @Test
    public void test() throws Exception {
        Integer deviceKey = null;
        /*
         * Generate the vm relocate spec to connect to the destination dvpg
         */
        VirtualMachineRelocateSpec relocateSpec = new VirtualMachineRelocateSpec();
        List<VirtualDeviceConfigSpec> ethernetCardList =
            generateEthernetDeviceChangeForVdsPort();
        //relocateSpec.setDeviceChange(ethernetCardList);
        relocateSpec.setFolder(this.folder.getVMFolder(this.destDcMor));
        relocateSpec.setHost(this.destHostMor);
        relocateSpec.setPool(this.hostSystem.getResourcePool(this.destHostMor).get(0));
        //relocateSpec.setService(
        //this.xvcProvisioningHelper.getServiceLocator("root", "vmware"));
        this.destDsMor = this.destDatastore.getDatastore(
                            this.destHostMor, "vimapi_vms");
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
                getEthernetCardNetworkMap(destVmMor, connectAnchor);
        for(String ethernetCardDevice : ethernetCardMap.keySet()){
            String network_id = ethernetCardMap.get(ethernetCardDevice);
            assertTrue(network_id.equals(opaqueNetworkInfo.get(0).
                       getOpaqueNetworkId()),"The vm is still " +
                       "connected to the opaque network on the destination " +
                       "host","The vm is not connected to the opaque " +
                       "network on the destination host");
        }
    }
    /**
     * Method to perform enterMaintenanceMode for hosts
     *
     * @param hostMorsList List of host mors
     * @return
     */
    private void setEnterMaintenanceMode(List<ManagedObjectReference> hostMorsList,
                                         boolean evacuate)
       throws Exception
    {
       String hostName = null;
       for (ManagedObjectReference mor : hostMorsList) {
          hostName = hostSystem.getHostName(mor);
          if (!hostSystem.isHostInMaintenanceMode(mor)) {
             if (hostSystem.enterMaintenanceMode(mor,
                      60, evacuate)) {
                log.info("Host is in  maintenanceMode:" + hostName);
             } else {
                log.error("Unable to set the "
                         + "enterMaintenanceMode for host :" + hostName);
                throw (new Exception("Unable to set the "
                         + "  enterMaintenanceMode  : " + hostName));
             }
          }
       }
    }

    /**
     * Method to perform exitMaintenanceMode
     *
     * @param hostMorsList List of host mors
     * @return
     */
    private void setExitMaintenanceMode(List<ManagedObjectReference> hostMorsList)
       throws Exception
    {
       String hostName = null;
       for (ManagedObjectReference mor : hostMorsList) {
          hostName = hostSystem.getHostName(mor);
          if (hostSystem.isHostInMaintenanceMode(mor)) {
             if (hostSystem.exitMaintenanceMode(mor,
                      TestConstants.EXIT_MAINTMODE_DEFAULT_TIMEOUT_SECS)) {
                log.info("Host is in  exitMaintenanceMode :" + hostName);
             } else {
                log.error("Unable to set the exitMaintenanceMode :"
                         + hostName);
                throw (new Exception("Unable to set the exitMaintenanceMode "));
             }
          }
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
            if (clusterMor != null) {
               ManagedObjectReference[] hostMors =new
                       ManagedObjectReference[hostSystem.getAllHost().size()];
               hostMors = hostSystem.getAllHost().toArray(hostMors);
               setEnterMaintenanceMode(hostSystem.getAllHost(), false);
               assertTrue((folder.moveInto(hostFolderMor,
                        hostMors)),
                        "Moved hosts  successfully", "Move hosts failed ");
               setExitMaintenanceMode(hostSystem.getAllHost());
               assertTrue((folder.destroy(clusterMor)),
                        "Successfully destroyed cluster",
                        "Unable to destroy cluster");
            }
            dvs.destroy(srcVdsMor);
            destDvs.destroy(destVdsMor);
            cleanupVm();
            // dvs.destroy(dcMor);
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
        } catch (Throwable e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            cleanupWorked = false;
        }
        try {
            hostSystem.destroy(destHostMor);
        } catch (Throwable e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
        }
        assertTrue(cleanupWorked, "Cleanup Succeeded !", "Cleanup Failed !");
        //this.sessionManager.logout(sessionMgrMor);
        return true;
    }

    private void relocateVM(ManagedObjectReference vmMor,
                            VirtualMachineRelocateSpec relocateSpec,
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
            throw new com.vmware.vc.MethodFaultFaultMsg("",
                                taskInfo.getError().getFault());
        }
    }
}
