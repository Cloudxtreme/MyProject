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

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * Edit VSPAN sessions by providing the same session twice in the array to
 * modify the session name.
 **/
public class Neg029 extends VspanTestBase
{
   VMwareVspanSession[] existingSessions;
   VMwareDVSConfigInfo info;

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      hostMor = hs.getConnectedHost(false);
      dvsMor = createDVSWithNic(dvsName, hostMor);
      setupPortgroups(dvsMor);
      info = vmwareDvs.getConfig(dvsMor);
      log.info("Create VSPAN...");
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               null, null, null));
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(info.getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to ADD Vspan session");
      log.info("Get the existing VSPAN sessions to modify them.");
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "No Sessions found.");
      return true;
   }

   @Test(description = "Edit VSPAN sessions by providing the same session "
            + "twice in the array to modify the session name.")
   @Override
   public void test()
      throws Exception
   {
      try {
         VMwareDVSVspanConfigSpec[] recfgSpec = null;
         recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length + 1];
         final VMwareVspanSession editSession = existingSessions[0];
         editSession.setName(editSession.getName() + "-edit");
         // edit the same session twice
         recfgSpec[0] = VspanHelper.buildVspanCfg(editSession, CONFIG_SPEC_EDIT);
         recfgSpec[1] = VspanHelper.buildVspanCfg(editSession, CONFIG_SPEC_EDIT);
         reconfigureVspan(dvsMor, recfgSpec);
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
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = true;
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}
