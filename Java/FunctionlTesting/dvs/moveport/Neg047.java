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
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.TestUtil;

/**
 * Move a DVPort connected to a powered off VM from a early binding DVPortgroup
 * with livePortMovingAllowed = true, to an late binding DVPortgroup with
 * livePortMovingAllowed = false. </br> Procedure:</br> Setup:</br> 1. Create a
 * DVS.</br> 2. Get A VM, used for connecting the DVPort to be moved.</br> 3.
 * Create early binding DVPortgroup with livePortMovingAllowed=true and connect
 * the VM to a DVPort in it and use it as port to be moved.</br> 4. Verify power
 * ops the VM.</br> 5. Create late binding DVPortGroup with
 * livePortMovingAllowed=false and use it as destination.</br> Test:</br> 6.
 * Move the DVPort to destination.</br> Cleanup:</br> 7. Delete the DVS and
 * logout.</br>
 */
public class Neg047 extends MovePortBase
{
   private ManagedObjectReference vm1Mor = null;
   /** deltaConfigSpec of the VM1 to restore it to Original form. */
   private VirtualMachineConfigSpec vm1DeltaCfgSpec = null;
   private VirtualMachinePowerState oldPowerState = null;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort connected to a powered off VM from "
               + "a early binding DVPortgroup with livePortMovingAllowed = true"
               + ", to an late binding DVPortgroup with "
               + "livePortMovingAllowed = false.");
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
            vms = ihs.getAllVirtualMachine(hostMor);
            if ((vms != null) && (vms.size() >= 1)) {
               vm1Mor = vms.get(0);// get the VM.
               policy = new DVPortgroupPolicy();
               policy.setLivePortMovingAllowed(true);
               aPortGroupCfg = buildDVPortgroupCfg(
                        DVPORTGROUP_TYPE_EARLY_BINDING, 1, policy, null);
               portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
               if (portgroupKeys != null) {
                  log.info("Added early binding DVPortgroup: "
                           + portgroupKeys);
                  portKeys = fetchPortKeys(dvsMor, portgroupKeys.get(0));
                  if ((portKeys != null) && (portKeys.size() >= 1)) {
                     log.info("Reconfigure the VM to use DVPort."
                              + portKeys);
                     vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor,
                              connectAnchor, portKeys.get(0),
                              portgroupKeys.get(0));
                     if (vm1DeltaCfgSpec != null) {
                        this.oldPowerState = this.ivm.getVMState(this.vm1Mor);
                        if (this.ivm.setVMState(this.vm1Mor, POWERED_ON, false)) {
                           log.info("Successfully powered on the VM");
                           log.info("Adding the destination DVPortgroup...");
                           policy = new DVPortgroupPolicy();
                           policy.setLivePortMovingAllowed(false);
                           aPortGroupCfg = buildDVPortgroupCfg(
                                    DVPORTGROUP_TYPE_LATE_BINDING, 0, policy,
                                    null);
                           portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                           if ((portgroupKeys != null)
                                    && (portgroupKeys.size() >= 1)) {
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
                        log.error("Failed to reconfigure the VM to use DVPort.");
                     }
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
   @Test(description = "Move a DVPort connected to a powered off VM from "
               + "a early binding DVPortgroup with livePortMovingAllowed = true"
               + ", to an late binding DVPortgroup with "
               + "livePortMovingAllowed = false.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedMethodFault = new InvalidArgument();
      try {
         movePort(dvsMor, portKeys, portgroupKey);
         log.error("Successfully moved the port into the destination portgroup");
      } catch (Exception mfExcep) {
         MethodFault mf = com.vmware.vcqa.util.TestUtil.getFault(mfExcep);
         status = TestUtil.checkMethodFault(mf, expectedMethodFault);
      }
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
         if (this.oldPowerState != null) {
            status &= this.ivm.setVMState(this.vm1Mor, this.oldPowerState,
                     false);
         }
         if ((this.vm1DeltaCfgSpec != null)
                  && this.ivm.setVMState(this.vm1Mor, POWERED_OFF, false)) {
            status = ivm.reconfigVM(vm1Mor, vm1DeltaCfgSpec);
         } else {
            log.error("failed to power off the VM.");
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
