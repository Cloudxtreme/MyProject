/*
 * ************************************************************************
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

import com.vmware.vc.NotFound;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Remove a VSPAN session by providing invalid/null key.
 */
public class Neg027 extends VspanTestBase
{
   VMwareDVSConfigInfo info;
   VMwareVspanSession[] existingSessions;
   String vspanName;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Remove a VSPAN session by providing invalid/null key.");
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      dvsMor = folder.createDistributedVirtualSwitch(dvsName,
               hs.getConnectedHost(null));
      setupPortgroups(dvsMor);
      info = vmwareDvs.getConfig(dvsMor);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanName = getTestId();
      vspanCfg[0] = VspanHelper.buildVspanCfg(VspanHelper.buildVspanSession(
               vspanName, null, null, null), CONFIG_SPEC_ADD);
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(info.getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to add VSPAN session");
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "Added VSPAN not found!");
      return true;
   }

   @Test(description = "Remove a VSPAN session by providing invalid/null key.")
   @Override
   public void test()
      throws Exception
   {
      try {
         VMwareDVSVspanConfigSpec[] recfgSpec = null;
         recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
         for (int i = 0; i < existingSessions.length; i++) {
            final VMwareVspanSession aSession = existingSessions[i];
            final String name = aSession.getName();
            log.info("vspan:{}: {} ", i, VspanHelper.toString(aSession));
            if (name.equals(vspanName)) {
               aSession.setKey("invalid");
               recfgSpec[i] = VspanHelper.buildVspanCfg(aSession,
                        CONFIG_SPEC_REMOVE);
               break;
            }
         }
         dvsReCfg.getVspanConfigSpec().clear();
         dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(recfgSpec));
         dvsReCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
         vmwareDvs.reconfigure(dvsMor, dvsReCfg);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new NotFound();
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
      return vmwareDvs.destroy(dvsMor);
   }
}
