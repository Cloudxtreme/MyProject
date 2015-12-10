/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * Add a PVLAN map entry to the DVS with primary PVLAN ID with port type as
 * promiscuous. P1(10,10,P) create/use a DVPort without any PVLAN configuration. <br>
 * Procedure:<br>
 * 1. Create a DVS.<br>
 * 2. Add the primary PVLAN entry.<br>
 * 4. Reconfigure a DVPort to use this PVLAN.<br>
 * 3. Verify the connectivity of the VMs connected to this DVPort and a normal
 * DVPort.<br>
 */
public class Pos016 extends PvlanBase
{
   ManagedObjectReference vm1Mor = null;
   ManagedObjectReference vm2Mor = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Add a PVLAN map entry to the DVS with primary "
               + "PVLAN ID with port type as promiscuous.  P1(10,10,P)\r\n"
               + "create/use a DVPort without any PVLAN configuration. P2");
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
   @Test(description = "Add a PVLAN map entry to the DVS with primary "
               + "PVLAN ID with port type as promiscuous.  P1(10,10,P)\r\n"
               + "create/use a DVPort without any PVLAN configuration. P2")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         if (iVmwareDVS.addPrimaryPvlan(dvsMor, PVLAN1_PRI_1)) {
            status = !areConnected(connectAnchor, Integer.MAX_VALUE,
                     PVLAN1_PRI_1, vm1Mor, vm2Mor);
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
