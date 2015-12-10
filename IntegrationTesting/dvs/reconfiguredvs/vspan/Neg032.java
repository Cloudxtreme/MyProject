/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.CONFIG_SPEC_EDIT;
import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vc.VspanDestPortConflict;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Edit a VSPAN session in the DVS by providing multiple configs with same
 * destination port & expect VspanDestPortConflict fault.<br>
 * 1. Config with source port mirrored for Tx and destination as a port key.<br>
 * 2. Config with source port mirrored for Tx and destination as a port key.<br>
 * 3. Config with source port mirrored for Tx and destination as a port key.<br>
 **/
public class Neg032 extends VspanTestBase
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
      vspanCfg = new VMwareDVSVspanConfigSpec[3];
      log.info("Creating '{}' VSPAN...", vspanCfg.length);
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

   @Test(description = "Edit a VSPAN session in the DVS by providing with "
            + "same destination port & expect VspanDestPortConflict fault.\r\n"
            + "1. Config with source port mirrored for Tx and destination as a port key.\r\n"
            + "2. Config with source port mirrored for Tx and destination as a port key.\r\n"
            + "3. Config with source port mirrored for Tx and destination as a "
            + "port key.")
   @Override
   public void test()
      throws Exception
   {
      try {
         VMwareDVSVspanConfigSpec[] recfgSpec = null;
         final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(
                  VspanHelper.popPort(portGroups), null, null);
         final VMwareVspanPort dst = VspanHelper.buildVspanPort(
                  VspanHelper.popPort(portGroups), null, null);
         recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
         for (int i = 0; i < existingSessions.length; i++) {
            final VMwareVspanSession aSession = existingSessions[i];
            aSession.setSourcePortTransmitted(srcTx);
            aSession.setDestinationPort(dst);
            recfgSpec[i] = VspanHelper.buildVspanCfg(aSession, CONFIG_SPEC_EDIT);
         }
         assertTrue(reconfigureVspan(dvsMor, recfgSpec),
                  "Failed to edit VSPAN session.");
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new VspanDestPortConflict();
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
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}
