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

public class Pos007 extends PortMirrorTestBase {
	VMwareVspanSession[] existingSessions;
	final String sessionTpye = "encapsulatedRemoteMirrorSource";

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
		return true;
	}

	@Test(description = "Test session type is \"encapsulatedRemoteMirrorSource\"")
	@Override
	public void test() throws Exception {
		String[] dstIPs = dstIP.split("-");
		VMwareDVSVspanConfigSpec[] vspanConfigSpecs = new VMwareDVSVspanConfigSpec[1];
		VMwareDVSVspanConfigSpec m_newSpecs = VspanHelper
				.getRawVMwareDVSVspanConfigSpec(sessionTpye);
		assertTrue(this.setVspanPorts(m_newSpecs, portGroups),
				"error occured when setup mirror ports");
		m_newSpecs.getVspanSession().setName(this.getTestId());
		m_newSpecs.getVspanSession().setEnabled(this.enabled);
		m_newSpecs.getVspanSession().setMirroredPacketLength(
				this.mirrorPacketLength);
		m_newSpecs.getVspanSession().setSamplingRate(this.samplingRate);
		m_newSpecs.getVspanSession().setSessionType(sessionTpye);
		m_newSpecs.getVspanSession().getDestinationPort().getIpAddress().clear();
      m_newSpecs.getVspanSession().getDestinationPort().getIpAddress().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(dstIPs));
		m_newSpecs.setOperation(TestConstants.CONFIG_SPEC_ADD);
		vspanConfigSpecs[0] = m_newSpecs;
		assertTrue(this.reconfigureVspan(dvsMor, vspanConfigSpecs, true),
				"Failed to ADD Vspan sessions");
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
		enabled = data.getBoolean(ENABLED);
		mirrorPacketLength = data.getInt(MIRROR_PKT_LENGTH);
		dstIP = data.getString(DST_IP);
		samplingRate = data.getInt(SAMPLINGRATE);
		log.info(">>> Finish the data read >>> ");
	}

	/**
	 * set the portkeys.
	 */
	protected boolean setVspanPorts(VMwareDVSVspanConfigSpec m_cfg,
			final MultiMap<String, String> pg) {
		final Collection<String> keys = pg.keySet();
		if (keys.size() < 3) {
			log.error("Don't have enough ports to do the dvPortMirror testing");
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
		return true;
	}
}
