/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a standalone DVPort in DVS connected to a powered on VM to an early
 * binding DVPortgroup. Setup: 1. Create a DVS with a host member. 2. Create a
 * standalone DVPort and use it as port to be moved. 3. Reconfigure the existing
 * VM to bind to the standalone DVPort and power on the VM. 4. Create early
 * binding DVPortgroup and use it's key as destination. Test: 5. Move the
 * standalone DVPort to the early binding DVPortgroup. Cleanup: 6. Reconfigure
 * the VM to bring it to previous state. 7. Delete the DVS.
 */
public class Pos031 extends MovePortBase
{
   private ManagedObjectReference vm1Mor;
   /** deltaConfigSpec of the VM to restore it to Original form. */
   private VirtualMachineConfigSpec vm1DeltaCfgSpec;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a standalone DVPort in DVS connected to a "
               + "powered on VM to an early binding DVPortgroup.");
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
      List<String> portgroupKeys = null;
      List<ManagedObjectReference> vms = null;
      DVPortgroupConfigSpec aPortGroupCfg = null;
      DVPortgroupPolicy policy = null;// used to set 'LivePortMovingAllowed'.
     
         if (super.testSetUp()) {
            hostMor = ihs.getStandaloneHost();
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            if (dvsMor != null) {
               log.info("DVS created: " + iDVSwitch.getName(dvsMor));
               vms = ihs.getAllVirtualMachine(hostMor);
               if ((vms != null) && (vms.size() >= 1)) {
                  vm1Mor = vms.get(0);// get the VM.
                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
                  if ((portKeys != null) && (portKeys.size() > 0)) {
                     log.info("Successfully created a standalone DVPort.");
                     vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor,
                              connectAnchor, portKeys.get(0), null);
                     if ((vm1DeltaCfgSpec != null)
                              && ivm.setVMState(vm1Mor, POWERED_ON, false)) {
                        log.info("Crating DVPortgroup...");
                        policy = new DVPortgroupPolicy();
                        policy.setLivePortMovingAllowed(true);
                        aPortGroupCfg = buildDVPortgroupCfg(
                                 DVPORTGROUP_TYPE_EARLY_BINDING, 1, policy,
                                 null);
                        portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                        if ((portgroupKeys != null)
                                 && (portgroupKeys.size() >= 1)) {
                           log.info("Successfully added early bind port group.");
                           portgroupKey = portgroupKeys.get(0);
                           status = true;
                        } else {
                           log.error("Failed to add late bind port group.");
                        }
                     } else {
                        log.error("Failed to reconfigure the VM to use DVPort.");
                     }
                  } else {
                     log.error("Failed to create the standalone DVPort.");
                  }
               } else {
                  log.error("Failed to get required number of VM's from host.");
               }
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
   @Test(description = "Move a standalone DVPort in DVS connected to a "
               + "powered on VM to an early binding DVPortgroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
                  connectAnchor, dvsMor, portKeys);
         status = movePort(dvsMor, portKeys, portgroupKey);
         status &= DVSUtil.verifyConnecteeInfoAfterMovePort(connectAnchor,
                  connectedEntitiespMap, dvsMor, portKeys, portgroupKey);

     
      assertTrue(status, "Test Failed");
   }

   /**
    * Test cleanup.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         if ((vm1DeltaCfgSpec != null)
                  && ivm.setVMState(vm1Mor, POWERED_OFF, false)) {
            status = ivm.reconfigVM(vm1Mor, vm1DeltaCfgSpec);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
