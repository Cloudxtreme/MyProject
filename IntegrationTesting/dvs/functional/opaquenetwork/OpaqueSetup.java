package dvs.functional.opaquenetwork;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostOpaqueNetworkInfo;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualEthernetCardNetworkBackingInfo;
import com.vmware.vc.VirtualEthernetCardOpaqueNetworkBackingInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
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

public class OpaqueSetup extends TestBase{

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
        initialize();

        try {
            DVSUtil.startNsxa(connectAnchor, "root", "ca$hc0w");
        } catch (Throwable e) {
            // TODO Auto-generated catch block
            e.printStackTrace();
            return false;
        }

         return true;
    }

    public void test() throws Exception {


    }

    @AfterMethod
    public boolean testCleanUp() throws Exception {
        return true;
    }

}
