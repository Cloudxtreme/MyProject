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

import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Add a VSPAN session to the DVS by providing many valid source port keys for
 * mirroring the Tx and Rx with destination as valid port keys.
 **/
public class Pos021 extends VspanTestBase
{
   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
      throws Exception
   {
      initialize();
      hostMor = hs.getConnectedHost(false);
      dvsMor = createDVSWithNic(dvsName, hostMor);
      setupPortgroups(dvsMor);
      return true;
   }

   @Test(description = "Add a VSPAN session to the DVS by providing many "
            + "valid source port keys for mirroring the Tx and Rx with "
            + "destination as valid port keys.")
   @Override
   public void test()
      throws Exception
   {
      Map<String, List<String>> pg = VspanHelper.popPortgroup(portGroups);
      final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(
               pg.values().iterator().next().toArray(new String[0]), null, null);
      pg = VspanHelper.popPortgroup(portGroups);// Use this for Rx.
      final VMwareVspanPort srcRx = VspanHelper.buildVspanPort(
               pg.values().iterator().next().toArray(new String[0]), null, null);
      final VMwareVspanPort dst = VspanHelper.buildVspanPort(
               VspanHelper.popPort(portGroups), null, null);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               srcTx, srcRx, dst));
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      vmwareDvs.reconfigure(dvsMor, dvsReCfg);
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
