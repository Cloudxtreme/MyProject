/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.util.Assert.*;

import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Add a VSPAN session to the DVS by providing many valid source port keys and
 * uplink port name for mirroring the Tx and Rx with destination as valid port
 * key.
 **/
public class Pos022 extends VspanTestBase
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
      setupUplinkPorts(dvsMor);
      return true;
   }

   @Test(description = "Add a VSPAN session to the DVS by providing many "
            + "valid source port keys and uplink port name "
            + "for mirroring the Tx and Rx with destination as valid port key.")
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
      Assert.assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
               "successfully added VSPAN session",
               "Failed to add vspan session.");
   }

   @AfterMethod(alwaysRun = true)
   @Override
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = true;
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      List<ManagedObjectReference> vmMorList = this.vm.getAllVM();
      if(vmMorList != null){
         /*
          * Power off all vms in the inventory
          */
         for(ManagedObjectReference mor : vmMorList){
            if(!this.vm.getVMState(mor).value().
                     equals(VirtualMachinePowerState.POWERED_OFF.value())){
               assertTrue(this.vm.setVMState(mor, VirtualMachinePowerState.POWERED_OFF, false),"Successfully powered off vm : " +
                          vm.getVMName(mor),"Failed to power off vm : "  +
                          vm.getVMName(mor));
            }
         }
      }
      return done;
   }
}
