package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.VmHelper;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.vm.Snapshot;

public class T11On extends TestBase{

        private Folder folder = null;
        private HostSystem hostSystem = null;
        private VmHelper vmHelper = null;
        private Datacenter dc = null;
        private VirtualMachine vm = null;
        private NetworkSystem nwSystem = null;
        private DatastoreSystem dataStoreSystem = null;
        private ManagedObjectReference dcMor = null;
        private ManagedObjectReference hostMor = null;
        private NetworkSystem ins = null;
        private ManagedObjectReference nsMor = null;
        private ManagedObjectReference vmMor = null;
        private VirtualMachineConfigSpec origVMConfigSpec = null;
        private String vmName;
        private String vmPath;
        private ManagedObjectReference resPool;
        private ManagedObjectReference vmFolderMor;
        private List<HostOpaqueNetworkInfo> opaqueNetworkInfo;
        private ManagedObjectReference snapshotMor;
        private Snapshot snapShot;



        public void initialize() throws Exception {
                folder  = new Folder(connectAnchor);
                hostSystem = new HostSystem(connectAnchor);
                vmHelper = new VmHelper(connectAnchor);
                dc = new Datacenter(connectAnchor);
                vm = new VirtualMachine(connectAnchor);
                nwSystem = new NetworkSystem(connectAnchor);
                dataStoreSystem = new DatastoreSystem(connectAnchor);
                ins = new NetworkSystem(connectAnchor);
                hostMor = hostSystem.getAllHost().get(0);
                snapShot = new Snapshot(connectAnchor);
        }


        @BeforeMethod
        public boolean testSetUp() throws Exception {
                /*
                 * Init code for all entities in the inventory
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

                /*
                 * Power on the vm
                 */
                assertTrue(vm.setVMState(vmMor,
                                  VirtualMachinePowerState.POWERED_ON,
                                  false),"Successfully powered on the virtual machine",
                                   "Failed to power on the virtual machine");

                /*
                 * Check network connectivity
                 */

                assertTrue(vm.getIPAddress(vmMor) != null, "vm ip is not null", "vm ip is null");
                assertTrue(DVSUtil.checkNetworkConnectivity(hostSystem.
                                   getIPAddress(hostMor),vm.getIPAddress(vmMor)),
                                   "The vm is reachable","The vm is not reachable");

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
                /*
                 * Create a vm snapshot
                 */
                snapshotMor = vm.createSnapshot(vmMor, "snapshot-1", "First snapshot",
                                      true, false);
        /*
         * Check if the snapshot is valid
         */
                assertTrue(snapshotMor != null,"The snapshot is valid",
                                   "The snapshot is invalid");
                return true;
        }

        @Test
        public void test() throws Exception {
                /*
                 * Reconfigure the vm to connect to vss portgroup here
                 */
                assertTrue(vm.reconfigVM(vmMor, origVMConfigSpec),
                                   "Reconfigured the vm to its original settings",
                                   "Failed to reconfigure the vm to its original settings");
        /*
         * TODO : check if you need to power on the vm here before reverting
         * ---Revert to the previous snapshot
         */
        assertTrue(snapShot.revertToSnapshot(snapshotMor, hostMor, null),
                          "Successfully reverted to the snapshot",
                          "Failed to revert to the snapshot");
        /*
         * Make sure that this connects to the opaque network
         */
        Map<String,String> ethMap = NetworkUtil.
                                getEthernetCardNetworkMap(vmMor, connectAnchor);

        for(String dev : ethMap.keySet()){
                System.out.println("\n ######## dev = " + dev);
                System.out.println("\n ######## val = " + ethMap.get(dev));
        }

                for(String dev : ethMap.keySet()){
                        assertTrue(ethMap.get(dev).equals(opaqueNetworkInfo.get(0).
                                           getOpaqueNetworkId()),"The ethernet card is connected " +
                                           "to opaque network","The ethernet card is not " +
                                           "connected to the opaque network");
                }

                /*
                 * Check network connectivity
                 */

                assertTrue(vm.getIPAddress(vmMor) != null, "vm ip is not null", "vm ip is null");
                assertTrue(DVSUtil.checkNetworkConnectivity(hostSystem.
                                   getIPAddress(hostMor),vm.getIPAddress(vmMor)),
                                   "The vm is reachable","The vm is not reachable");

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
                    
                        /*
                         * Remove the vm snapshot
                         */
                        if (snapShot != null) {
                            assertTrue(snapShot.removeSnapshot(snapshotMor, true, true),
                                                    "Removed vm snapshot", "Failed to remove snapshot");
                        }
                    }
                } catch (Throwable t) {
                        t.printStackTrace();
                        cleanupWorked = false;
                        DVSUtil.testbedTeardown(connectAnchor, true);
                        vm.removeAllSnapshots(vmMor);
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
