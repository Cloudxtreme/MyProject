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
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.NoPermission;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.MultiMap;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.dvs.VspanHelper;

public class Neg013 extends PortMirrorTestBase {

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
		return true;
	}

	@Test(description = "Test useless fields in srcrx/srctx/dst port item with correct value.")
	@Override
	public void test() throws Exception {
		try {
         VMwareDVSVspanConfigSpec[] vspanConfigSpecs = new VMwareDVSVspanConfigSpec[1];
         VMwareDVSVspanConfigSpec m_newSpecs = VspanHelper
         		.getRawVMwareDVSVspanConfigSpec(this.sessionType);
         assertTrue(this.setVspanPorts(m_newSpecs, portGroups),
         		"error occured when setup mirror ports");
         m_newSpecs.getVspanSession().setName(this.getTestId());
         m_newSpecs.getVspanSession().setSessionType(this.sessionType);
         m_newSpecs.getVspanSession().setEncapsulationVlanId(1);
         m_newSpecs.setOperation(CONFIG_SPEC_ADD);
         vspanConfigSpecs[0] = m_newSpecs;
         this.reconfigureVspan(dvsMor, vspanConfigSpecs, false);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new InvalidArgument();
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
	}

	@AfterMethod(alwaysRun = true)
	@Override
	public boolean testCleanUp() throws Exception {
		boolean done = true;
		log.info("Destroying the DVS: {} ", dvsName);
		done &= this.destroy(dvsMor);
		return done;
	}

	protected void getProperties() {
		dstIP = data.getString(DST_IP);
		vlanId = data.getInt(VLANID);
		this.sessionType = data.getString(SESSION_TYPE);
		log.debug(">>>>>>>> Got dstIP value {}", dstIP);
		log.debug(">>>>>>>> Got vlanId value {}", vlanId);
	}

	protected boolean setVspanPorts(VMwareDVSVspanConfigSpec m_cfg,
			final MultiMap<String, String> pg) {

		if (this.dstIP != null) {
			// test IP address field
			String[] tmp = dstIP.split("-");
			m_cfg.getVspanSession().getSourcePortReceived().getIpAddress().clear();
         m_cfg.getVspanSession().getSourcePortReceived().getIpAddress().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(tmp));
			m_cfg.getVspanSession().getSourcePortTransmitted().getIpAddress().clear();
         m_cfg.getVspanSession().getSourcePortTransmitted().getIpAddress()
					.addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(tmp));
			m_cfg.getVspanSession().getDestinationPort().getIpAddress().clear();
         m_cfg.getVspanSession().getDestinationPort().getIpAddress().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(tmp));

		} else if (vlanId > 0) {
			// test vlanId field
			Integer[] tmpVlans = new Integer[1];
			tmpVlans[0] = vlanId;
			m_cfg.getVspanSession().getSourcePortReceived().getVlans().clear();
         m_cfg.getVspanSession().getSourcePortReceived().getVlans().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(tmpVlans));
			m_cfg.getVspanSession().getSourcePortTransmitted().getVlans().clear();
         m_cfg.getVspanSession().getSourcePortTransmitted().getVlans().addAll(
					com.vmware.vcqa.util.TestUtil.arrayToVector(tmpVlans));
			m_cfg.getVspanSession().getDestinationPort().getVlans().clear();
         m_cfg.getVspanSession().getDestinationPort().getVlans().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(tmpVlans));
		} else {
			m_cfg.getVspanSession().getSourcePortReceived().getUplinkPortName().clear();
         // test uplinkport field uplinksName
			m_cfg.getVspanSession().getSourcePortReceived().getUplinkPortName().addAll(
					com.vmware.vcqa.util.TestUtil.arrayToVector(uplinksName));
			m_cfg.getVspanSession().getSourcePortTransmitted().getUplinkPortName().clear();
         m_cfg.getVspanSession().getSourcePortTransmitted().getUplinkPortName()
					.addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinksName));
		}
		return true;
	}
}
