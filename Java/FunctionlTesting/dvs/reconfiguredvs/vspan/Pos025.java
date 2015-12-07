/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;

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
 * EDIT a VSPAN session in the DVS by providing many valid source port keys,
 * port group keys and uplink port name for mirroring the Tx and Rx with
 * destination as valid uplink port name.
 **/
public class Pos025 extends VspanTestBase
{
   VMwareVspanSession[] existingSessions;

   @Override
   public void setTestDescription()
   {
      setTestDescription("EDIT a VSPAN session in the DVS by providing many "
               + "valid source port keys, port group keys and uplink port "
               + "name for mirroring the Tx and Rx with destination "
               + "as valid uplink port name.");
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      hostMor = hs.getConnectedHost(false);
      dvsMor = createDVSWithNic(dvsName, hostMor);
      setupPortgroups(dvsMor);
      setupUplinkPorts(dvsMor);
      log.info("Create VSPAN...");
      final Map<String, List<String>> apg = VspanHelper.popPortgroup(portGroups);
      final String portgroupKey = apg.keySet().iterator().next();
      final String portKey = apg.get(portgroupKey).get(0);
      final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(portKey, null,
               null);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               srcTx, null, null));
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

   @Test(description = "EDIT a VSPAN session in the DVS by providing many "
            + "valid source port keys, port group keys and uplink port "
            + "name for mirroring the Tx and Rx with destination "
            + "as valid uplink port name.")
   @Override
   public void test()
      throws Exception
   {
      final Map<String, List<String>> pg1 = VspanHelper.popPortgroup(portGroups);
      final Map<String, List<String>> pg2 = VspanHelper.popPortgroup(portGroups);
      final String pgKey1 = pg1.keySet().iterator().next();
      final String pgKey2 = pg2.keySet().iterator().next();
      final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(
               pg1.get(pgKey1).toArray(new String[0]), null, null);
      final VMwareVspanPort srcRx = VspanHelper.buildVspanPort(
               pg2.get(pgKey2).toArray(new String[0]), null, null);
      final VMwareVspanPort dst = VspanHelper.buildVspanPort(null, null,
               VspanHelper.popPort(uplinkPortgroups));
      VMwareDVSVspanConfigSpec[] recfgSpec = null;
      recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
      for (int i = 0; i < existingSessions.length; i++) {// only one
         final VMwareVspanSession aSession = existingSessions[i];
         log.info("Original Session: {}", VspanHelper.toString(aSession));
         aSession.setSourcePortTransmitted(srcTx);
         aSession.setSourcePortReceived(srcRx);
         aSession.setDestinationPort(dst);
         log.info("Reconfig Session: {}", VspanHelper.toString(aSession));
         recfgSpec[i] = VspanHelper.buildVspanCfg(aSession, CONFIG_SPEC_EDIT);
      }
      assertTrue(reconfigureVspan(dvsMor, recfgSpec),
               "Edited VSPAN successfully", "Failed to edit VSPAN session.");
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
