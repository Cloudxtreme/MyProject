/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vc.VspanSameSessionPortConflict;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Add a VSPAN session to a DVS by providing a valid DVPort key as source and
 * same DVPort key as destination in same session. This is not allowed.
 */
public class Neg009 extends VspanTestBase
{
   VMwareDVSConfigInfo info;
   VMwareVspanSession[] existingSessions;
   String portKey;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a VSPAN session to a DVS by providing a valid "
               + "DVPort key as source and same DVPort key as destination "
               + "in same session. This is not allowed.");
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      dvsMor = folder.createDistributedVirtualSwitch(dvsName,
               hs.getConnectedHost(false));
      setupPortgroups(dvsMor);
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      final VMwareVspanPort sourcePortTx;
      final VMwareVspanPort destination;
      portKey = VspanHelper.popPort(portGroups);
      sourcePortTx = VspanHelper.buildVspanPort(portKey, null, null);
      destination = VspanHelper.buildVspanPort(portKey, null, null);
      final VMwareVspanSession session = VspanHelper.buildVspanSession(
               getTestId(), sourcePortTx, null, destination);
      log.info("Session: {} ", VspanHelper.toString(session));
      vspanCfg[0] = VspanHelper.buildVspanCfg(session, CONFIG_SPEC_ADD);
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      return true;
   }

   @Test(description = "Add a VSPAN session to a DVS by providing a valid "
            + "DVPort key as source and same DVPort key as destination. "
            + "This is not allowed.")
   @Override
   public void test()
      throws Exception
   {
      try {
         vmwareDvs.reconfigure(dvsMor, dvsReCfg);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new VspanSameSessionPortConflict();
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
