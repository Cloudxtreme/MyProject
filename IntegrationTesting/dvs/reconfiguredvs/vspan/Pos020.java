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
 * mirroring the Tx only with destination as valid port key.<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS & add host member to it using free pNIC.<br>
 * 2. Create 3 port groups with 2 ports each.<br>
 * <br>
 * TEST:<br>
 * 3. Create Source Tx with multiple ports & Dest with valid DVPort<br>
 * 4. Reconfigure the DVS to add the VSPAN sessions.<br>
 * 5. Verify that the VSPAN's are created from VC & HOSTD.<br>
 * CLEANUP:<br>
 * 6. Destroy the DVS.<br>
 */
public class Pos020 extends VspanTestBase
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
            + "valid source port keys for mirroring the Tx only with "
            + "destination as valid port key.")
   @Override
   public void test()
      throws Exception
   {
      final Map<String, List<String>> pg = VspanHelper.popPortgroup(portGroups);
      final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(
               pg.values().iterator().next().toArray(new String[0]), null, null);
      final VMwareVspanPort dst = VspanHelper.buildVspanPort(
               VspanHelper.popPort(portGroups), null, null);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               srcTx, null, dst));
      log.info("Adding session: {}",
               VspanHelper.toString(vspanCfg[0].getVspanSession()));
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
