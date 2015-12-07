/* ************************************************************************
 *
 * Copyright 2010 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs.vspan;

import static com.vmware.vcqa.TestConstants.*;
import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.vim.dvs.VspanHelper;

/**
 * DESCRIPTION:<br>
 * REMOVE VSPAN session from DVS by providing valid VSPAN key.<br>
 * <br>
 * SETUP:<br>
 * 1. Create a DVS & add host member to it using free pNIC.<br>
 * 2. Create 2 port groups with 2 ports each.<br>
 * 3. Get 2 VM's from the host and power them on.<br>
 * 4. Reconfigure each VM to use 2 ports of DVPortGroup.<br>
 * 5. Add VSPAN sessions to DVS to delete them.<br>
 * <br>
 * TEST:<br>
 * 6. Generate different combinations of VSPAN sessions using DVPorts with
 * destination as valid port key, port group key and valid uplink port name.<br>
 * 6. Reconfigure the DVS to EDIT the VSPAN sessions.<br>
 * 7. Verify that the VSPAN's are edited from VC & HOSTD.<br>
 * CLEANUP:<br>
 * 8. Restore the VMs to previous network config.<br>
 * 9. Destroy the DVS.<br>
 * <br>
 * TODO : We can control the data to be given to this test using XML. As of now
 * we create & delete 64 sessions.
 */
public class Pos018 extends VspanTestBase
{
   VMwareVspanSession[] existingSessions;

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
      setupVMs(dvsMor); // TODO VM's setup is not needed
      log.info("Create VSPAN sessions with no destination ports.");
      VMwareDVSVspanConfigSpec[] vspanConfigSpecs =  buildVspanCfgs(null, dvsMor);
      for (int i=0;i<vspanConfigSpecs.length ; i++) {
         vspanConfigSpecs[i].getVspanSession().setMirroredPacketLength(60);
      }
      assertTrue(reconfigureVspan(dvsMor, vspanConfigSpecs),
               "Failed to ADD Vspan sessions");
      log.info("Get the existing VSPAN sessions to modify them.");
      existingSessions = VspanHelper.filterSession((com.vmware.vcqa.util.TestUtil.vectorToArray(vmwareDvs.getConfig(dvsMor).getVspanSession(), com.vmware.vc.VMwareVspanSession.class)));
      assertNotEmpty(existingSessions, "No Sessions found.");
      return true;
   }

   @Test(description = "REMOVE VSPAN session from DVS by providing "
            + "valid VSPAN key.")
   @Override
   public void test()
      throws Exception
   {
      VMwareDVSVspanConfigSpec[] recfgSpec = null;
      recfgSpec = new VMwareDVSVspanConfigSpec[existingSessions.length];
      for (int i = 0; i < existingSessions.length; i++) {
         final VMwareVspanSession aSession = existingSessions[i];
         recfgSpec[i] = VspanHelper.buildVspanCfg(aSession, CONFIG_SPEC_REMOVE);
      }
      assertTrue(reconfigureVspan(dvsMor, recfgSpec),
               "Failed to remove VSPAN sessions.");
   }

   @AfterMethod(alwaysRun = true)
   @Override
   public boolean testCleanUp()
      throws Exception
   {
      boolean done = true;
      done &= cleanupVMs();
      log.info("Destroying the DVS: {} ", dvsName);
      done &= destroy(dvsMor);
      return done;
   }
}
