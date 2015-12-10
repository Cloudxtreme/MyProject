/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

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
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Add a VSPAN session to the DVS by providing many valid source port keys, port
 * group keys and uplink port name for mirroring the Tx and Rx with destination
 * as valid port group key.
 **/
public class Pos023 extends VspanTestBase
{
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
      return true;
   }

   @Test(description = "Add a VSPAN session to the DVS by providing many "
            + "valid source port keys, port group keys and uplink port "
            + "name for mirroring the Tx and Rx with destination as "
            + "valid port group key.")
   @Override
   public void test()
      throws Exception
   {
      final Map<String, List<String>> pg1 = VspanHelper.popPortgroup(portGroups);
      final Map<String, List<String>> pg2 = VspanHelper.popPortgroup(portGroups);
      final String pgKey1 = pg1.keySet().iterator().next();
      final String pgKey2 = pg2.keySet().iterator().next();
      final VMwareVspanPort srcTx = VspanHelper.buildVspanPort(
               pg1.get(pgKey1).toArray(new String[0]), new String[] { pgKey1,
                        pgKey2 }, null);
      final VMwareVspanPort srcRx = VspanHelper.buildVspanPort(
               pg2.get(pgKey2).toArray(new String[0]), new String[] { pgKey2,
                        pgKey1 }, null);
      final VMwareVspanPort dst = VspanHelper.buildVspanPort(null,
               VspanHelper.popPortgroup(portGroups).keySet().iterator().next(),
               null);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      vspanCfg[0] = new VMwareDVSVspanConfigSpec();
      vspanCfg[0].setOperation(TestConstants.CONFIG_SPEC_ADD);
      vspanCfg[0].setVspanSession(VspanHelper.buildVspanSession(getTestId(),
               srcTx, srcRx, dst));
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfigVersion(dvsMor));
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
