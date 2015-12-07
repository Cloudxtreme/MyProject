package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DvsHostInfrastructureTrafficResource;
import com.vmware.vc.DvsHostInfrastructureTrafficResourceAllocation;
import com.vmware.vc.HostDVSConfigSpec;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SharesInfo;
import com.vmware.vc.SharesLevel;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardResourceAllocation;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.VmHelper;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;

public class T1 extends TestBase{

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
        private ManagedObjectReference nsMor = null;
        private ManagedObjectReference vmMor = null;
        private VirtualMachineConfigSpec[] existingVMConfigSpecs = null;



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
                hostMor = hostSystem.getConnectedHost(null);
        }


        @BeforeMethod
        public boolean testSetUp() throws Exception {
                /*
                 * Init code for all entities in the inventory
                 */

                log.info("\n\n ######### log dir = " + System.getenv("ZOO_LOG_DIR")  + "   \n\n");

                initialize();
                try {
                        DVSUtil.startNsxa(connectAnchor,"root", "ca$hc0w", "vmnic1");
                        existingVMConfigSpecs = DVSUtil.testbedSetup(connectAnchor);
                } catch (Throwable e) {
                        // TODO Auto-generated catch block
                        e.printStackTrace();
                }

                /*
                 * Query for the opaque network
                 */
                nsMor = ins.getNetworkSystem(hostMor);
                List<HostOpaqueNetworkInfo> opaqueNetworkInfo = ins.
                                getNetworkInfo(nsMor).getOpaqueNetwork();
                assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                          "The list of opaque networks is not null",
                          "The list of opaque networks is null");

                 //EnableNetiocV3();

                /*
                 *  Create a default vm spec
                 */
                VirtualMachineConfigSpec vmConfigSpec = DVSUtil.
                                buildDefaultSpec(connectAnchor,
                                                hostSystem.getResourcePool(hostMor).get(0),
                                                TestConstants.VM_VIRTUALDEVICE_ETHERNET_VMXNET3,
                                                "Sample-vm-T1", 1);
                List<VirtualDeviceConfigSpec> deviceSpecList =
                                vmConfigSpec.getDeviceChange();
                for(VirtualDeviceConfigSpec spec : deviceSpecList){
                        VirtualDevice device = spec.getDevice();
                        if(device instanceof VirtualEthernetCard){
                                VirtualEthernetCard vEthernetDevice =
                                                (VirtualEthernetCard)device;
                                 VirtualEthernetCardOpaqueNetworkBackingInfo opaqueNetworkBackingInfo
                                        = NetworkUtil.createOpaqueNetworkBackingInfo(
                                                        opaqueNetworkInfo.get(0).getOpaqueNetworkId(),
                                                        opaqueNetworkInfo.get(0).getOpaqueNetworkType());
                                vEthernetDevice.setBacking(opaqueNetworkBackingInfo);

                                VirtualEthernetCardResourceAllocation virtEthernetCardResAlloc
                                = new VirtualEthernetCardResourceAllocation();
                                virtEthernetCardResAlloc.setLimit(20L);
                                virtEthernetCardResAlloc.setReservation(10L);
                                SharesInfo sharesInfo = new SharesInfo();
                                sharesInfo.setShares(50);
                                sharesInfo.setLevel(SharesLevel.NORMAL);
                                virtEthernetCardResAlloc.setShare(sharesInfo );
                                vEthernetDevice.setResourceAllocation(virtEthernetCardResAlloc);
                        }
                }
                /*
                 * Create the vm in this step
                 */
                 vmMor = folder.createVM(vm.getVMFolder(),
                                 vmConfigSpec, hostSystem.getResourcePool(hostMor).get(0),
                                 hostMor);
                 return true;
        }

        @Test
        public void test() throws Exception {
                /*
                 * Power on the vm
                 */
                assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_ON,
                                false),"Successfully powered on the virtual machine",
                                "Failed to power on the virtual machine");


        }

        @AfterMethod
        public boolean testCleanUp() throws Exception {
                boolean cleanupWorked = true;
                try {
                        if(vmMor != null){
                                /*
                                 * Power off the vm
                                 */
                                assertTrue(vm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF,
                                                false),"Successfully powered on the virtual machine",
                                                "Failed to power on the virtual machine");
                                /*
                                 * Destroy the vm
                                 */
                                vm.destroy(vmMor);
                        }
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

           public HostDVSConfigSpec makeDvsReconfigureSpec() {

                   HostDVSConfigSpec reconfigSpec = new HostDVSConfigSpec();

                return reconfigSpec;

           }

           public boolean EnableNetiocV3() throws Exception {
                   boolean result;
                   InternalHostDistributedVirtualSwitchManager hdvsManager = new
                                   InternalHostDistributedVirtualSwitchManager(
                       connectAnchor);
                   HostDVSConfigSpec reconfigSpec  = makeDvsReconfigureSpec();
                   ManagedObjectReference hostDVSMgrMor =
                           hdvsManager.getHostDvsManager(connectAnchor);
                   String UUIDHS1 = ins.
                   getNetworkInfo(nsMor).getProxySwitch().get(0).getDvsUuid();
                   reconfigSpec.setUuid(UUIDHS1);
                   reconfigSpec.setEnableNetworkResourceManagement(true);
                   result = hdvsManager.reconfigureDistributedVirtualSwitch(
                                   hostDVSMgrMor, reconfigSpec);

                   reconfigSpec  = makeDvsReconfigureSpec();
                   reconfigSpec.setUuid(UUIDHS1);
                   List<DvsHostInfrastructureTrafficResource>
                       listHostInfraTrafficResource
                   = new ArrayList<DvsHostInfrastructureTrafficResource>();

                   List<String> listPoolKeys = new ArrayList<String>();
                   reconfigSpec.setNetworkResourceControlVersion("version3");

                   String[] pools = {"virtualMachine",
                                                        "nfs",
                                                        "management",
                                                        "iSCSI",
                                                        "vmotion",
                                                        "faultTolerance",
                                                        "vdp",
                                                        "hbr",
                                                        "vsan"};

                   String[] resPools = {"netsched.pools.persist.vm",
                                        "netsched.pools.persist.nfs",
                                        "netsched.pools.persist.mgmt",
                                        "netsched.pools.persist.isci",
                                        "netsched.pools.persist.vmotion",
                                        "netsched.pools.persist.ft",
                                        "netsched.pools.persist.vdp",
                                        "netsched.pools.persist.hbr",
                                        "netsched.pools.persist.vsan"};

                   int index = 0;
                   for (String pool : pools) {
                           DvsHostInfrastructureTrafficResource
                               dvsHostInfrastructureTrafficResource = new
                                        DvsHostInfrastructureTrafficResource();
                           dvsHostInfrastructureTrafficResource.setKey(pool);
                           DvsHostInfrastructureTrafficResourceAllocation
                              dvsHostInfraTraffResAlloc = new
                              DvsHostInfrastructureTrafficResourceAllocation();
                           dvsHostInfraTraffResAlloc.setLimit(200L);
                           dvsHostInfraTraffResAlloc.setReservation(50L);
                           SharesInfo sharesInfo = new SharesInfo();
                           sharesInfo.setShares(50);
                           sharesInfo.setLevel(SharesLevel.NORMAL);
                           dvsHostInfraTraffResAlloc.setShares(sharesInfo );
                           dvsHostInfrastructureTrafficResource.
                               setAllocationInfo(dvsHostInfraTraffResAlloc);
                           listHostInfraTrafficResource.
                               add(dvsHostInfrastructureTrafficResource);
                           listPoolKeys.add(resPools[index]);
                           index++;
                   }

                   result = hdvsManager.reconfigureDistributedVirtualSwitch
                           (hostDVSMgrMor, reconfigSpec);

                   reconfigSpec  = makeDvsReconfigureSpec();
                   reconfigSpec.setUuid(UUIDHS1);
                   reconfigSpec.setHostInfrastructureTrafficResource
                                           (listHostInfraTrafficResource);
                   reconfigSpec.setNetworkResourcePoolKeys(listPoolKeys);
                   List<String> uplinks = new ArrayList<String>();
                   uplinks.add("Uplink 1");
                   //reconfigSpec.setUplinkPortKey(uplinks );
                   result = hdvsManager.reconfigureDistributedVirtualSwitch
                           (hostDVSMgrMor, reconfigSpec);
                   if (result) {
                      log.info("DVS Updated");
                   }

                   return result;
           }

}
