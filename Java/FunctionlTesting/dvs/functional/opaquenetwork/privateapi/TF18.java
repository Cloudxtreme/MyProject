package dvs.functional.opaquenetwork.privateapi;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Random;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.BoolPolicy;
import com.vmware.vc.DvsHostInfrastructureTrafficResource;
import com.vmware.vc.DvsHostInfrastructureTrafficResourceAllocation;
import com.vmware.vc.HostDVSConfigSpec;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostOpaqueSwitch;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicOpaqueNetworkSpec;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.KeyValue;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.SharesInfo;
import com.vmware.vc.SharesLevel;
import com.vmware.vc.StringPolicy;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSPortSetting;
import com.vmware.vc.VMwareUplinkLacpPolicy;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardResourceAllocation;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.VmHelper;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;

public class TF18 extends TestBase{

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
        private NetworkSystem ns = null;
        private NetworkSystem ins = null;
        private ManagedObjectReference nsMor = null;
        private ManagedObjectReference vmMor = null;
        private VirtualMachineConfigSpec[] existingVMConfigSpecs = null;
        private HostVirtualNicSpec hostVNicSpec;
        private InternalHostDistributedVirtualSwitchManager hdvsManager;
        private ManagedObjectReference hostDVSMgrMor = null;
        private InternalServiceInstance msi;
        private String UUIDHS1;
        private String vNicKey;
        private HostVirtualNicSpec originalHostVirtualNicSpec;
        private boolean vmkNic;
        private ConnectAnchor hostConnectAnchor;
        private SessionManager sessionManager;
        private ManagedObjectReference sessionMgrMor;
        private UserSession hostLoginSession;
        private ManagedObjectReference datastoreSystemMor;
        private ManagedObjectReference datastore = null;
        List<HostVirtualNic> vniclist1;
        List<HostVirtualNic> vniclist2;

        public List<HostOpaqueSwitch> GetOpaqueSwitches()
                throws Exception
     {
         NetworkSystem networkSystem = new NetworkSystem(connectAnchor);
         HostNetworkInfo hostNetworkInfo = networkSystem.getNetworkInfo(nsMor);
         return hostNetworkInfo.getOpaqueSwitch();
     }
        
        
        public void initialize() throws Exception {
                folder  = new Folder(connectAnchor);
                hostSystem = new HostSystem(connectAnchor);
                vmHelper = new VmHelper(connectAnchor);
                dc = new Datacenter(connectAnchor);
                vm = new VirtualMachine(connectAnchor);
                nwSystem = new NetworkSystem(connectAnchor);
                dataStoreSystem = new DatastoreSystem(connectAnchor);
                storageHelper = new ProvisioningOpsStorageHelper(connectAnchor);
                ns = new NetworkSystem(connectAnchor);
                hostMor = hostSystem.getConnectedHost(null);

                String hostIP = hostSystem.getIPAddress(hostMor);
                hdvsManager = new InternalHostDistributedVirtualSwitchManager(
                                connectAnchor);
                msi = new InternalServiceInstance(connectAnchor);
                hostDVSMgrMor = msi.getInternalServiceInstanceContent().
                                getHostDistributedVirtualSwitchManager();
                nsMor = ns.getNetworkSystem(hostMor);
        }


        @BeforeMethod
        public boolean testSetUp() throws Exception {
            /*
             * Init code for all entities in the inventory
             */

            initialize();
            try {
                    DVSUtil.startNsxa(connectAnchor,"root", "ca$hc0w", "vmnic1");
            } catch (Throwable e) {
                    // TODO Auto-generated catch block
                    e.printStackTrace();
                    return false;
            }

            /*
             * Query for the opaque network
             */
            List<HostOpaqueNetworkInfo> opaqueNetworkInfo = ns.
                            getNetworkInfo(nsMor).getOpaqueNetwork();
            assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                      "The list of opaque networks is not null",
                      "The list of opaque networks is null");

            hostVNicSpec = buildOpaqueHostVnicSpec
                            (ns.getNetworkInfo(nsMor).getOpaqueNetwork().get(0));
            HostVirtualNic hostVirtualNic = ns.getVirtualNic
                            (nsMor, "Management Network", true);
            originalHostVirtualNicSpec = hostVirtualNic.getSpec();
            vniclist1 = GetOpaqueSwitches().get(0).getVtep();
            return true;
        }

        @Test
        public void test() throws Exception {
            vmkNic = ns.updateVirtualNic(this.nsMor, "vmk0", hostVNicSpec);
            dataStoreSystem = new DatastoreSystem(connectAnchor);
            datastoreSystemMor = dataStoreSystem.getDatastoreSystem(hostMor);
            datastore = dataStoreSystem.addNasVol("/fvt-1/vimapi_vms/bpei/", "10.115.160.201",
                            "vimapi_vms", datastoreSystemMor);
        }

        public HostVirtualNicSpec buildOpaqueHostVnicSpec
                (HostOpaqueNetworkInfo valOpaqueNetworkInfo)
                           throws Exception
        {

           HostVirtualNicOpaqueNetworkSpec opaqueNetworkSpec
                                           = new HostVirtualNicOpaqueNetworkSpec();
           opaqueNetworkSpec.setOpaqueNetworkId
                                   (valOpaqueNetworkInfo.getOpaqueNetworkId());
           opaqueNetworkSpec.setOpaqueNetworkType
                                   (valOpaqueNetworkInfo.getOpaqueNetworkType());

           HostIpConfig ipConfig = new HostIpConfig();
           ipConfig.setDhcp(true);

           HostVirtualNicSpec hostVirtualNicSpec = new HostVirtualNicSpec();
           hostVirtualNicSpec.setOpaqueNetwork(opaqueNetworkSpec);
           hostVirtualNicSpec.setIp(ipConfig);
           
           vniclist2 = GetOpaqueSwitches().get(0).getVtep();
           
           log.info("vniclist1:" + vniclist1);
           log.info("vniclist2:" + vniclist2);

           return hostVirtualNicSpec;
        }

        @AfterMethod
        public boolean testCleanUp() throws Exception {
            boolean cleanupWorked = true;
            try {
                  if (datastore != null) {
                      dataStoreSystem.removeDatastore
                       (datastoreSystemMor, datastore, true);
                  }
                    if (vmkNic) {
                          if (originalHostVirtualNicSpec != null) {
                                  ns.updateVirtualNic(nsMor,
                                                    "vmk0",
                                                    originalHostVirtualNicSpec);
                          }
                  }
            } catch (Throwable t) {
                    t.printStackTrace();
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
