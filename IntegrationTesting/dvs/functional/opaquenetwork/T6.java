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
import com.vmware.vcqa.vim.provisioning.ProvisioningOpsStorageHelper;

public class T6 extends TestBase{

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
	private ManagedObjectReference srcVmMor = null;
	private ManagedObjectReference destVmMor = null;
	private VirtualMachineConfigSpec srcOrigVMConfigSpec = null;
	private VirtualMachineConfigSpec destOrigVMConfigSpec = null;

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
		List<HostOpaqueNetworkInfo> opaqueNetworkInfo = ins.
				getNetworkInfo(nsMor).getOpaqueNetwork();
		assertTrue(opaqueNetworkInfo != null && opaqueNetworkInfo.size() > 0,
		          "The list of opaque networks is not null",
		          "The list of opaque networks is null");
		/*
		 * Get two vms on the host
		 */
        srcVmMor = hostSystem.getVMs
	    		  (hostMor, VirtualMachinePowerState.POWERED_OFF).get(0);
        destVmMor = hostSystem.getVMs
	    		  (hostMor, VirtualMachinePowerState.POWERED_OFF).get(1);
		Map<String,String> srcVmEthernetMap = NetworkUtil.
				getEthernetCardNetworkMap(srcVmMor, connectAnchor);
		Map<String,String> destVmEthernetMap = NetworkUtil.
				getEthernetCardNetworkMap(destVmMor, connectAnchor);
        Set<String> srcEthernetCardDevicesSet = srcVmEthernetMap.keySet();
        Set<String> destEthernetCardDevicesSet = destVmEthernetMap.keySet();
        /*
         * Compute a new ethernet card network map
         */
        Map<String,HostOpaqueNetworkInfo> ethernetCardNetworkMap = new
        		HashMap<String,HostOpaqueNetworkInfo>();
		for(String ethernetCard : srcEthernetCardDevicesSet){
			ethernetCardNetworkMap.put(ethernetCard, opaqueNetworkInfo.get(0));
		}
        /*
         * Reconfigure the virtual machine to connect to opaque network
         */
		this.srcOrigVMConfigSpec = NetworkUtil.
				               reconfigureVMConnectToOpaqueNetwork(srcVmMor,
				               ethernetCardNetworkMap, connectAnchor);
		/*
		 * Clear the ethernet card network map
		 */
		ethernetCardNetworkMap.clear();
		/*
		 *  Compute a new ethernet card network map for destination vm
		 */
	    for(String ethernetCard : destEthernetCardDevicesSet){
	    	ethernetCardNetworkMap.put(ethernetCard, opaqueNetworkInfo.get(0));
	    }
	    /*
	     * Reconfigure the destination vm to connect to opaque network
	     */
	    this.destOrigVMConfigSpec = NetworkUtil.
	               reconfigureVMConnectToOpaqueNetwork(destVmMor,
	               ethernetCardNetworkMap, connectAnchor);
        return true;
	}

	@Test
	public void test() throws Exception {
		/*
		 * Power on the vms
		 */
		assertTrue(vm.setVMState(srcVmMor, VirtualMachinePowerState.POWERED_ON,
				true),"Successfully powered on the source virtual machine",
				"Failed to power on the source virtual machine");
		assertTrue(vm.setVMState(destVmMor, VirtualMachinePowerState.POWERED_ON,
				true),"Successfully powered on the destination virtual machine",
				"Failed to power on the destination virtual machine");
		/*
		 * Check network connectivity
		 */
		assertTrue(vm.getIPAddress(srcVmMor) != null, "src vm ip is not null", "src vm ip is null");
		assertTrue(vm.getIPAddress(destVmMor) != null, "dest vm ip is not null", "dest vm ip is null");
		assertTrue(DVSUtil.checkNetworkConnectivity(vm.getIPAddress(srcVmMor),
				   vm.getIPAddress(destVmMor)),"The vm is reachable",
				   "The vm is not reachable");
	}

	@AfterMethod
	public boolean testCleanUp() throws Exception {
		boolean cleanupWorked = true;
		try {
			if(srcVmMor != null && destVmMor != null){
				/*
				 * Power off the vms
				 */
				assertTrue(vm.setVMState(srcVmMor,
						  VirtualMachinePowerState.POWERED_OFF,
						  false),"Successfully powered off the source virtual " +
						  "machine","Failed to power off the source vm");
				assertTrue(vm.setVMState(destVmMor,
						  VirtualMachinePowerState.POWERED_OFF,
						  false),"Successfully powered off the dest virtual " +
						  "machine","Failed to power off the dest vm");
				/*
				 * Restore the vm configuration
				 */
				assertTrue(vm.reconfigVM(srcVmMor, srcOrigVMConfigSpec),
						   "Reconfigured the source vm to its original settings",
						   "Failed to reconfigure the source vm to its original " +
						   "settings");
				assertTrue(vm.reconfigVM(destVmMor, destOrigVMConfigSpec),
						   "Reconfigured the destination vm to its original " +
						   "settings",
						   "Failed to reconfigure the destination vm to its " +
						   "original settings");
			}
		} catch (Throwable t) {
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
		assertTrue(cleanupWorked, "Cleanup Succeeded !", "Cleanup Failed !");
		return true;
	}
}
