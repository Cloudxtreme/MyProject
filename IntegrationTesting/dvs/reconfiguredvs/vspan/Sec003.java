/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.PrivilegeConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Remove a VSPAN session in DVS by a user having "DVSwitch.Vspan" privilege.<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS.<br>
 * 2. Add a VSPAN session.<br>
 * 3. Login with Test user with "DVSwitch.Vspan" privilege.<br>
 * <br>
 * TEST:<br>
 * 4. Reconfigure the DVS to REMOVE the VSPAN session successfully.<br>
 * CLEANUP:<br>
 * 5. Destroy the DVS.<br>
 */
public class Sec003 extends VspanTestBase
{
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;
   VMwareVspanSession[] existingSessions;
   VMwareDVSConfigInfo info;

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      dvsMor = folder.createDistributedVirtualSwitch(dvsName);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               null, null, null));
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      log.info("Adding session:{}",
               VspanHelper.toString(vspanCfg[0].getVspanSession()));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to Add VSPAN session.");
      info = vmwareDvs.getConfig(dvsMor);
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "Added VSPAN not found!");
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(),
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_VSPAN, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Test(description = "REMOVE a VSPAN session in DVS by a user having"
            + " \"DVSwitch.Vspan\" privilege.")
   @Override
   public void test()
      throws Exception
   {
      VMwareDVSVspanConfigSpec[] recfgSpec = null;
      recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
      for (int i = 0; i < existingSessions.length; i++) {
         final VMwareVspanSession aSession = existingSessions[i];
         log.info("Existing Session: {} : {}", i,
                  VspanHelper.toString(aSession));
         recfgSpec[i] = VspanHelper.buildVspanCfg(aSession, CONFIG_SPEC_REMOVE);
      }
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(recfgSpec));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to REMOVE the VSPAN session.");
   }

   @AfterMethod(alwaysRun = true)
   @Override
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = true;
      if (authHelper != null) {
         done &= authHelper.performSecurityTestsCleanup();
      }
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}
