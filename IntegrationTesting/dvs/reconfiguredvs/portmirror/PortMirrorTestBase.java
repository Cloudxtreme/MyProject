package dvs.reconfiguredvs.portmirror;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.*;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchHostMember;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.HostDVSPortData;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.UserSession;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vc.VirtualMachineConfigSpec;

import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.InternalServiceInstance;
import com.vmware.vcqa.internal.vim.dvs.InternalHostDistributedVirtualSwitchManager;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.MultiMap;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.MessageConstants;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.dvs.VspanHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * This class is the base class for all the PortMirror test scripts. It contains
 * all the interfaces which is used for PortMirror testing.
 */
public abstract class PortMirrorTestBase extends TestBase {
	protected ManagedObjectReference dvsMor;
	protected ManagedObjectReference netFolderMor;
	protected ManagedEntity me;
	protected Folder folder;
	protected HostSystem hs;
	protected NetworkSystem ns;
	protected VirtualMachine vm;
	protected DistributedVirtualSwitchHelper vmwareDvs;
	protected DistributedVirtualPortgroup dvpg;
	protected DVPortgroupConfigSpec dvPortgroupConfigSpec;
	protected VMwareDVSConfigSpec dvsCfg;// Used to create DVS.
	protected VMwareDVSConfigSpec dvsReCfg;// Used for reconfiguring the DVS.
	protected String dvsName;// Defaults to test case ID.
	protected ManagedObjectReference hostMor;
	protected int portsInDvpg = 2;// defaults to 2 if not given in data file.
	protected String sessionType = null;
	protected final Map<ManagedObjectReference, VirtualMachineConfigSpec> vms;
	protected ArrayList<String> usedPortKeys;
	protected String[] uplinksName; // DVS's uplink name
	/**
	 * Contains DVPortGroups and ports in the format<br>
	 * portGroup-1= {port-1, port-2} <br>
	 * portGroup-2= {port-1, port-2} <br>
	 * This MultiMap will be populated on calling {@link #setupPortgroups()}<br>
	 * => Keyset is a collection of DVPortgroups & values are a List of DVPorts.<br>
	 */
	@SuppressWarnings("deprecation")
	protected final MultiMap<String, String> portGroups;
	/** Contains only the uplink portGroup(s) and it's ports */
	@SuppressWarnings("deprecation")
	protected final MultiMap<String, String> uplinkPortgroups;

	/* Data file properties */
	static final String NORMAL_TRAFFIC_ALLOWED = "normal-traffic-allowed";
	static final String STRIP_ORIGINAL_VLAN = "stripOriginalVlan";
	static final String ENABLED = "enabled";
	static final String ENCALSULATION_VLANID = "encapsulationVlanId";
	static final String MIRROR_PKT_LENGTH = "mirrorPacketLength";
	static final String SAMPLINGRATE = "samplingRate";
	static final String PORTS_IN_DVPG = "ports-in-dvpg";
	static final String SESSION_TYPE = "sessionType";
	static final String SRCRX_VLANS = "rxvlan";
	static final String DST_IP = "dstip";
	static final String VLANID = "vlanid";
	static final String SESSION_KEY = "sessionKey";
	static final String INVALIDPORTKEY = "invalidPortKey";

	/* Properties from data file */
	protected String[] srcTxWc;
	protected String[] srcRxWc;
	protected boolean normalTrafficAllowed;
	protected boolean stripOriginalVlan;
	protected boolean enabled;
	protected int encapsulationVlanId;
	protected int mirrorPacketLength;
	protected int samplingRate;
	protected String srcRxVlan;
	protected String dstIP;
	protected int vlanId;
	protected String sessionKey;
	protected String invalidPortKey;

	private DVSConfigInfo dvsCfgInfo;// Holds the DVS info.

	/**
	 * Constructor.
	 */
	public PortMirrorTestBase() {
		// dvsName = getTestName() + "-dvs";
		portGroups = new MultiMap<String, String>();
		uplinkPortgroups = new MultiMap<String, String>();
		vms = new HashMap<ManagedObjectReference, VirtualMachineConfigSpec>();
		usedPortKeys = new ArrayList<String>();
	}

	/**
	 * Get the testid
	 *
	 * @return string contains the test id.
	 */
	public String getTestName() {
		return getTestId();
	}

	/**
	 * Initialize the members.<br>
	 *
	 * @throws Exception
	 */
	protected void initialize() throws Exception {
		folder = new Folder(connectAnchor);
		vm = new VirtualMachine(connectAnchor);
		hs = new HostSystem(connectAnchor);
		ns = new NetworkSystem(connectAnchor);
		vmwareDvs = new DistributedVirtualSwitchHelper(connectAnchor);
		dvpg = new DistributedVirtualPortgroup(connectAnchor);
		dvsName = getTestName();
	}

	/**
	 * Create a DVS by adding a free NIC of the host.<br>
	 *
	 * @param name
	 *            Name of the DVS.
	 * @param hostMor
	 *            Host to be added to DVS with pNIC.
	 * @return MOR of created DVS.
	 * @throws Exception
	 */
	public ManagedObjectReference createDVSWithNic(final String name,
			final ManagedObjectReference hostMor) throws Exception {
		final ManagedObjectReference newDvsMor;
		final Map<ManagedObjectReference, String> pNics;
		dvsCfg = new VMwareDVSConfigSpec();
		dvsCfg.setName(name);
		netFolderMor = folder.getNetworkFolder(folder.getDataCenter());
		Assert.assertNotNull(netFolderMor, "Can't find the folder for testing!");
		pNics = new HashMap<ManagedObjectReference, String>();
		final String[] freePnics = ns.getPNicIds(hostMor, false);
		Assert.assertNotEmpty(freePnics, "No free nics found in host.");
		pNics.put(hostMor, freePnics[0]);
		dvsCfg = (VMwareDVSConfigSpec) DVSUtil.addHostsToDVSConfigSpecWithPnic(
				dvsCfg, pNics, getTestId());// FIXME Casting
		newDvsMor = folder.createDistributedVirtualSwitch(netFolderMor, dvsCfg);
		Assert.assertNotNull(newDvsMor, "Can't create new DVS for testing!");
		dvsCfgInfo = vmwareDvs.getConfig(newDvsMor);
		DVSNameArrayUplinkPortPolicy uplinkPortPolicy = (DVSNameArrayUplinkPortPolicy) dvsCfgInfo
				.getUplinkPortPolicy();
		uplinksName = com.vmware.vcqa.util.TestUtil.vectorToArray(uplinkPortPolicy.getUplinkPortName(), java.lang.String.class);
		log.info(">>>uplink name is {}>>>", uplinksName);
		log.info("Created DVS {}", dvsCfgInfo.getName());
		return newDvsMor;
	}

	/**
	 * Create the port groups and populate the MultiMaps for further use.
	 *
	 * @param dvsMor
	 *            DVS MOR
	 * @return void
	 */
	protected void setupPortgroups(final ManagedObjectReference dvsMor)
			throws Exception {
		DistributedVirtualSwitchPortCriteria criteria;
		// need at least 3 port groups.
		final String[] pgTypes = { DVPORTGROUP_TYPE_EARLY_BINDING,
				DVPORTGROUP_TYPE_LATE_BINDING, DVPORTGROUP_TYPE_LATE_BINDING };
		for (int i = 0; i < pgTypes.length; i++) {
			final String pgName = getTestId() + "-pg-" + i + "-" + pgTypes[i];
			log.debug("Adding DVPG: {} with '{}' ports", pgName, portsInDvpg);
			final String pgKey = vmwareDvs.addPortGroup(dvsMor, pgTypes[i],
					portsInDvpg, pgName);
			criteria = vmwareDvs.getPortCriteria(null, null, null,
					new String[] { pgKey }, null, true);
			final List<String> ports = vmwareDvs
					.fetchPortKeys(dvsMor, criteria);
			Assert.assertNotEmpty(ports, "No ports in PG: " + pgName);
			log.info("Added PG {} with ports {}", pgKey, ports);
			portGroups.put(pgKey, ports);
		}
	}

	/**
	 * Destroy given DVS.
	 *
	 * @param mor
	 *            MOR of the entity to be destroyed.
	 * @return boolean true, if destroyed. otherwise false.
	 */
	boolean destroy(final ManagedObjectReference mor) {
		boolean status = false;
		if (mor != null) {
			try {
				status = vmwareDvs.destroy(mor);
			} catch (final Exception e) {
				log.error("Failed to destroy the DVS", e);
			}
		} else {
			log.info("Given MOR is null");
			status = true;
		}
		return status;
	}

	/**
	 * Method to reconfigure the VSPAN session on given DVS
	 *
	 * @param dvsMor
	 *            ManagedObjectReference object
	 * @param vspanCfg
	 *            VMwareDVSVspanConfigSpec object
	 * @param check
	 *            whether check the cfg on ESX host and VPXD
	 * @return boolean true if successful false otherwise
	 * @throws MethodFault
	 *             , Exception
	 */
	boolean reconfigureVspan(final ManagedObjectReference dvsMor,
			final VMwareDVSVspanConfigSpec[] vspanCfg, final boolean check)
			throws Exception {
		boolean verify = true;
		ManagedObjectReference hostMor = null;
		log.info("Reconfiguring VSPAN session of DVS: {} ", dvsName);
		final VMwareDVSConfigInfo info = vmwareDvs.getConfig(dvsMor);
		VMwareVspanSession[] sessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil
				.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
		final VMwareDVSConfigSpec vmwareDvsCfg = new VMwareDVSConfigSpec();
		vmwareDvsCfg.setConfigVersion(info.getConfigVersion());
		vmwareDvsCfg.getVspanConfigSpec().clear();
      vmwareDvsCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
		assertTrue(vmwareDvs.reconfigure(dvsMor, vmwareDvsCfg),
				"Failed to reconfigure VSPAN session");
		log.info("Reconfigured VSPAN successfully.");
		if (check == true) {
			log.info("Get current config & compute expected config...");
			final List<VMwareVspanSession> expected = vmwareDvs
					.mergeVspansCfgs(sessions, vspanCfg);
			// now get the current config.
			sessions = com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class);
			verify = vmwareDvs.verifyVspan((sessions == null ? null : Arrays
					.asList(sessions)), expected);
			DistributedVirtualSwitchHostMember[] hostMembers = com.vmware.vcqa.util.TestUtil.vectorToArray(info.getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
			if (sessions != null && hostMembers != null
					&& hostMembers.length > 0) {
				for (DistributedVirtualSwitchHostMember hostMember : hostMembers) {
					hostMor = hostMember.getConfig().getHost();
					if (hostMor != null) {
						verify &= verifyVspanSessionOnPorts(connectAnchor,
								hostMor, info.getUuid(), com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(
                              		dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class), usedPortKeys);
					} else {
						log.warn("hostMor is null on DistributedVirtual"
								+ "SwitchHostMember config. Skipping "
								+ "VMwareVspanSession verfication host");
					}
				}

			} else {
				log.warn("VMwareVspanSession or "
						+ "DistributedVirtualSwitchHostMember is null on VC. "
						+ "Skipping VMwareVspanSession verfication host");
			}
		}
		return verify;
	}

	/**
	 * This method verifies that the actual verify VspanSessionOnHost retrieved
	 * is equal to the expected verifyVspanSession on host's port
	 *
	 * @param connectAnchor
	 * @param hostMor
	 * @param vdsUuid
	 * @param expectedLldpInfo
	 * @return true - if the actual verifyVspanSessionOnHost returned is equal
	 *         to the expected value, false otherwise
	 * @throws Exception
	 */
	private boolean verifyVspanSessionOnPorts(ConnectAnchor connectAnchor,
			ManagedObjectReference hostMor, String vdsUuid,
			VMwareVspanSession[] expectedVspanSessions,
			ArrayList<String> portKeys) throws Exception {
		assertNotNull(connectAnchor, "The connect anchor is null");
		assertNotNull(hostMor, "The host Mor is null");
		boolean verify;
		ArrayList<Integer> matchCount = new ArrayList<Integer>();
		int matched = 0;
		VMwareVspanSession vspanSessions[];

		HostSystem hostSystem = new HostSystem(connectAnchor);
		UserSession hostLoginSession = null;
		ConnectAnchor hostConnectAnchor = new ConnectAnchor(hostSystem
				.getHostName(hostMor), connectAnchor.getPort());
		SessionManager sessionManager = new SessionManager(hostConnectAnchor);
		ManagedObjectReference sessionMgrMor = sessionManager
				.getSessionManager();
		hostLoginSession = new SessionManager(hostConnectAnchor).login(
				sessionMgrMor, TestConstants.ESX_USERNAME,
				TestConstants.ESX_PASSWORD, null);
		Assert.assertNotNull(hostLoginSession, "Cannot login into the host");
		InternalHostDistributedVirtualSwitchManager hdvs = new InternalHostDistributedVirtualSwitchManager(
				hostConnectAnchor);
		InternalServiceInstance msi = new InternalServiceInstance(
				hostConnectAnchor);
		ManagedObjectReference hostDVSMgrMor = msi
				.getInternalServiceInstanceContent()
				.getHostDistributedVirtualSwitchManager();
		String[] s = new String[portKeys.size()];
		usedPortKeys.toArray(s);
		HostDVSPortData[] hd = hdvs.fetchPortState(hostDVSMgrMor, vdsUuid, s,
				null);
		// For each expected session, it must be hit at least one time.
		// In MN.next, if one port has no relationship with the session,
		// vpxd will not push the session to that port.
		for (VMwareVspanSession expectedVspanSession : expectedVspanSessions) {
			log.info("Name of VMwareVspanSession on VC :"
					+ expectedVspanSession.getName());
			matched = 0;
			for (HostDVSPortData hdpd : hd) {
				vspanSessions = com.vmware.vcqa.util.TestUtil.vectorToArray(hdpd.getVspanConfig(), com.vmware.vc.VMwareVspanSession.class);
				if (null != vspanSessions) {
					for (VMwareVspanSession vspanSession : vspanSessions) {
						if (expectedVspanSession.getName().equalsIgnoreCase(
								vspanSession.getName())) {
							log.info("Found matching VMwareVspanSession{} "
									+ "on port {}.", vspanSession.getName(),
									hdpd.getPortKey());
							Vector<String> ignorePropList = VspanHelper.getIgnoredField(expectedVspanSession
									.getSessionType());
							ignorePropList.addAll(TestUtil
									.getIgnorePropertyList(
											expectedVspanSession, false));
							assertTrue(TestUtil.compareObject(vspanSession,
									expectedVspanSession, ignorePropList),
									"Successfully verified VspanSession for :"
											+ expectedVspanSession.getName(),
									"Verification failed for  VspanSession :"
											+ expectedVspanSession.getName());
							matched++;
							break;
						}
					}
				}
			}
			log.info("Found matched session {} on {} ports:",
					expectedVspanSession.getName(), matched);
			matchCount.add(new Integer(matched));
		}
		verify = true;
		Iterator<Integer> i = matchCount.iterator();
		while (i.hasNext()) {
			Integer tmp = (Integer) i.next();
			// at least match one time.
			if (tmp.longValue() < 1) {
				verify = false;
			}
		}
		return verify;
	}

	/**
	 * Get VMs from a host member of DVS.
	 * Connect them to the DVPorts of DVS.
	 * Need 3 VMs in PortMirror testing and 2 vNICs on each VM.
	 */
	public void setupVMs(final ManagedObjectReference aDvsMor) throws Exception {
		final DistributedVirtualSwitchHostMember[] hostMember;
		final ManagedObjectReference dvsHostMor;
		final Vector<ManagedObjectReference> hostVms;
		hostMember = com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(aDvsMor).getHost(), com.vmware.vc.DistributedVirtualSwitchHostMember.class);
		assertNotEmpty(hostMember, "No hosts connected to DVS");
		dvsHostMor = hostMember[0].getConfig().getHost();
		hostVms = hs.getAllVirtualMachine(dvsHostMor);
		Assert.assertNotEmpty(hostVms, MessageConstants.VM_GET_FAIL);
		Assert.assertTrue(hostVms.size() >= portGroups.size(),
				"Less number of VM's found than number of PG's");
		log.info("Got '{}' VM's in host {}", hostVms.size(), hostMor);
		assertTrue(vm.powerOnVMs(hostVms, false),
				MessageConstants.VM_POWERON_FAIL);
		final Iterator<String> iter = portGroups.keySet().iterator();
		int count = 0;
		while (iter.hasNext()) {
			final String pgKey = iter.next();
			final DistributedVirtualSwitchPortConnection[] conns;
			final VirtualMachineConfigSpec[] vmCfgs;
			final List<String> ports = portGroups.get(pgKey);// get the first
			log.info("Ports: {}", ports);
			final ManagedObjectReference aVmMor = hostVms.get(count);
			conns = new DistributedVirtualSwitchPortConnection[ports.size()];
			for (int j = 0; j < ports.size(); j++) {
				conns[j] = new DistributedVirtualSwitchPortConnection();
				conns[j].setPortKey(ports.get(j));
				conns[j].setPortgroupKey(pgKey);
				conns[j].setSwitchUuid(dvsCfgInfo.getUuid());
			}
			log.debug("Created {} DVPort Connections.", conns.length);
			vmCfgs = DVSUtil.getVMConfigSpecForDVSPort(aVmMor, connectAnchor,
					conns);
			assertNotEmpty(vmCfgs, "Failed to get Recfg spec for VM " + aVmMor);
			log.debug("Reconfiguring the VM to connect to DVS...");
			assertTrue(vm.reconfigVM(aVmMor, vmCfgs[0]),
					"Failed to reconfig VM");
			log.debug("Reconfigured VM '{}' to use DVS.", aVmMor);
			vms.put(aVmMor, vmCfgs[1]);
			count++;
		}
	}

	/**
	 * Restore the VMs to previous network Configuration.
	 *
	 * @return true if the VM cleaned, else return false.
	 */
	public boolean cleanupVMs() {
		boolean result = true;
		for (int i = 0; i < vms.size(); i++) {
			final Iterator<ManagedObjectReference> specs = vms.keySet()
					.iterator();
			while (specs.hasNext()) {
				try {
					final ManagedObjectReference aVmMor = specs.next();
					log.info("Restoring '{}' to original Cfg.", aVmMor);
					result &= vm.reconfigVM(aVmMor, vms.get(aVmMor));
				} catch (final Exception e) {
					log.error("Failed to restore VM to original Cfg", e);
					result = false;
				}
			}
		}
		return result;
	}

	/**
	 * Method to construct the VMwareDVSVspanConfigSpec from given values.
	 *
	 * @param vspanSession
	 *            the VMwareVspanSession.
	 * @param operation
	 *            Operation.
	 * @return VMwareDVSVspanConfigSpec.
	 */
	public static final VMwareDVSVspanConfigSpec buildVspanCfg(
			final VMwareVspanSession vspanSession, final String operation) {
		final VMwareDVSVspanConfigSpec vspanCfg = new VMwareDVSVspanConfigSpec();
		vspanCfg.setVspanSession(vspanSession);
		vspanCfg.setOperation(operation);
		return vspanCfg;
	}

	/**
	 * Abstract function which should be implements in sub class in order to set
	 * the portkeys correctly.
	 *
	 * @param m_cfg
	 *            DVS configSpec object.
	 * @param pg
	 *            MultiMap object which contained portgroup info.
	 * @return trun if successfule, false if failed.
	 */
	abstract protected boolean setVspanPorts(VMwareDVSVspanConfigSpec m_cfg,
			final MultiMap<String, String> pg);

	/**
	 * Get the properties from XML file.
	 */
	abstract protected void getProperties();

}
