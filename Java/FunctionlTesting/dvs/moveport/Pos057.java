/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.TestUtil;

/**
 * Move a DVPort connected to a powered on VM from a early binding DVPortgroup
 * with livePortMovingAllowed = false, to same DVPortGroup
 */
public class Pos057 extends MovePortBase
{
   private ManagedObjectReference vm1Mor;
   /** deltaConfigSpec of the VM1 to restore it to Original form. */
   private VirtualMachineConfigSpec vm1DeltaCfgSpec;
   private String portKey = null;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort connected to a powered on VM from "
               + "a early binding DVPortgroup with "
               + "livePortMovingAllowed = false, to same DVPortGroup ");
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
               policy.setLivePortMovingAllowed(false);
               aPortGroupCfg = buildDVPortgroupCfg(
                        DVPORTGROUP_TYPE_EARLY_BINDING, 1, policy, null);
               portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
               if (portgroupKeys != null) {
                  portgroupKey = portgroupKeys.get(0);
                  log.info("Added early binding DVPortgroup: "
                           + portgroupKey);
                  portKeys = fetchPortKeys(dvsMor, portgroupKeys.get(0));
                  if ((portKeys != null) && (portKeys.size() >= 1)) {
                     this.portKey = portKeys.get(0);
                     log.info("Obtained portKey " + this.portKey
                              + " from " + " portgroupKey :  " + portgroupKey);
                     log.info("Reconfigure the VM to use DVPort."
                              + portKey + " PGkey :" + portgroupKey);
                     vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor,
                              connectAnchor, portKey, portgroupKeys.get(0));
                     if ((vm1DeltaCfgSpec != null)
                              && ivm.verifyPowerOps(vm1Mor, false)) {
                        status = true;
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
    * @throws Exception
    */
   @Override
   @Test(description = "Move a DVPort connected to a powered on VM from "
               + "a early binding DVPortgroup with "
               + "livePortMovingAllowed = false, to same DVPortGroup ")
   public void test()
      throws Exception
   {
      assertTrue(ivm.setVMState(vm1Mor, VirtualMachinePowerState.POWERED_ON, false), "Powered on the vm", "Failed to power on the vm");
      assertTrue(movePort(dvsMor, portKeys, portgroupKey), "Successfully "
               + "moved the port", "Failed to move the port");
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
