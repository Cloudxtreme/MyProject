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

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * Move a standalone DVPort bound to a powered off VM to a late binding
 * DVPortgroup.
 */
public class Neg014 extends MovePortBase
{
   private HostNetworkConfig[] hostNetworkConfig;
   ManagedObjectReference vm1Mor = null;
   /** deltaConfigSpec of the VM1 to restore it to Original form. */
   private VirtualMachineConfigSpec vm1DeltaCfgSpec;
   private boolean updated;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a standalone DVPort bound to a powered off "
               + "VM to a late binding DVPortgroup.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create standalone DVPort and use it as port
    * to be moved. 3. Reconfigure the VM to use this standalone DVPort. 4.
    * Create late binding DVPortgroup and use it as destination.
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
      List<ManagedObjectReference> vms = null;
     
         if (super.testSetUp()) {
            hostMor = ihs.getStandaloneHost();
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            if (dvsMor != null) {
               vms = ivm.getAllVMs(hostMor);
               if ((vms != null) && !vms.isEmpty()) {
                  vm1Mor = vms.get(0);
                  if (ins.refresh(ins.getNetworkSystem(hostMor))) {
                     log.info("Refreshed the network.");
                  }
                  // update the network to use the DVS.
                  hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           dvsMor, hostMor);
                  updated = ins.updateNetworkConfig(
                           ins.getNetworkSystem(hostMor), hostNetworkConfig[0],
                           TestConstants.CHANGEMODE_MODIFY);
                  if (updated) {
                     log.info("Successfully updated the network to use DVS.");
                     log.info("Adding standalone DVPort...");
                     portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
                     if ((portKeys != null) && (portKeys.size() >= 1)) {
                        log.info("Reconfigure the VM to use standalone DVPort.");
                        vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor,
                                 connectAnchor, portKeys.get(0), null);
                        if ((vm1DeltaCfgSpec != null)
                                 && ivm.verifyPowerOps(vm1Mor, false)) {
                           log.info("Adding the destination DVPortgroup...");
                           portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                                    DVPORTGROUP_TYPE_LATE_BINDING, 1, prefix
                                             + "PG-Late");
                           if (portgroupKey != null) {
                              log.info("Successfully created late binding"
                                       + " port group.");
                              status = true;
                           } else {
                              log.error("Failed to create late binding "
                                       + "DVPortgroup.");
                           }
                        } else {
                           log.error("Successfully reconfigured the VM.");
                        }
                     } else {
                        log.error("Failed to get DVPort.");
                     }
                  } else {
                     log.error("Failed to update the network.");
                  }
               }
            } else {
               log.error("Failed to create DVS.");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. Move the DVPort in the DVPortgroup by providing null port key.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a standalone DVPort bound to a powered off "
               + "VM to a late binding DVPortgroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
      MethodFault expectedFault = new InvalidArgument();
      try {
         movePort(dvsMor, portKeys, portgroupKey);
         log.error("API didn't throw any exception.");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         status = TestUtil.checkMethodFault(actualMethodFault, expectedFault);
      }
      if (!status) {
         log.error("API didn't throw expected exception: "
                  + expectedFault.getClass().getSimpleName());
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
         if (updated) {
            status &= ins.updateNetworkConfig(ins.getNetworkSystem(hostMor),
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
         } else {
            status = false;
            log.error("Failed to restore the network config.");
         }
      } catch (Exception e) {
         status = false;
         TestUtil.handleException(e);
      }
      try {
         if ((vm1DeltaCfgSpec != null)
                  && ivm.setVMState(vm1Mor, POWERED_OFF, false)) {
            status &= ivm.reconfigVM(vm1Mor, vm1DeltaCfgSpec);
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
