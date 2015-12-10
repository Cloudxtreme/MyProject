/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_COMMINITY;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to DVS by providing a secondary PVLAN with port type as
 * community. Reconfigure two DVPorts to use community PVLAN ID. P1(101) ,
 * P2(101) Procedure:<br>
 * Setup: 1. Create a DVS with a host member in it.<br>
 * 2. Get two VM's from the host to verify connectivity.<br>
 * 3. Update the host network to use DVS.<br>
 * Test:<br>
 * 4. Add a secondary PVLAN map entry of type community to DVS. <br>
 * 5. The DVPorts belonging to same secondary PVLAN of type community should
 * have connectivity.<br>
 * Cleanup:<br>
 * 6. Update the network of host to use previous network.<br>
 * 7. Deleted the DVS.<br>
 * 8. Log off from VC.<br>
 */
public class Pos005 extends PvlanBase
{
   private List<ManagedObjectReference> vms = null;
   private ManagedObjectReference vm1Mor = null;
   private ManagedObjectReference vm2Mor = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to DVS by providing a "
               + "secondary PVLAN with port type as community. Reconfigure "
               + "two DVPorts to use community PVLAN ID.");
   }

   /**
    * Test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
     
         if (super.testSetUp()) {
            // hostMor = ihs.getStandaloneHost();
            hostMor = ihs.getConnectedHost(null);
            if (hostMor != null) {
               log.info("Creating DVS: " + dvsName);
               dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
               log.info("Check whether we have two VMs in the host...");
               vms = ihs.getAllVirtualMachine(hostMor);
               if (vms != null && vms.size() >= 2) {
                  vm1Mor = vms.get(0);
                  vm2Mor = vms.get(1);
                  log.info("Got two VM's, Update host network to use DVS...");
                  hostNetworkConfig = iVmwareDVS.getHostNetworkConfigMigrateToDVS(
                           dvsMor, hostMor);
                  if (hostNetworkConfig != null) {
                     status = ins.updateNetworkConfig(
                              ins.getNetworkSystem(hostMor),
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY);
                  } else {
                     log.error("Failed to get the required network config.");
                  }
               } else {
                  log.error("Failed to get required number of VM's.");
               }
            } else {
               log.error("Failed to get a host.");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a PVLAN map entry to DVS by providing a "
               + "secondary PVLAN with port type as community. Reconfigure "
               + "two DVPorts to use community PVLAN ID.")
   public void test()
      throws Exception
   {
      boolean status = false;
      log.info("Test Begin:");
     
         if (iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
                  PVLAN1_PRI_1, PVLAN1_SEC_1, true)) {
            status = areConnected(connectAnchor, PVLAN1_SEC_1, PVLAN1_SEC_1,
                     vm1Mor, vm2Mor);
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, if test setup was successful. false, otherwise.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if (hostNetworkConfig != null) {
            if (ins.updateNetworkConfig(ins.getNetworkSystem(hostMor),
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY)) {
               log.info("Successfully restored the network config.");
            } else {
               log.error("Failed to restore the network config.");
               status = false;
            }
         }
      } catch (Exception e) {
         status = false;
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
