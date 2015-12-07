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
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.PVLAN_TYPE_ISOLATED;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * Add three PVLAN map entries to the DVS. 1. One primary PVLAN with promiscuous
 * port. P1-(10,10,P) 2. One secondary PVLAN with community port. P2-(10,101,C)
 * 3. Another secondary PVLAN with isolated port. P3-(10,102,I) Procedure:<br>
 * Setup: 1. Create a DVS with a host member in it.<br>
 * 2. Get two VM's from the host to verify connectivity.<br>
 * 3. Update the host network to use DVS.<br>
 * Test:<br>
 * 4.a. Add a primary PVLAN map entry of type promiscuous to DVS. <br>
 * 4.b. Add a secondary PVLAN map entry of type community to DVS. <br>
 * 4.c. Add a secondary PVLAN map entry of type isolated to DVS. <br>
 * 5.a. DVPorts belonging to P1 and P2 should have connectivity.<br>
 * 5.c. DVPorts belonging to P1 and P3 should have connectivity.<br>
 * 5.c. DVPorts belonging to P2 and P3 should not have connectivity.<br>
 * Cleanup:<br>
 * 6. Update the network of host to use previous network.<br>
 * 7. Deleted the DVS.<br>
 * 8. Log off from VC.<br>
 */
public class Pos011 extends PvlanBase
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
               + "secondary VLAN ID with port type as isolated. Reconfigure "
               + "two DVPorts to use these VLAN IDs.");
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
            hostMor = ihs.getStandaloneHost();
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
               + "secondary VLAN ID with port type as isolated. Reconfigure "
               + "two DVPorts to use these VLAN IDs.")
   public void test()
      throws Exception
   {
      boolean status = false;
      log.info("Test Begin:");
     
         if (iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
                  PVLAN1_PRI_1, PVLAN1_SEC_1, true)) {
            log.info("Successfully added first community PVLAN.");
            if (iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_ISOLATED,
                     PVLAN1_PRI_1, PVLAN1_SEC_2, false)) {
               log.info("Successfully added isolated PVLAN in the "
                        + "same primary PVLAN.");
               log.info("DVPorts belonging to P1 and P2 should have connectivity");
               if (areConnected(connectAnchor, PVLAN1_PRI_1, PVLAN1_SEC_1,
                        vm1Mor, vm2Mor)) {
                  log.info("DVPorts P1 and P2 are connected.");
                  if (areConnected(connectAnchor, PVLAN1_PRI_1, PVLAN1_SEC_2,
                           vm1Mor, vm2Mor)) {
                     log.info("DVPorts P1 and P3 are connected.");
                     if (!areConnected(connectAnchor, PVLAN1_SEC_1,
                              PVLAN1_SEC_2, vm1Mor, vm2Mor)) {
                        log.info("Success: DVPorts P2 and P3 are not connected");
                        status = true;
                     } else {
                        log.error("DVPorts P2 and P3 are connected!");
                     }
                  } else {
                     log.error("DVPorts P1 and P3 are not connected.");
                  }
               } else {
                  log.error("DVPorts P1 and P2 are not connected.");
               }
            }
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
