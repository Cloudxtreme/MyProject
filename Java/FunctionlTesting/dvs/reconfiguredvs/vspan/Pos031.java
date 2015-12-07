/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * EDIT a VSPAN session in the DVS by providing blank as name of the session.
 **/
public class Pos031 extends VspanTestBase
{
   VMwareVspanSession[] existingSessions;

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      dvsMor = folder.createDistributedVirtualSwitch(dvsName);
      log.info("Create VSPAN...");
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               null, null, null));
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to ADD Vspan session");
      log.info("Get the existing VSPAN sessions to modify them.");
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "No Sessions found.");
      return true;
   }

   @Test(description = "EDIT a VSPAN session in the DVS by providing blank as name of the session.")
   @Override
   public void test()
      throws Exception
   {
      VMwareDVSVspanConfigSpec[] recfgSpec = null;
      recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
      for (int i = 0; i < existingSessions.length; i++) {// only one
         final VMwareVspanSession aSession = existingSessions[i];
         log.info("Original Session: {}", VspanHelper.toString(aSession));
         aSession.setName("");// set blank name.
         log.info("Reconfig Session: {}", VspanHelper.toString(aSession));
         recfgSpec[i] = VspanHelper.buildVspanCfg(aSession, CONFIG_SPEC_EDIT);
      }
      assertTrue(reconfigureVspan(dvsMor, recfgSpec),
               "Failed to edit VSPAN session.");
   }

   @AfterMethod(alwaysRun = true)
   @Override
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = true;
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}
