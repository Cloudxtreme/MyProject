/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
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
 * Add PVLAN map entries to the DVS by providing two secondary VLAN IDs both
 * with port type as community. Reconfigure one DVPort to use VLAN ID-101 and
 * other DVPort to use the VLAN ID-102. P0(10), P1-(10,101,C) P2-(10,102,C)
 */
public class Pos007 extends PvlanBase
{
   ManagedObjectReference vm1Mor = null;
   ManagedObjectReference vm2Mor = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Add PVLAN map entries to the DVS by providing "
               + "two secondary VLAN IDs both with port type as community. "
               + "Reconfigure one DVPort to use VLAN ID-101 and other "
               + "DVPort to use the VLAN ID-102. "
               + "P0(10), P1-(10,101,C)  P2-(10,102,C)");
   }

   /**
    * Test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if setup is successful.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
     
         List<ManagedObjectReference> vms = null;
         if (super.testSetUp()) {
            hostMor = ihs.getStandaloneHost();
            /* Create a DVS */
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            /* Make sure that we have 2 VM's to verify the connectivity. */
            vms = ihs.getAllVirtualMachine(hostMor);
            if (vms != null && vms.size() >= 2) {
               vm1Mor = vms.get(0);
               vm2Mor = vms.get(1);
               log.info("Successfully got the VM's required for verification.");
               // update the network to use the DVS.
               hostNetworkConfig = iVmwareDVS.getHostNetworkConfigMigrateToDVS(
                        dvsMor, hostMor);
               status = ins.updateNetworkConfig(ins.getNetworkSystem(hostMor),
                        hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);
            } else {
               log.error("Failed to get required number of VM's.");
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
   @Test(description = "Add PVLAN map entries to the DVS by providing "
               + "two secondary VLAN IDs both with port type as community. "
               + "Reconfigure one DVPort to use VLAN ID-101 and other "
               + "DVPort to use the VLAN ID-102. "
               + "P0(10), P1-(10,101,C)  P2-(10,102,C)")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         if (iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
                  PVLAN1_PRI_1, PVLAN1_SEC_1, true)) {
            if (iVmwareDVS.addSecondaryPvlan(dvsMor, PVLAN_TYPE_COMMINITY,
                     PVLAN1_PRI_1, PVLAN1_SEC_2, false)) {
               status = !areConnected(connectAnchor, PVLAN1_SEC_1,
                        PVLAN1_SEC_2, vm1Mor, vm2Mor);
            }
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Test cleanup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
     
         if (ins.updateNetworkConfig(ins.getNetworkSystem(hostMor),
                  hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY)) {
            log.info("Successfully restored the network config.");
         } else {
            log.error("Failed to restore the network config.");
         }
         status = super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
