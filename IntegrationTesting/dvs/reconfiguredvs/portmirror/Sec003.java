package dvs.reconfiguredvs.portmirror;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;
import static com.vmware.vcqa.vim.PrivilegeConstants.DVSWITCH_VSPAN;
import java.util.*;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;
import com.vmware.vc.NoPermission;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.MultiMap;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.dvs.VspanHelper;

public class Sec003 extends PortMirrorTestBase {
	private AuthorizationHelper authHelper;
	private final String testUser = GENERIC_USER;
	VMwareDVSVspanConfigSpec[] vspanConfigSpecs = new VMwareDVSVspanConfigSpec[1];

	@Factory
	@Parameters( { "dataFile" })
	public Object[] getTests(@Optional("") final String dataFile)
			throws Exception {
		return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
	}

	@BeforeMethod(alwaysRun = true)
	@Override
	public boolean testSetUp() throws Exception {
		initialize();
		getProperties();
		hostMor = hs.getConnectedHost(null);
		assertNotNull(hostMor, HOST_GET_FAIL);
		dvsMor = createDVSWithNic(dvsName, hostMor);
		setupPortgroups(dvsMor); // "portGroups" variant is ready.
		setupVMs(dvsMor);
		// Add a new session with use - administrator
		VMwareDVSVspanConfigSpec m_newSpecs = VspanHelper
				.getRawVMwareDVSVspanConfigSpec(this.sessionType);
		m_newSpecs.getVspanSession().setName(this.getTestId());
		m_newSpecs.getVspanSession().setSessionType(this.sessionType);
		m_newSpecs.setOperation(CONFIG_SPEC_ADD);
		assertTrue(this.setVspanPorts(m_newSpecs, portGroups),
				"error occured when setup mirror ports");
		vspanConfigSpecs[0] = m_newSpecs;
		assertTrue(this.reconfigureVspan(dvsMor, vspanConfigSpecs, false),
				"Failed to ADD Vspan sessions");
		// Login with Test user with "DVSwitch.Vspan" privilege.
		authHelper = new AuthorizationHelper(connectAnchor, getTestId(), data
				.getString(TESTINPUT_USERNAME), data
				.getString(TESTINPUT_PASSWORD));
		authHelper.setPermissions(dvsMor, DVSWITCH_VSPAN, testUser, false);
		return authHelper.performSecurityTestsSetup(testUser);
	}

	@Test(description = "Test DVSwitch.vspan privilege and delete new session.")
	@Override
	public void test() throws Exception {
		VMwareVspanSession[] sessions = com.vmware.vcqa.util.TestUtil
				.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class);
		VMwareDVSVspanConfigSpec target = null;
		for (int j = 0; j < sessions.length; j++) {
			final VMwareVspanSession aSession = sessions[j];
			if (aSession.getName().equals(this.getTestId())) {
				log.info("found target session {}", aSession.getName());
				target = buildVspanCfg(aSession, CONFIG_SPEC_REMOVE);
			}
		}
		if (target != null) {
			assertTrue(this.reconfigureVspan(dvsMor, vspanConfigSpecs, true),
					"Failed to delete Vspan sessions");
		} else {
			assertTrue(false, "Can't find the target session");
		}
	}

	@AfterMethod(alwaysRun = true)
	@Override
	public boolean testCleanUp() throws Exception {
		boolean done = true;
		if (authHelper != null) {
			done &= authHelper.performSecurityTestsCleanup();
		}
		done &= cleanupVMs();
		log.info("Destroying the DVS: {} ", dvsName);
		done &= this.destroy(dvsMor);
		return done;
	}

	protected void getProperties() {
		sessionType = data.getString(SESSION_TYPE);
	}

	/**
	 * set the portkeys partially according different session type.
	 */
	protected boolean setVspanPorts(VMwareDVSVspanConfigSpec m_cfg,
			final MultiMap<String, String> pg) {

		final Collection<String> keys = pg.keySet();
		List<String> l = null;
		String pgName = null;
		Iterator<String> m_i = keys.iterator();
		if (keys.size() < 3) {
			log.error("Don't have enough ports to do the PortMirror testing");
			return false;
		}
		if (this.sessionType.equals("dvPortMirror")
				|| this.sessionType.equals("encapsulatedRemoteMirrorSource")) {
			pgName = m_i.next();
			/* set the rx ports */
			l = pg.get(pgName);
			String[] srcrxports = new String[l.size()];
			l.toArray(srcrxports);
			usedPortKeys.addAll(l);
			m_cfg.getVspanSession().getSourcePortReceived().getPortKey().clear();
         m_cfg.getVspanSession().getSourcePortReceived().getPortKey().addAll(
					com.vmware.vcqa.util.TestUtil.arrayToVector(srcrxports));
		}
		if (this.sessionType.equals("remoteMirrorSource")) {
			m_cfg.getVspanSession().getDestinationPort().getUplinkPortName().clear();
         /*
			 * set the dst ports, for remoteMirrorSource type, the uplink alias
			 * should be used
			 */
			m_cfg.getVspanSession().getDestinationPort().getUplinkPortName().addAll(
					com.vmware.vcqa.util.TestUtil.arrayToVector(uplinksName));
		}
		if (this.sessionType.equals("remoteMirrorDest")) {
			/* set the dst ports */
			pgName = m_i.next();
			l = pg.get(pgName);
			usedPortKeys.addAll(l);
			String[] dstports = new String[l.size()];
			l.toArray(dstports);
			m_cfg.getVspanSession().getDestinationPort().getPortKey().clear();
         m_cfg.getVspanSession().getDestinationPort().getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(dstports));
		}
		return true;
	}
}
