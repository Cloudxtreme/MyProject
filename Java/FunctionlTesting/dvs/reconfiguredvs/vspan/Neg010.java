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

import com.vmware.vc.VMwareDVSConfigInfo;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vc.VspanPortConflict;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * Edit a VSPAN session in a DVS by providing a valid uplink port name as source
 * and same port as destination.
 */
public class Neg010 extends VspanTestBase
{
   String sessionName = getTestId();
   VMwareDVSConfigInfo info;
   VMwareVspanSession[] existingSessions;
   VMwareVspanPort dest;
   String uplinkPort;

   @Override
   public void setTestDescription()
   {
      setTestDescription("Edit a VSPAN session in a DVS by providing a valid "
               + "uplink port name as source and same port as destination.");
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp()
   throws Exception
   {
      initialize();
      hostMor = hs.getConnectedHost(false);
      dvsMor = createDVSWithNic(dvsName,hostMor);
      vspanCfg = new VMwareDVSVspanConfigSpec[1];
      setupPortgroups(dvsMor);
      setupUplinkPorts(dvsMor);
      uplinkPort = VspanHelper.popPort(uplinkPortgroups);
      dest = VspanHelper.buildVspanPort(null, null, uplinkPort);
      vspanCfg[0] = VspanHelper.buildVspanCfg(VspanHelper.buildVspanSession(
               sessionName, null, null, dest), CONFIG_SPEC_ADD);
      dvsReCfg = new VMwareDVSConfigSpec();
      dvsReCfg.setConfigVersion(vmwareDvs.getConfig(dvsMor).getConfigVersion());
      dvsReCfg.getVspanConfigSpec().clear();
      dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(vspanCfg));
      assertTrue(vmwareDvs.reconfigure(dvsMor, dvsReCfg),
      "Failed to add VSPAN session");
      info = vmwareDvs.getConfig(dvsMor);
      existingSessions = com.vmware.vcqa.util.TestUtil.vectorToArray(info.getVspanSession(), com.vmware.vc.VMwareVspanSession.class);
      assertNotEmpty(existingSessions, "Added VSPAN not found!");
      return true;
   }

   @Test(description = "Edit a VSPAN session in a DVS by providing a valid "
               + "uplink port name as source and same port as destination.")
   @Override
   public void test()
   throws Exception
   {
      try {
         VMwareDVSVspanConfigSpec[] recfgSpec = null;
         recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
         for (int i = 0; i < existingSessions.length; i++) {
            final VMwareVspanSession aSession = existingSessions[i];
            log.info("Existing Session: {} : {}",i,VspanHelper.toString(aSession));
            if(sessionName.equals(aSession.getName())){
               final String uplink = VspanHelper.popPort(uplinkPortgroups);
               dest.getUplinkPortName().clear();
               dest.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] {uplinkPort,uplink}));
               aSession.setDestinationPort(VspanHelper.buildVspanPort(null, null,
                        uplinkPort));
               recfgSpec[i] = VspanHelper.buildVspanCfg(aSession, CONFIG_SPEC_EDIT);
            }
         }
         dvsReCfg = new VMwareDVSConfigSpec();
         dvsReCfg.setConfigVersion(info.getConfigVersion());
         dvsReCfg.getVspanConfigSpec().clear();
         dvsReCfg.getVspanConfigSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(recfgSpec));
         vmwareDvs.reconfigure(dvsMor, dvsReCfg);
         com.vmware.vcqa.util.Assert.assertTrue(false, "No Exception Thrown!");
      } catch (Exception excep) {
         com.vmware.vc.MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(excep);
         com.vmware.vc.MethodFault expectedMethodFault = new VspanPortConflict();
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
