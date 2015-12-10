package dvs.reconfiguredvs.portmirror;


import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Factory;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import com.vmware.vc.DvsOperationBulkFault;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.MultiMap;
import com.vmware.vcqa.vim.dvs.VspanHelper;

public class Neg002 extends PortMirrorTestBase {

	@Factory
	@Parameters( { "dataFile" })
	public Object[] getTests(@Optional("") final String dataFile)
			throws Exception {
		return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
	}

	final String sessionTpye = "encapsulatedRemoteMirrorSource";

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

	@Test(description = "Test negative IPv4/IPv6 address (10.0/2011:1).")
	@Override
	public void test() throws Exception {
		try {
         VMwareDVSVspanConfigSpec[] vspanConfigSpecs = new VMwareDVSVspanConfigSpec[1];
         VMwareDVSVspanConfigSpec m_newSpecs = VspanHelper
         		.getRawVMwareDVSVspanConfigSpec(sessionTpye);
         assertTrue(this.setVspanPorts(m_newSpecs, portGroups),
         		"error occured when setup mirror ports");
         m_newSpecs.getVspanSession().setName(this.getTestId());
         String[] dstIPs = new String[1];
         dstIPs[0] = this.dstIP;
         m_newSpecs.getVspanSession().getDestinationPort().getIpAddress().clear();
         m_newSpecs.getVspanSession().getDestinationPort().getIpAddress().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(dstIPs));
         m_newSpecs.getVspanSession().setSessionType(sessionTpye);
         m_newSpecs.setOperation(TestConstants.CONFIG_SPEC_ADD);
         vspanConfigSpecs[0] = m_newSpecs;
         this.reconfigureVspan(dvsMor, vspanConfigSpecs, true);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         boolean result1 = false;
         boolean result2 = false;
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         /* with different data set, the exception type is different */
         com.vmware.vc.MethodFault expectedMethodFault1 = new DvsOperationBulkFault();
         com.vmware.vc.MethodFault expectedMethodFault2 = new InvalidArgument();
         result1 = com.vmware.vcqa.util.TestUtil.checkMethodFault(
                  actualMethodFault, expectedMethodFault1);
         result2 = com.vmware.vcqa.util.TestUtil.checkMethodFault(
                  actualMethodFault, expectedMethodFault2);
         if (result1 == false && result2 == false) {
            com.vmware.vcqa.util.Assert.assertTrue(false,
                     "MethodFault mismatch!");
         }
      }
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
		dstIP = data.getString(DST_IP);
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
		m_i = keys.iterator();
		pgName = m_i.next();
		/* set the rx ports */
		l = pg.get(pgName);
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
