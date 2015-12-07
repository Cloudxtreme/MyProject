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

public class Sec004 extends PortMirrorTestBase {
	private AuthorizationHelper authHelper;
	private final String testUser = GENERIC_USER;

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
		// Login with Test user with "DVSwitch.Vspan" privilege.
		authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
				data.getString(TESTINPUT_USERNAME), data
						.getString(TESTINPUT_PASSWORD));
		authHelper.setPermissions(dvsMor, DVSWITCH_VSPAN, testUser, false);
		return authHelper.performSecurityTestsSetup(testUser);
	}

	@Test(description = "Test without DVSwitch.vspan privilege and add new session.")
	@Override
	public void test() throws Exception {
		try {
			VMwareDVSVspanConfigSpec[] vspanConfigSpecs = new VMwareDVSVspanConfigSpec[1];
			VMwareDVSVspanConfigSpec m_newSpecs = VspanHelper
					.getRawVMwareDVSVspanConfigSpec(this.sessionType);
			m_newSpecs.getVspanSession().setName(this.getTestId());
			m_newSpecs.getVspanSession().setSessionType(this.sessionType);
			m_newSpecs.setOperation(CONFIG_SPEC_ADD);
			vspanConfigSpecs[0] = m_newSpecs;
			this.reconfigureVspan(dvsMor, vspanConfigSpecs, false);
			com.vmware.vcqa.util.Assert.assertTrue(false,
					"No Exception Thrown!");
		} catch (Exception excep) {
			com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil
					.getFault(excep);
			com.vmware.vc.MethodFault expectedMethodFault = new NoPermission();
			/* specify the expect privilege is DVSwitch.Vspan */
			((NoPermission) expectedMethodFault)
					.setPrivilegeId("DVSwitch.Vspan");
			/*
			 * the object is a runtime value, so set the actual value to expect
			 * object
			 */
			((NoPermission) expectedMethodFault)
					.setObject(((NoPermission) actualMethodFault).getObject());
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
		if (authHelper != null) {
			done &= authHelper.performSecurityTestsCleanup();
		}
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
		return true;
	}
}
