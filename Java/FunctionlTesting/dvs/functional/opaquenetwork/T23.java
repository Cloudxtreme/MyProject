package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.io.File;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.OvfCreateDescriptorResult;
import com.vmware.vc.OvfCreateImportSpecParams;
import com.vmware.vc.OvfCreateImportSpecParamsDiskProvisioningType;
import com.vmware.vc.OvfCreateImportSpecResult;
import com.vmware.vc.OvfFile;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCardDistributedVirtualPortBackingInfo;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualMachineCloneSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachineFileInfo;
import com.vmware.vc.VirtualMachineMovePriority;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vc.VirtualMachineRelocateSpec;
import com.vmware.vc.vsm.DependencyInfo;
import com.vmware.vc.vsm.ProviderInfo;
import com.vmware.vc.vsm.VServiceManagerBindResult;
import com.vmware.vc.vsm.VServiceManagerQueryProvidersResult;
import com.vmware.vcqa.ServiceInfo;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VmHelper;
import com.vmware.vcqa.vim.ComputeResource;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.Datastore;
import com.vmware.vcqa.vim.DatastoreProperties;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.HttpConstants;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.OvfManager;
import com.vmware.vcqa.vim.ResourcePool;
import com.vmware.vcqa.vim.VirtualAppTestConstants;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.DatastoreSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;
import com.vmware.vcqa.vim.host.StorageConstants.DatastoreTypesEnum;
import com.vmware.vcqa.vim.host.VmotionSystem;
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;
import com.vmware.vcqa.vsm.VServiceManager;
import com.vmware.vcqa.vsm.VServiceManagerHelper;
import com.vmware.vcqa.vsm.VsmConstants;


/**
 * OVF Deployment
 *
 */

public class T23 extends TestBase
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
   private String destpgKey = null;
   private ManagedObjectReference dsMor = null;
   private ProvisioningOpsStorageHelper storageHelper = null;
   private ManagedObjectReference destHostMor = null;
   private ManagedObjectReference cloneVmMor = null;
   private ManagedObjectReference srcnsmor;
   private List<HostOpaqueNetworkInfo> opaqueNetworkInfo;
   private List<ManagedObjectReference> dvpgmorlist;
   private String dvpgkey;
   private OvfManager iovfManager;
   private ManagedObjectReference ovfManagerMor;
   private String vmName;
   private Datastore ds;
   private ManagedObjectReference poolMor;
   private String ovfDescriptor;
   private ResourcePool rp;
   private VServiceManager vsm;
   private VServiceManagerHelper vsmHelper;
   private ServiceInfo vsmServiceInfo;
   private ServiceInfo vcServiceInfo;

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
      assertNotNull(dcMor, "Found a valid datacenter in the inventory",
                    "Failed to find a datacenter in the inventory");
      storageHelper = new ProvisioningOpsStorageHelper(connectAnchor);
      iovfManager = new OvfManager(connectAnchor);
      ovfManagerMor = iovfManager.getOvfManager();
      ds = new Datastore(connectAnchor);
      rp = new ResourcePool(connectAnchor);
      vcServiceInfo = super
              .getServiceInfoList(TestConstants.VC_EXTENSION_KEY).get(0);
      /*vsmServiceInfo = super.getServiceInfoList(
              VsmConstants.VSM_EXTENSION_KEY).get(0);
      vsm = new VServiceManager(vsmServiceInfo);
      vsmServiceInfo = vsm.setVsmSessionCookie(vcServiceInfo);
      vsmHelper = new VServiceManagerHelper(vsmServiceInfo);*/
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
      this.hostMor = hostSystem.getAllHost().get(0);

      srcnsmor = nwSystem.getNetworkSystem(hostMor);
      opaqueNetworkInfo = nwSystem.
                                getNetworkInfo(srcnsmor).getOpaqueNetwork();
      assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
                         "The list of opaque networks is not null",
                         "The list of opaque networks is null");
          vmMor = hostSystem.getVMs
                              (hostMor, VirtualMachinePowerState.POWERED_OFF).get(0);

      return true;
   }

   /**
    * Export VM
    *
    * @throws Exception
    */
   private void exportOvf() throws Exception {
       OvfCreateDescriptorResult createDesRes;
       String exportLocation;
       if (System.getProperty(HttpConstants.PROP_OS_NAME).toUpperCase()
                       .equals(TestConstants.HOST_OS_WINDOWS)) {
               exportLocation = VirtualAppTestConstants.OVF_FILE_WIN_LOCATION;
               exportLocation += File.separator
                               + TestUtil.getTimeStampedTestId(getTestId())
                               + File.separator;
       } else {
               exportLocation = VirtualAppTestConstants.OVF_FILE_LINUX_LOCATION
                               + "/";
               exportLocation += "/" + TestUtil.getTimeStampedTestId(getTestId())
                               + "/";
       }

       List<OvfFile> ovfFiles = vm.exportVM(vmMor, true, exportLocation);
       Assert.assertNotNull(ovfFiles, "Failed to export the VM");
       createDesRes = iovfManager.createDescriptor(ovfManagerMor, vmMor,
                       ovfFiles);
       ovfDescriptor = createDesRes.getOvfDescriptor();
   }


   /**
    * Import OVF files
    *
    * @throws Exception
    */
   private void importVM() throws Exception {
       List<DependencyInfo> dependencies;
       String entityKey;
       ManagedObjectReference vmFolderMor = vm.getVMFolder();
       ManagedObjectReference hostMor = hostSystem.getStandaloneHost();
       assertNotNull(vmFolderMor, "Not able to obtain vmfolder");
       OvfCreateImportSpecParams importSpecParams = new OvfCreateImportSpecParams();
       importSpecParams.setEntityName(vmName);
       importSpecParams.setHostSystem(hostMor);
       importSpecParams
                       .setDiskProvisioning(OvfCreateImportSpecParamsDiskProvisioningType.THIN
                                       .value());
       DatastoreProperties dsProperties = new DatastoreProperties();
       dsProperties.setIsShared(true);
       Vector<ManagedObjectReference> hosts = new Vector<ManagedObjectReference>();
       hosts.add(hostMor);
       List<ManagedObjectReference> dataStores = ds.getDatastores(hosts,
                       dsProperties);
       OvfCreateImportSpecResult importSpecRes = iovfManager.createImportSpec(
                       ovfManagerMor, ovfDescriptor, poolMor, dataStores.get(0),
                       importSpecParams);
       vmMor = rp.importVApp(importSpecRes, poolMor, hostMor, vmFolderMor,
                       ovfDescriptor);
   }

   protected void bindDependencytoProvider(String entityKey,
           String dependencyId) throws Exception {
           ProviderInfo provider;
           List<VServiceManagerQueryProvidersResult> compatibleProvidersList = vsm
                           .queryCompatibleProviders(entityKey, dependencyId);
           provider = compatibleProvidersList.get(0).getProviderInfo();
           VServiceManagerBindResult bindResult = this.vsm.bind(entityKey,
                           dependencyId, provider.getEntityKey(), provider.getId());
           Assert.assertNotNull(bindResult,
                           "Null bindResult returned by the bind API");
           Assert.assertTrue(
                           vsmHelper.verifyBind(entityKey, dependencyId,
                                           provider.getEntityKey(), provider.getId(), bindResult),
                           "Bind dependency verification succeeded",
                           "Bind dependency verification failed");
   }

   protected VirtualMachineConfigSpec createVMConfigSpec(
                   ManagedObjectReference hostMor, String vmName,
                   ManagedObjectReference poolMor) throws Exception {
       VirtualMachineConfigSpec vmConfigSpec;
       List<ManagedObjectReference> allDatastores;
       DatastoreProperties properties = new DatastoreProperties();
       properties.setIsShared(true);
       properties.setType(DatastoreTypesEnum.VMFS);
       allDatastores = ds.getDatastores(hostMor, properties);
       VirtualMachineFileInfo fileInfo = new VirtualMachineFileInfo();
       String vmPathName = "["
                       + this.ds.getDatastoreInfo(allDatastores.get(0)).getName()
                       + "]";
       fileInfo.setVmPathName(vmPathName);
       vmConfigSpec = vm.createVMConfigSpec(poolMor, hostMor, vmName,
                       TestConstants.VM_DEFAULT_GUEST_LINUX, null, null);
       vmConfigSpec.setFiles(fileInfo);
       vmConfigSpec.setMemoryMB((long) 100);
       return vmConfigSpec;
   }

   @Test
   public void test()
      throws Exception
   {
           poolMor = hostSystem.getResourcePool(hostMor).get(0);
           vmName = "vm" + getTestId() + TestUtil.getRandomAlphaNumericString(3);
           VirtualMachineConfigSpec vmConfig = this.createVMConfigSpec(hostMor, vmName, poolMor);
           exportOvf();
           importVM();
   }

   @AfterMethod
   public boolean testCleanUp()
      throws Exception
   {
                boolean cleanupWorked = true;
                try {
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
