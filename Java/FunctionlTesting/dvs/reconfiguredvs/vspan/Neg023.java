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

import com.vmware.vc.InvalidArgument;
import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Edit a VSPAN session in a DVS by providing invalid VLAN ID.
 */
public class Neg023 extends VspanTestBase
{
   VMwareDVSConfigInfo info;
   VMwareVspanSession[] existingSessions;

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      dvsMor = folder.createDistributedVirtualSwitch(dvsName,
               hs.getConnectedHost(false));
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = VspanHelper.buildVspanCfg(VspanHelper.buildVspanSession(
               getTestId(), null, null, null), CONFIG_SPEC_ADD);
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "Failed to add VSPAN session");
      info = vmwareDvs.getConfig(dvsMor);
      existingSessions = VspanHelper.filterSession(com.vmware.vcqa.util.TestUtil.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class));
      assertNotEmpty(existingSessions, "Added VSPAN not found!");
      return true;
   }

   @Test(description = "Edit a VSPAN session in a DVS by providing "
            + "invalid VLAN ID.")
   @Override
   public void test()
      throws Exception
   {
      try {
         VMwareDVSVspanConfigSpec[] recfgSpec = null;
         recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
         for (int i = 0; i < existingSessions.length; i++) {
            final VMwareVspanSession aSession = existingSessions[i];
            aSession.setEncapsulationVlanId(-1);
            recfgSpec[i] = VspanHelper.buildVspanCfg(aSession, CONFIG_SPEC_EDIT);
         }
         dvsReCfg = new VMwareDVSConfigSpec();
         dvsReCfg.setConfigVersion(info.getConfigVersion());
         dvsReCfg.getVspanConfigSpec().clear();
         dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(recfgSpec));
         vmwareDvs.reconfigure(dvsMor, dvsReCfg);
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

   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return vmwareDvs.destroy(dvsMor);
   }
}
