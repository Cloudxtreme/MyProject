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

import java.util.List;
import java.util.Map;

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
 * Edit a VSPAN session in the DVS by providing multiple config specs.<br>
 * 1. Config with source port mirrored for Tx and destination as a port key.<br>
 * 2. Config with same source port mirrored for both Tx and Rx.<br>
 * 3. Config with a port mirrored for source Rx which is mirrored for Tx & Rx in
 * another session & destination as a different port.<br>
 **/
public class Pos026 extends VspanTestBase
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
      }
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to ADD Vspan session");
      log.info("Get the existing VSPAN sessions to modify them.");
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "No Sessions found.");
      return true;
   }

   @Test(description = "Edit a VSPAN session in the DVS by providing "
            + "multiple config specs.\r\n"
            + "1. Config with source port mirrored for Tx and destination as a port key.\r\n"
            + "2. Config with same source port mirrored for both Tx and Rx.\r\n"
            + "3. Config with a port mirrored for source Rx which is mirrored "
            + "for Tx & Rx in another session & destination as a different port.")
   @Override
   public void test()
      throws Exception
   {
      final Map<String, List<String>> pg2 = VspanHelper.popPortgroup(portGroups);
      final String pgKey2 = pg2.keySet().iterator().next();
      VMwareDVSVspanConfigSpec[] recfgSpec = null;
      VMwareVspanPort srcRx;
      recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
      // 1. Config with source port mirrored for Tx & destination as port key.
      VMwareVspanPort srcTx = VspanHelper.buildVspanPort(
               VspanHelper.popPort(portGroups), null, null);
      VMwareVspanPort dst = VspanHelper.buildVspanPort(
               VspanHelper.popPort(portGroups), null, null);
      VMwareVspanSession editSession = existingSessions[0];
      editSession.setSourcePortTransmitted(srcTx);
      editSession.setDestinationPort(dst);
      recfgSpec[0] = VspanHelper.buildVspanCfg(editSession, CONFIG_SPEC_EDIT);
      // 2. Config with same source port mirrored for both Tx and Rx.
      final String port = VspanHelper.popPort(portGroups);
      srcTx = VspanHelper.buildVspanPort(port, null, null);
      srcRx = VspanHelper.buildVspanPort(port, null, null);
      editSession = existingSessions[1];
      editSession.setSourcePortTransmitted(srcTx);
      editSession.setSourcePortReceived(srcRx);
      recfgSpec[1] = VspanHelper.buildVspanCfg(editSession, CONFIG_SPEC_EDIT);
      // 3. Config with a port mirrored for source Rx which is mirrored for Tx &
      // Rx in another session & destination as a different port.
      srcRx = VspanHelper.buildVspanPort(port, null, null);
      dst = VspanHelper.buildVspanPort(pg2.get(pgKey2).toArray(new String[0]),
               null, null);
      editSession = existingSessions[2];
      editSession.setSourcePortReceived(srcRx);
      editSession.setDestinationPort(dst);
      recfgSpec[2] = VspanHelper.buildVspanCfg(editSession, CONFIG_SPEC_EDIT);
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
