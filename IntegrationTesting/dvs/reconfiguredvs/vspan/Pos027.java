/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Edit a VSPAN session in the DVS by providing similar multiple config specs.<br>
 * 1. Config with source port mirrored for Tx and Rx.<br>
 * 2. Config with source port mirrored for Tx and Rx.<br>
 * 3. Config with source port mirrored for Tx and Rx.<br>
 **/
public class Pos027 extends VspanTestBase
{
   VMwareVspanSession[] existingSessions;

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      hostMor = hs.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_FAIL);
      dvsMor = createDVSWithNic(dvsName, hostMor);
      setupPortgroups(dvsMor);
      log.info("Create VSPAN...");
      // add 3 sessions
      vspanCfg = new VMwareDVSVspanConfigSpec[3];
      for (int i = 0; i < vspanCfg.length; i++) {
         vspanCfg[i] = new VMwareDVSVspanConfigSpec();
         vspanCfg[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
         vspanCfg[i].setVspanSession(VspanHelper.buildVspanSession(getTestId()
                  + "-" + i, null, null, null));
         final VMwareVspanSession session = vspanCfg[i].getVspanSession();
         session.setEnabled(i % 2 == 0 ? true : false);
         log.info("Session: {} ", VspanHelper.toString(session));
      }
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to ADD VSPAN session");
      log.info("Get the existing VSPAN sessions to modify them.");
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "No Sessions found.");
      return true;
   }

   @Test(description = "Edit a VSPAN session in the DVS by providing "
            + "similar multiple config specs.\r\n"
            + "1. Config with source port mirrored for Tx and Rx.\r\n"
            + "2. Config with source port mirrored for Tx and Rx.\r\n"
            + "3. Config with source port mirrored for Tx and Rx.")
   @Override
   public void test()
      throws Exception
   {
      VMwareDVSVspanConfigSpec[] recfgSpec = null;
      final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(
               VspanHelper.popPort(portGroups), null, null);
      final VMwareVspanPort srcRx = VspanHelper.buildVspanPort(
               VspanHelper.popPort(portGroups), null, null);
      recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
      for (int i = 0; i < existingSessions.length; i++) {
         final VMwareVspanSession aSession = existingSessions[i];
         aSession.setSourcePortTransmitted(srcTx);
         aSession.setSourcePortReceived(srcRx);
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
