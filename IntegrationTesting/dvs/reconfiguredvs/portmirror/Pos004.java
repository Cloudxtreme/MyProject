package dvs.reconfiguredvs.portmirror;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.MultiMap;
import com.vmware.vcqa.vim.dvs.VspanHelper;

public class Pos004 extends PortMirrorTestBase {
	VMwareVspanSession[] existingSessions;

	final String sessionTpye = "remoteMirrorSource";
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
		getProperties();// read the configuration from XML file.
		hostMor = hs.getConnectedHost(null);
		assertNotNull(hostMor, HOST_GET_FAIL);
		dvsMor = createDVSWithNic(dvsName, hostMor);
		setupPortgroups(dvsMor); // "portGroups" variant is ready.
		setupVMs(dvsMor);
		VMwareDVSVspanConfigSpec m_newSpecs = VspanHelper
				.getRawVMwareDVSVspanConfigSpec(sessionTpye);
		assertTrue(this.setVspanPorts(m_newSpecs, portGroups),
				"error occured when setup mirror ports");
		m_newSpecs.getVspanSession().setName(this.getTestId());
		m_newSpecs.getVspanSession().setSessionType(sessionTpye);
		/*
		 * For remoteMirrorSoure type, encapsulationVlanid is needed.
		 */
		m_newSpecs.getVspanSession().setEncapsulationVlanId(1);
		m_newSpecs.setOperation(TestConstants.CONFIG_SPEC_ADD);
		vspanConfigSpecs[0] = m_newSpecs;
		assertTrue(this.reconfigureVspan(dvsMor, vspanConfigSpecs, false),
				"Failed to ADD Vspan sessions");
		return true;
	}

	@Test(description = "Test session type is \"remoteMirrorSource\"")
	@Override
	public void test() throws Exception {
		VMwareVspanSession[] sessions = com.vmware.vcqa.util.TestUtil
				.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class);
		VMwareDVSVspanConfigSpec target = null;
		for (int j = 0; j < sessions.length; j++) {
			final VMwareVspanSession aSession = sessions[j];
			if (aSession.getName().equals(this.getTestId())) {
				log.info("found target session {}", aSession.getName());
				log.info("begin to change session ({}) fields' value", aSession
						.getKey());
				target = buildVspanCfg(aSession, CONFIG_SPEC_EDIT);
			}
		}
		if (target != null) {
			target.getVspanSession().setEnabled(this.enabled);
			target.getVspanSession().setNormalTrafficAllowed(
					this.normalTrafficAllowed);
			target.getVspanSession().setMirroredPacketLength(
					this.mirrorPacketLength);
			target.getVspanSession().setSamplingRate(this.samplingRate);
			target.getVspanSession().setEncapsulationVlanId(
					this.encapsulationVlanId);
			target.getVspanSession().setStripOriginalVlan(
					this.stripOriginalVlan);
		} else {
			assertTrue(false, "fail to search session object!");
		}
		vspanConfigSpecs[0] = target;
		assertTrue(this.reconfigureVspan(dvsMor, vspanConfigSpecs, true),
				"Error happened when edit session content");
	}

	@AfterMethod(alwaysRun = true)
	@Override
	public boolean testCleanUp() throws Exception {
		boolean done = true;
		done &= cleanupVMs();
		log.info("Destroying the DVS: {} ", dvsName);
		done &= this.destroy(dvsMor);
		return done;
	}

	protected void getProperties() {
		normalTrafficAllowed = data.getBoolean(NORMAL_TRAFFIC_ALLOWED);
		enabled = data.getBoolean(ENABLED);
		mirrorPacketLength = data.getInt(MIRROR_PKT_LENGTH);
		samplingRate = data.getInt(SAMPLINGRATE);
		stripOriginalVlan = data.getBoolean(STRIP_ORIGINAL_VLAN);
		encapsulationVlanId = data.getInt(ENCALSULATION_VLANID);
		log.info(">>> Finish the data read >>> ");
	}

	/**
	 * set the portkeys.
	 */
	protected boolean setVspanPorts(VMwareDVSVspanConfigSpec m_cfg,
			final MultiMap<String, String> pg) {
		final Collection<String> keys = pg.keySet();
		if (keys.size() < 3) {
			log
					.error("Don't have enough ports to do the dvPortMirror session type testing");
			return false;
		}
		Iterator<String> m_i;
		m_i = keys.iterator();
		String pgName = m_i.next();
		/* set the rx ports */
		List<String> l = pg.get(pgName);
		String[] srcrxports = new String[l.size()];
		l.toArray(srcrxports);
		usedPortKeys.addAll(l);
		m_cfg.getVspanSession().getSourcePortReceived().getPortKey().clear();
      m_cfg.getVspanSession().getSourcePortReceived().getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(srcrxports));
		/* set the tx ports */
		pgName = m_i.next();
		l = pg.get(pgName);
		usedPortKeys.addAll(l);
		String[] srctxports = new String[l.size()];
		l.toArray(srctxports);
		m_cfg.getVspanSession().getSourcePortTransmitted().getPortKey().clear();
      m_cfg.getVspanSession().getSourcePortTransmitted().getPortKey().addAll(
				com.vmware.vcqa.util.TestUtil.arrayToVector(srctxports));
		m_cfg.getVspanSession().getDestinationPort().getUplinkPortName().clear();
      /*
		 * set the dst ports, for remoteMirrorSource type, the uplink alias
		 * should be used
		 */
		m_cfg.getVspanSession().getDestinationPort().getUplinkPortName().addAll(
				com.vmware.vcqa.util.TestUtil.arrayToVector(uplinksName));
		return true;
	}
}
