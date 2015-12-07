package dvs.rollback;

/*
 * ************************************************************************
 *
 * Copyright 2011 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

/**
 * @author kmokada
 *
 */

import static com.vmware.vcqa.TestConstants.VM_DEFAULT_GUEST_WINDOWS;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.csi.binding.vim.DistributedVirtualSwitch.ConfigSpec;
import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.EntityBackupConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.InvalidRequest;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.RollbackFailure;
import com.vmware.vc.SelectionSet;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchManager;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * The following setup will be used for BackupRestore tests However, the setup
 * will be modified as necessary later 1. Create 2 DVS (DVS1 and DVS2) 2. create
 * ephemeral port groups DVPG1 on DVS1 and DVPG2 on DVS2 3. create a VM with 2
 * vNics 4. Define DVPG1 as the backing for vNic1 and DVPG2 as the backing for
 * vNic2 5. Power on VM 6. Power OFF VM
 */
public class Neg001 extends TestBase {
	/*
	 * private data variables
	 */
	private HostSystem ihs = null;
	private Map allHosts = null;
	private ManagedObjectReference hostMor = null;
	private ManagedObjectReference vmMor = null;
	private VirtualMachine ivm = null;
	private String vmName = null;
	private Folder iFolder = null;
	private NetworkSystem ins = null;
	private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
	private boolean isVMCreated = false;
	private ManagedObjectReference nsMor = null;
	private Map<String, DVPortgroupConfigSpec> hmPgConfig = new HashMap<String, DVPortgroupConfigSpec>();
	private ManagedObjectReference dvsMor = null;
	SelectionSet[] selectionSet = new SelectionSet[1];
	SelectionSet[] dvs2SelectionSet = new SelectionSet[1];
	EntityBackupConfig[] Pos047VDSConfig = null;
	EntityBackupConfig[] DVS2Config = null;

	private Vector<ManagedObjectReference> dvsMorList = new Vector<ManagedObjectReference>(
			2);
	HostNetworkConfig originalNetworkConfig1 = null;
	HostNetworkConfig originalNetworkConfig2 = null;

	/**
	 * Sets the test description.
	 * 
	 * @param testDescription
	 *            the testDescription to set
	 */
	@Override
	public void setTestDescription() {
		super.setTestDescription("Verify rollback on DVS throws an exception when there was no previous config to return\n"
				+ " 1. Create 2 DVS (DVS1 and DVS2)\n"
				+ " 2. create ephemeral portgroups DVPG1 on DVS1 and DVPG2 on DVS2\n"
				+ " 3. create a VM with 2 vNics\n"
				+ " 4. Define DVPG1 as the backing for vNic1 and DVPG2 as the backing for vNic2\n"
				+ " 5. Power on VM\n" + " 6. Power OFF VM\n");
	}

	@Override
	@BeforeMethod(alwaysRun = true)
	public boolean testSetUp()

	{
		boolean status = false;
		Iterator it = null;
		VirtualMachineConfigSpec vmConfigSpec = null;
		String[] pnicIds = null;
		log.info("Test setup Begin:");
		try {

			iFolder = new Folder(connectAnchor);
			iDistributedVirtualSwitch = new DistributedVirtualSwitch(
					connectAnchor);
			ihs = new HostSystem(connectAnchor);
			ivm = new VirtualMachine(connectAnchor);
			ins = new NetworkSystem(connectAnchor);

			ihs = new HostSystem(connectAnchor);
			ivm = new VirtualMachine(connectAnchor);
			allHosts = ihs.getAllHosts(VersionConstants.ESX5x, HostSystemConnectionState.CONNECTED);
			int count = 1;
			if (allHosts != null) {
				it = allHosts.keySet().iterator();
				hostMor = (ManagedObjectReference) it.next();
				log.info("Found a host with free pnics in the inventory");
				nsMor = ins.getNetworkSystem(hostMor);
				if (nsMor != null) {
					pnicIds = ins.getPNicIds(hostMor);
					if (pnicIds != null) {
						vmName = getTestId() + "-vm" + count;
						vmConfigSpec = buildDefaultSpec(
								connectAnchor,
								hostMor,
								TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32,
								vmName, 1);
						vmMor = new Folder(super.getConnectAnchor()).createVM(
								ivm.getVMFolder(), vmConfigSpec,
								ihs.getPoolMor(hostMor), hostMor);
						if (vmMor != null) {
							isVMCreated = true;
							log.info("Successfully created the VM " + vmName);
						} else {
							log.error("Can not create the VM " + vmName);
						}
						if (vmMor != null) {
							status = ivm.setVMState(vmMor, VirtualMachinePowerState.POWERED_OFF, false);
						}
					} else {
						log.error("There are no free pnics on the host");
					}
				} else {
					log.error("The network system MOR is null");
				}
				count++;
			} else {
				log.error("Valid Host MOR not found");
				status = false;
			}

		} catch (Exception e) {
			TestUtil.handleException(e);
		}

		assertTrue(status, "Setup failed");
		return status;
	}

	/**
	 * Method that creates the DVS.
	 * 
	 * @param connectAnchor
	 *            ConnectAnchor object
	 */
	@Override
	@Test(description = "Verify rollback on DVS throws an exception when there was no previous config to return\n"
			+ " 1. Create a DVS\n"
			+ " 2. create a VM with 2 vNics\n"
			+ " 3. Call rollback on DVS with null as EntityBackup.Config parameter\n")
	public void test() throws Exception {
		try {
         ManagedObjectReference srcDVSMor = null;
         boolean status = false;
         DVSConfigSpec cs = null;
         log.info("Test Begin:");
         /* added by kmokada for backup restore */
         try {
         	String[] freePnics = ins.getPNicIds(hostMor);
         	if (freePnics != null && freePnics.length >= 2) {
         		srcDVSMor = migrateNetworkToDVS(hostMor, freePnics[0], "DVS1");
         		assertNotNull(srcDVSMor, "Successfully created the DVSwitch",
         				"Null returned for Distributed Virtual Switch MOR");
         		dvsMor = migrateNetworkToDVS(hostMor, freePnics[1], "DVS2");
         		assertNotNull(dvsMor, "Successfully created the DVSwitch",
         				"Null returned for Distributed Virtual Switch MOR");
         		dvsMorList.add(srcDVSMor);
         		dvsMorList.add(dvsMor);

         	} else {
         		log.error("Failed to get required(2) no of freePnics");
         	}
         } catch (Exception e) {
         	TestUtil.handleException(e);
         }
         cs = iDistributedVirtualSwitch.dvsRollback(dvsMor, null);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new RollbackFailure();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
	}

	/**
	 * Method to restore the state as it was before the test is started.
	 * 
	 * @param connectAnchor
	 *            ConnectAnchor object
	 */
	@Override
	@AfterMethod(alwaysRun = true)
	public boolean testCleanUp() throws Exception {
		boolean status = true;
		try {
			if (vmMor != null) {
				final Vector<ManagedObjectReference> allVMs = ivm.getAllVM();

				if (allVMs != null && !allVMs.isEmpty()) {

					for (int i = 0; i < allVMs.size(); i++) {
						final ManagedObjectReference currVmMor = allVMs.get(i);
						String pattern = getTestId() + "-vm";
						if (ivm.getName(currVmMor).contains(pattern)) {
							log.info("VM " + ivm.getName(currVmMor)
									+ "will be cleaned up");

							if (ivm.setVMState(currVmMor, VirtualMachinePowerState.POWERED_OFF, false)) {
								if (isVMCreated) {
									log.info("Destroying the created VM"
											+ ivm.getName(currVmMor));
									status &= ivm.destroy(currVmMor);
								}
							} else {
								log.error("Can not power off the VM"
										+ ivm.getName(currVmMor));
								status &= false;
							}
						}
					}
				}
			}
			if (dvsMorList != null && dvsMorList.size() > 0) {
				status &= iDistributedVirtualSwitch.destroy(dvsMorList);
			}

		} catch (Exception e) {
			TestUtil.handleException(e);
		}

		assertTrue(status, "Cleanup failed");
		return status;
	}

	/**
	 * Create a default VMConfigSpec.
	 * 
	 * @param connectAnchor
	 *            ConnectAnchor
	 * @param hostMor
	 *            The MOR of the host where the defaultVMSpec has to be created.
	 * @param deviceType
	 *            type of the device.
	 * @param vmName
	 *            String
	 * @return vmConfigSpec VirtualMachineConfigSpec.
	 * @throws MethodFault
	 *             , Exception
	 */
	public static VirtualMachineConfigSpec buildDefaultSpec(
			ConnectAnchor connectAnchor, ManagedObjectReference hostMor,
			String deviceType, String vmName, int noOfCards)
			throws Exception {
		ManagedObjectReference poolMor = null;
		VirtualMachineConfigSpec vmConfigSpec = null;
		HostSystem ihs = new HostSystem(connectAnchor);
		VirtualMachine ivm = new VirtualMachine(connectAnchor);
		Vector<String> deviceTypesVector = new Vector<String>();
		poolMor = ihs.getPoolMor(hostMor);
		if (poolMor != null) {

			deviceTypesVector.add(TestConstants.VM_VIRTUALDEVICE_DISK);
			deviceTypesVector.add(VM_VIRTUALDEVICE_SCSI_BUSL_CONTROLLER);
			for (int i = 0; i < noOfCards; i++) {
				deviceTypesVector
						.add(TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32);
			}
			deviceTypesVector.add(deviceType);
			// create the VMCfg with the default devices.
			vmConfigSpec = ivm.createVMConfigSpec(poolMor, vmName,
					VM_DEFAULT_GUEST_WINDOWS, deviceTypesVector, null);
		} else {
			log.error("Unable to get the resource pool from the host.");
		}
		return vmConfigSpec;
	}

	/*
	 * CreateDistributedVirtualSwitch with HostMemberPnicSpec
	 */

	private ManagedObjectReference migrateNetworkToDVS(
			ManagedObjectReference hostMor, String pnic, String vDsName)
			throws Exception {
		ManagedObjectReference nwSystemMor = null;
		ManagedObjectReference dvsMor = null;
		DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
		DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
		nwSystemMor = ins.getNetworkSystem(hostMor);
		hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
		hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
		hostMember.setHost(hostMor);
		pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
		DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
		pnicSpec.setPnicDevice(pnic);
		pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec()
				.addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
		hostMember.setBacking(pnicBacking);
		DVSConfigSpec dvsConfigSpec = new DVSConfigSpec();
		dvsConfigSpec.setConfigVersion("");
		dvsConfigSpec.setName(vDsName);
		dvsConfigSpec.setNumStandalonePorts(1);
		dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost()
				.addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
		dvsMor = iFolder.createDistributedVirtualSwitch(
				iFolder.getNetworkFolder(iFolder.getDataCenter()),
				dvsConfigSpec);
		if (dvsMor != null
				&& ins.refresh(nwSystemMor)
				&& iDistributedVirtualSwitch.validateDVSConfigSpec(dvsMor,
						dvsConfigSpec, null)) {
			log.info("Successfully created the distributed " + "virtual switch");

		} else {
			log.error("Unable to create DistributedVirtualSwitch");
		}
		return dvsMor;
	}

}
