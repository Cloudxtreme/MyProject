/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.vim.PrivilegeConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.NoPermission;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.AuthorizationHelper;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Add a VSPAN session to the DVS by user NOT having "DVSwitch.Vspan" privilege.<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS.<br>
 * 2. Login with Test user without "DVSwitch.Vspan" privilege.<br>
 * <br>
 * TEST:<br>
 * 3. Try to reconfigure DVS to ADD a VSPAN session.<br>
 * 5. Expect that NoPermission Fault to thrown.<br>
 * CLEANUP:<br>
 * 6. Destroy the DVS.<br>
 */
public class Sec004 extends VspanTestBase
{
   private AuthorizationHelper authHelper;
   private final String testUser = GENERIC_USER;

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
      vspanCfg[0].getVspanSession().setEncapsulationVlanId(1);
      vspanCfg[0].getVspanSession().setEnabled(true);
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      authHelper = new AuthorizationHelper(connectAnchor, getTestId(), true,
               data.getString(TestConstants.TESTINPUT_USERNAME),
               data.getString(TestConstants.TESTINPUT_PASSWORD));
      authHelper.setPermissions(dvsMor, DVSWITCH_VSPAN, testUser, false);
      return authHelper.performSecurityTestsSetup(testUser);
   }

   @Test(description = "Add a VSPAN session to the DVS by a user NOT having "
            + "\"DVSwitch.Vspan\" privilege.")
   @Override
   public void test()
      throws Exception
   {
      try {
         log.info("Adding session: {}",
                  VspanHelper.toString(vspanCfg[0].getVspanSession()));
         vmwareDvs.reconfigure(dvsMor, dvsReCfg);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         NoPermission expectedMethodFault = new NoPermission();
         expectedMethodFault.setObject(dvsMor);
         expectedMethodFault.setPrivilegeId(DVSWITCH_VSPAN);
         com.vmware.vcqa.util.Assert.assertTrue(
                  com.vmware.vcqa.util.TestUtil.checkMethodFault(
                           actualMethodFault, expectedMethodFault),
                  "MethodFault mismatch!");
      }
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
