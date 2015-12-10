/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

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
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a standalone DVPort bound to a powered on VM to a late binding
 * DVPortgroup.
 */
public class Pos033 extends MovePortBase
{
   private ManagedObjectReference vm1Mor = null;
   /** deltaConfigSpec of the VM to restore it to Original form. */
   private VirtualMachineConfigSpec vm1DeltaCfgSpec = null;;
   private VirtualMachinePowerState oldVMPowerState = null;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a standalone DVPort bound to a powered off VM "
               + "to a late binding DVPortGroup.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Get A VM, used for connecting the DVPort to
    * be moved. 3. Create a standalone DVPort and connect VM-1 to it and use it
    * as port to be moved. 4. Create a late binding DVPortgroup and use it as
    * destination.
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
     
         if (super.testSetUp()) {
            hostMor = ihs.getStandaloneHost();
            if (hostMor != null) {
               dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
               vms = ivm.getAllVMs(hostMor);
               if ((vms != null) && (vms.size() >= 1)) {
                  vm1Mor = vms.get(0);// get the VM.
                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
                  if ((portKeys != null) && !portKeys.isEmpty()) {
                     log.info("Reconfigure the VM to use standalone DVPort.");
                     vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor,
                              connectAnchor, portKeys.get(0), null);
                     if (vm1DeltaCfgSpec != null) {
                        log.info("Successfully reconfigured the VM to use the "
                                 + "DVPort: " + portKeys);
                        this.oldVMPowerState = this.ivm.getVMState(this.vm1Mor);
                        if (this.ivm.setVMState(vm1Mor, VirtualMachinePowerState.POWERED_ON, false)) {
                           log.info("Successfully powered on the VM");
                           log.info("Adding the destination DVPortgroup...");
                           DVPortgroupPolicy policy = new DVPortgroupPolicy();
                           policy.setLivePortMovingAllowed(true);
                           aPortGroupCfg = buildDVPortgroupCfg(
                                    DVPORTGROUP_TYPE_LATE_BINDING, 1, policy,
                                    null);
                           portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                           if ((portgroupKeys != null)
                                    && (portgroupKeys.size() > 0)) {
                              log.info("Successfully added late binding "
                                       + "DVPortgroup.");
                              portgroupKey = portgroupKeys.get(0);
                              status = true;
                           } else {
                              log.error("Failed to add late bind port group.");
                           }
                        } else {
                           log.error("Can not power on the VM");
                        }
                     } else {
                        log.error("Failed to reconfigure the VM.");
                     }
                  } else {
                     log.error("Failed to add standalone DVPorts.");
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
   @Test(description = "Move a standalone DVPort bound to a powered off VM "
               + "to a late binding DVPortGroup.")
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
    * Test cleanup. Restore VM's to original state. Delete the DVS.
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
         if (this.oldVMPowerState != null) {
            this.ivm.setVMState(this.vm1Mor, this.oldVMPowerState, false);
         }
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
