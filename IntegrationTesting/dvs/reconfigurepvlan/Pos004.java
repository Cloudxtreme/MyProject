/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
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
 * Add a PVLAN map entry to DVS by providing a primary PVLAN with port type as
 * promiscuous. Reconfigure two DVPorts to use this primary VLAN ID. <br>
 * Procedure:<br>
 * 1. Create a DVS.<br>
 * 2. Add the primary PVLAN entry.<br>
 * 4. Reconfigure 2 DVPorts to use this PVLAN.<br>
 * 3. Verify the connectivity of the VMs.<br>
 */
public class Pos004 extends PvlanBase
{
   ManagedObjectReference vm1Mor = null;
   ManagedObjectReference vm2Mor = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Add a PVLAN map entry to DVS by providing"
               + " a primary PVLAN with port type as promiscuous. "
               + "Reconfigure two DVPorts to use this primary VLAN ID.");
   }

   /**
    * Test setup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      List<ManagedObjectReference> vms = null;
     
         if (super.testSetUp()) {
            // hostMor = ihs.getStandaloneHost();
            hostMor = ihs.getConnectedHost(null);
            log.info("Using host: " + ihs.getName(hostMor));
            /* Create a DVS */
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            vms = ihs.getVMs(hostMor, null);
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
   @Override
   @Test(description = " Add a PVLAN map entry to DVS by providing"
               + " a primary PVLAN with port type as promiscuous. "
               + "Reconfigure two DVPorts to use this primary VLAN ID.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         if (iVmwareDVS.addPrimaryPvlan(dvsMor, PVLAN1_PRI_1)) {
            status = areConnected(connectAnchor, PVLAN1_PRI_1, PVLAN1_PRI_1,
                     vm1Mor, vm2Mor);
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Test cleanup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return <code>true</code> if successful.
    */
   @Override
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
