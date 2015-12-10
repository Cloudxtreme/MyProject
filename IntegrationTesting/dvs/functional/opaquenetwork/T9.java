package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.VmHelper;
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

public class T9 extends TestBase{

        private Folder folder = null;
        private HostSystem hostSystem = null;
        private VmHelper vmHelper = null;
        private Datacenter dc = null;
        private VirtualMachine vm = null;
        private NetworkSystem nwSystem = null;
        private DatastoreSystem dataStoreSystem = null;
        private ManagedObjectReference dcMor = null;
        private ProvisioningOpsStorageHelper storageHelper = null;
        private ManagedObjectReference hostMor = null;
        private NetworkSystem ins = null;
        private ManagedObjectReference nsMor =         null;
        private ManagedObjectReference vmMor = null;
        private VirtualMachineConfigSpec origVMConfigSpec = null;
        private DistributedVirtualSwitch vds = null;
        private ManagedObjectReference vdsMor = null;
        private DVSConfigSpec vdsConfigSpec = null;
        private DistributedVirtualPortgroup dvpg;
        private String pgKey;
    private ManagedObjectReference pgMor = null;
    private String vds_uuid = null;
    private String port_key = null;
        private Set<String> ethernetCardDevicesSet;
        private List<HostOpaqueNetworkInfo> opaqueNetworkInfo;



        public void initialize() throws Exception {
                folder  = new Folder(connectAnchor);
                hostSystem = new HostSystem(connectAnchor);
                vmHelper = new VmHelper(connectAnchor);
                dc = new Datacenter(connectAnchor);
                vm = new VirtualMachine(connectAnchor);
                nwSystem = new NetworkSystem(connectAnchor);
                dataStoreSystem = new DatastoreSystem(connectAnchor);
                storageHelper = new ProvisioningOpsStorageHelper(connectAnchor);
                ins = new NetworkSystem(connectAnchor);
                hostMor = hostSystem.getAllHost().get(0);
                vds = new DistributedVirtualSwitch(connectAnchor);
                dcMor = this.folder.getDataCenter();
                if(dcMor == null){
                        this.folder.createDatacenter(folder.getRootFolder(), "dc-1");
                }
                /*
                 *  create a vds in the network folder
                 */
                vdsConfigSpec = DVSUtil.createDefaultDVSConfigSpec("vds-1");
        vdsConfigSpec.setNumStandalonePorts(10);
        vdsMor = folder.createDistributedVirtualSwitch(
                         folder.getNetworkFolder(dcMor),vdsConfigSpec);
        assertTrue(DVSUtil.addSingleFreePnicAndHostToDVS(connectAnchor, hostMor,
                           Arrays.asList(new ManagedObjectReference[]{vdsMor})),
                           "Successfully added the free pnic on the host to the vds",
                           "Failed to add the free pnic on the host to the vds");
        /*
         * Add a portgroup on the vds
         */
        this.dvpg = new DistributedVirtualPortgroup(connectAnchor);
        DVPortgroupConfigSpec[] portgrpSpecArray = new DVPortgroupConfigSpec[1];
        portgrpSpecArray[0] = new DVPortgroupConfigSpec();
        portgrpSpecArray[0].setName("pg-1");
        portgrpSpecArray[0].setNumPorts(10);
        pgKey = this.vds.addPortGroup(vdsMor,
                  DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 10, "vds-pg-1");
        pgMor = this.dvpg.getPortgroupMor(vdsMor, pgKey);
        /*
         * Get a free port in the vds
         */
        this.port_key = this.vds.getFreeStandaloneDVPortKey(vdsMor, null);
        this.vds_uuid = this.vds.getConfig(vdsMor).getUuid();
    }


        @BeforeMethod
        public boolean testSetUp() throws Exception {
                /*
                 * Init code for all entities in the inventory
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

                /*
                 * Query for the opaque network
                 */
                nsMor = ins.getNetworkSystem(hostMor);
                opaqueNetworkInfo = ins.
                                getNetworkInfo(nsMor).getOpaqueNetwork();
                assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                          "The list of opaque networks is not null",
                          "The list of opaque networks is null");
                /*
                 * Get the first available vm in the inventory
                 */
                this.vmMor = hostSystem.getVMs
                              (hostMor, VirtualMachinePowerState.POWERED_OFF).get(0);
                Map<String,String> vmEthernetMap = NetworkUtil.
                                getEthernetCardNetworkMap(vmMor, connectAnchor);
        ethernetCardDevicesSet = vmEthernetMap.keySet();
        /*
         * Compute a new ethernet card network map
         */
        Map<String,HostOpaqueNetworkInfo> ethernetCardNetworkMap = new
                        HashMap<String,HostOpaqueNetworkInfo>();
                for(String ethernetCard : ethernetCardDevicesSet){
                        ethernetCardNetworkMap.put(ethernetCard,
                                opaqueNetworkInfo.get(0));
                }
        /*
         * Reconfigure the virtual machine to connect to opaque network
         */
                this.origVMConfigSpec = NetworkUtil.
                                               reconfigureVMConnectToOpaqueNetwork(vmMor,
                                               ethernetCardNetworkMap, connectAnchor);
        return true;
        }

        @Test
        public void test() throws Exception {
                /*
                 * Power on the vm
                 */
                assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON,
                                true),"Successfully powered on the virtual machine",
                                "Failed to power on the virtual machine");
                /*
                 * Check network connectivity
                 */
                assertTrue(vm.getIPAddress(vmMor) != null, "vm ip is not null",
                        "vm ip is null");
                assertTrue(DVSUtil.checkNetworkConnectivity(hostSystem.
                                   getIPAddress(hostMor),vm.getIPAddress(vmMor)),
                                   "The vm is reachable","The vm is not reachable");

        /*
         * Compute a new ethernet card network map
         */
        Map<String,HostOpaqueNetworkInfo> ethernetCardNetworkMap = new
                        HashMap<String,HostOpaqueNetworkInfo>();
                for(String ethernetCard : ethernetCardDevicesSet){
                        ethernetCardNetworkMap.put(ethernetCard,
                                opaqueNetworkInfo.get(1));
                }

        /*
         * Reconfigure the virtual machine to connect to 2nd opaque network
         */
                this.origVMConfigSpec = NetworkUtil.
                                               reconfigureVMConnectToOpaqueNetwork(vmMor,
                                               ethernetCardNetworkMap, connectAnchor);

                /*
                 * Check network connectivity
                 */
                assertTrue(vm.getIPAddress(vmMor) != null, "vm ip is not null",
                        "vm ip is null");
                assertTrue(DVSUtil.checkNetworkConnectivity(hostSystem.
                                   getIPAddress(hostMor),vm.getIPAddress(vmMor)),
                                   "The vm is reachable","The vm is not reachable");

                /*
                 * Power off the vm
                 */
                assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
                                false),"Successfully powered on the virtual machine",
                                "Failed to power on the virtual machine");
                /*
                 * Compute ethMap
                 */
                Map<String,Map<String,Boolean>> ethMap = new HashMap<String,
                                Map<String,Boolean>>();
                String eth_device = this.ethernetCardDevicesSet.iterator().next();
                /*
                 * Compute port boolean map
                 */
                Map<String,Boolean> portBoolMap = new HashMap<String,Boolean>();
                portBoolMap.put(port_key, false);
                /*
                 * Put the ethernet card device into the map
                 */
                ethMap.put(eth_device, portBoolMap);
                /*
                 * Connect the vm's vnic to a vds port
                 */
                DVSUtil.reconfigureVMConnectToVdsPort(vmMor, connectAnchor, ethMap,
                                vds_uuid);
                /*
                 * Connect the vm's vnic to to the opaque network
                 */
                Map<String,HostOpaqueNetworkInfo> ethNetMap = new
                                HashMap<String,HostOpaqueNetworkInfo>();
                ethNetMap.put(eth_device, opaqueNetworkInfo.get(0));
        NetworkUtil.reconfigureVMConnectToOpaqueNetwork(vmMor, ethNetMap,
                        connectAnchor);
        /*
                 * Power on the vm
                 */
                assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON,
                                true),"Successfully powered on the virtual machine",
                                "Failed to power on the virtual machine");
                /*
                 * Check network connectivity
                 */
                assertTrue(vm.getIPAddress(vmMor) != null, "vm ip is not null",
                        "vm ip is null");
                assertTrue(DVSUtil.checkNetworkConnectivity(hostSystem.
                                   getIPAddress(hostMor),vm.getIPAddress(vmMor)),
                                   "The vm is reachable","The vm is not reachable");
                /*
                 * Power off the vm
                 */
                assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
                                false),"Successfully powered on the virtual machine",
                                "Failed to power on the virtual machine");

        /*
         * Connect vnic back to the vds port
         */
                DVSUtil.reconfigureVMConnectToVdsPort(vmMor, connectAnchor, ethMap,
                                vds_uuid);
                /*
                 * Clear ethMap
                 */
                ethMap = new HashMap<String,Map<String,Boolean>>();
                /*
                 * Populate ethMap based on connection to portgroup
                 */
                portBoolMap = new HashMap<String,Boolean>();
                portBoolMap.put(pgKey, true);
        ethMap.put(eth_device, portBoolMap);
        /*
         * Connect vm vnic to the vds portgroup
         */
        DVSUtil.reconfigureVMConnectToVdsPort(vmMor, connectAnchor, ethMap,
                                vds_uuid);
        /*
         * Connect vnic to the opaque network
         */
        NetworkUtil.reconfigureVMConnectToOpaqueNetwork(vmMor, ethNetMap,
                        connectAnchor);
        /*
                 * Power on the vm
                 */
                assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON,
                                true),"Successfully powered on the virtual machine",
                                "Failed to power on the virtual machine");
                /*
                 * Check network connectivity
                 */
                assertTrue(vm.getIPAddress(vmMor) != null, "vm ip is not null",
                        "vm ip is null");
                assertTrue(DVSUtil.checkNetworkConnectivity(hostSystem.
                                   getIPAddress(hostMor),vm.getIPAddress(vmMor)),
                                   "The vm is reachable","The vm is not reachable");

                /*
                 * Connect vnic to the vds portgroup back
                 */
                DVSUtil.reconfigureVMConnectToVdsPort(vmMor, connectAnchor, ethMap,
                                vds_uuid);
        }

        @AfterMethod
        public boolean testCleanUp() throws Exception {
                boolean cleanupWorked = true;
                try {
                    if(vmMor != null){
                        /*
                         * Power off the vm
                         */
                        if (vm.getVMState(vmMor).equals
                                (VirtualMachinePowerState.POWERED_ON)) {
                            assertTrue(vm.setVMState(vmMor,VirtualMachinePowerState.
                                    POWERED_OFF, false),"Successfully powered on the"
                                            + "virtual machine",
                                            "Failed to power on the virtual machine");
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
                } catch (Exception t) {
                        t.printStackTrace();
                        cleanupWorked = false;
                        DVSUtil.testbedTeardown(connectAnchor, true);
                }

                try {
                    if(vdsMor != null){
                        vds.destroy(vdsMor);
                    }
                } catch (Exception e) {
                    e.printStackTrace();
                    cleanupWorked = false;
                }
                
                try {
                        DVSUtil.testbedTeardown(connectAnchor);
                } catch (Exception e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                        cleanupWorked = false;
                }
                try {
                        DVSUtil.stopNsxa(connectAnchor, "root", "ca$hc0w");
                } catch (Exception e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                        cleanupWorked = false;
                }
                assertTrue(cleanupWorked, "Cleanup Succeeded !", "Cleanup Failed !");
                return true;
        }
}
