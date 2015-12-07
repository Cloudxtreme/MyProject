/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VspanSameSessionPortConflict;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * Add a VSPAN session by providing same DVPort key for both Source and
 * destination.
 */
public class Neg028 extends VspanTestBase
{
   VMwareDVSConfigInfo info;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a VSPAN session by providing same DVPort "
               + "key for both Source and destination.");
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
      info = vmwareDvs.getConfig(dvsMor);
      return true;
   }

   @Test(description = "Add a VSPAN session by providing same DVPort "
            + "key for both Source and destination.")
   @Override
   public void test()
      throws Exception
   {
      try {
         final Map<String, List<String>> pg = VspanHelper.popPortgroup(portGroups);
         final String[] ports = pg.values().iterator().next().toArray(
                  new String[0]);
         final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(ports, null,
                  null);
         final VMwareVspanPort dst = VspanHelper.buildVspanPort(ports, null, null);
         vspanCfg = new VMwareDVSVspanConfigSpec[1];
         vspanCfg[0] = new VMwareDVSVspanConfigSpec();
         vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
         vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
                  srcTx, null, dst));
         dvsReCfg = new VMwareDVSConfigSpec();
         dvsReCfg.setConfigVersion(info.getConfigVersion());
         dvsReCfg.getVspanConfigSpec().clear();
         dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
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
