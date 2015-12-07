package dvs.vmops.createvm;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_VMXNET;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_STALONE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_STALONE_PASS;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.vpxd.DvsVNicProfile;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;

/**
 * DESCRIPTION:<br>
 * TARGET: VC <br>
 * NOTE : PR#417980 <br>
 * <br>
 * SETUP:<br>
 * 
 * TEST:<br>
 * 1. Add a host to VC <br>
 * 2. Add host to vDS <br>
 * 3. Create a VM on this host and select DVSwitch as Network Adapter <br>
 * 4. Disconnect host and then remove host from VC <br>
 * 5. Add host back to VC <br>
 * 6. Remove vm mentioned in step-3 using right click -> remove from inventory
 * 7. Browse the datastore to .vmx file of this vm and right click and select
 * "add to Inventory" <br>
 * 
 * CLEANUP:<br>
 * 8. Destroy vDs<br>
 */

public class Pos025 extends TestBase {

	/**
	 * private data variables
	 */

	private HostSystem ihs = null;
	private HostConnectSpec hostCnxSpec = null;
	private VirtualMachine ivm = null;
	private Folder folder = null;
	private ManagedObjectReference hostMor = null;
	private boolean hostRemoved = false;
	private ManagedObjectReference hostFolderMor = null;
	protected ManagedEntity iManagedEntity = null;
	protected DistributedVirtualSwitchHelper dvsHelper = null;
	private DistributedVirtualSwitch iDVSwitch = null;
	protected DistributedVirtualPortgroup iDVPortgroup = null;
	private ManagedObjectReference dvsMor = null;
	private ManagedObjectReference vmMor = null;
	private ManagedObjectReference vmNewMor = null;
	private ManagedObjectReference vmFolderMor = null;
	private ManagedObjectReference resPool = null;
	private String vmPath = null;
	private String vmName = null;
	private String dvsName = null;


	/**
	 * Set test description.
	 */
	@Override
	public void setTestDescription() {
		setTestDescription("1.Add a host to VC"
				+ "2. Add host to vDS"
				+ "3. Create a VM on this host and select DVSwitch as Network Adapter"
				+ "4. Disconnect host and then remove host from VC"
				+ "5. Add host back to VC"
				+ "6. Remove vm mentioned in step-3 using right click -> remove from inventory"
				+ "7. Browse the datastore to .vmx file of this vm and right click and select add to Inventory");
	}

	/**
	 * Method to set up the Environment for the test.
	 * 
	 * @return Return true, if test set up was successful false, if test set up
	 *         was not successful
	 * @throws Exception
	 */

	@BeforeMethod(alwaysRun = true)
	public boolean testSetUp() throws Exception {

		boolean setupDone = true;
		this.ihs = new HostSystem(connectAnchor);
		this.ivm = new VirtualMachine(connectAnchor);
		this.folder = new Folder(connectAnchor);
		this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
		this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
		this.dvsHelper = new DistributedVirtualSwitchHelper(connectAnchor);
		hostMor = ihs.getStandaloneHost();
		hostFolderMor = ihs.getHostFolder(hostMor);
		this.hostCnxSpec = this.ihs.getHostConnectSpec(this.hostMor);

		/**
		 * Here the Host is simulated as such its getting added to VC for the
		 * first time
		 */

		log.info("Using host : " + hostCnxSpec.getHostName());
		log.info("Removing host from inventory... ");
		hostRemoved = this.ihs.destroy(this.hostMor);
		if (hostRemoved) {
			log.info("Adding host to inventory... ");
			hostMor = this.ihs.addStandaloneHost(hostFolderMor, hostCnxSpec,
					null, true);
		}

		/**
		 * Attach the host with the DVS after creating the switch
		 */

		dvsName=TestUtil.getShortTime()+ "_DVS";
		dvsMor = folder.createDistributedVirtualSwitch(dvsName);
		assertNotNull(dvsMor, "Failed to create the DVS switch "+dvsName);

		/**
		 *  Add freenics and host to DVS
		 */

		assertTrue(DVSUtil.addFreePnicAndHostToDVS(connectAnchor, hostMor,
				Arrays.asList(new ManagedObjectReference[] { dvsMor })),
				"Failed to attach freenics & host to DVS " +dvsName);

		String pgKey1 = this.dvsHelper.addPortGroup(dvsMor,
				DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING, 2, this
						.getTestId()
						+ "_early1");

		DistributedVirtualSwitchPortConnection portConnection = DVSUtil
				.buildDistributedVirtualSwitchPortConnection(this.dvsHelper
						.getConfig(this.dvsMor).getUuid(), null, pgKey1);

		/**
		 * Create a VM and attach it to DVS VM portgroup
		 */

		List<ManagedObjectReference> vms = DVSUtil
				.createVms(
						connectAnchor,
						this.hostMor,
						1,
						1,
						Arrays.asList(new DistributedVirtualSwitchPortConnection[] { portConnection }));
		assertNotNull(vms, " Failed to create VM");
		this.vmMor = vms.get(0);
		vmName = this.ivm.getVMName(this.vmMor);
		assertNotNull(vmMor, "Successfully created the VM " + vmName,
				"Failed to create VM " + vmName);
	
		return setupDone;
	}

	@Test(description = "This test is to address PR 417980")
	public void test() throws Exception {

		/**
		 * Test to disconnect the host from the VC and remove the host further
		 * readd the host
		 */
		assertTrue(this.ihs.disconnectHost(hostMor),
				"Successfully disconnected the Host from VC",
				"Host Disconnect Failed");
		if (this.ihs.destroy(hostMor)) {
			log.info("Successfully removed the host from VC");
			log.info("Adding the disconnected Standalone host back to the VC");
			hostMor = this.ihs.addStandaloneHost(hostFolderMor, hostCnxSpec,
					null, true);
			assertNotNull(hostMor, "Successfully added te host back to VC",
					"Failed to acc the host to VC");
		} else {
			log.error("Unable to remove the host from VC");
		}

		/**
		 * Unregister the VM created prior from the host
		 */

		Vector<ManagedObjectReference> allVmMors = this.ihs
				.getAllVirtualMachine(hostMor);
		for (ManagedObjectReference vmMor : allVmMors) {
			String tmpName = this.ivm.getVMName(vmMor);
			if (tmpName.equals(vmName)) {
				vmPath = this.ivm.getVMConfigInfo(vmMor).getFiles()
						.getVmPathName();
				vmFolderMor = this.ivm.getParentNode(vmMor);
				resPool = this.ivm.getResourcePool(vmMor);
				this.vmMor = vmMor;
				break;
			}
		}

		assertTrue(this.ivm.unregisterVM(vmMor),
				"VM got successfully unregistered", "VM failed to unregister");

		/**
		 * Register the VM once again accessing the .vmx file
		 */
		vmNewMor = new com.vmware.vcqa.vim.Folder(super.getConnectAnchor())
				.registerVm(vmFolderMor, vmPath, null, false, resPool, hostMor);
		if (vmNewMor != null) {
			log.info("Successfully registered the VM :"
					+ this.ivm.getVMName(vmNewMor));
		}

	}

	/**
	 * Method to restore the state, as it was, before setting up the test
	 * environment.
	 * 
	 * @return true, if test clean up was successful false, otherwise
	 * @throws Exception
	 */

	@AfterMethod(alwaysRun = true)
	public boolean testCleanUp() throws Exception {
		boolean cleanupDone = true;
		log.info("Successfully updated to existing network config");
		assertTrue(this.ivm.destroy(vmNewMor),
				"Deletion of the Virtual Machine Failed");
		log.info("Successfully deleted the VM "+ vmName);
		log.info("Deleting the DVS switch "+dvsName);
		assertTrue(this.iDVSwitch.destroy(dvsMor),
				"Deletion of DVS switch failed");
		return cleanupDone;
	}


}
