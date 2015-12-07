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
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;

/**
 * Move a DVPort bound to a VM, from an early binding DVPortgroup to a late
 * binding DVPortgroup with bindingOnHostAllowed�= false.
 */
public class Neg017 extends MovePortBase
{
   private HostNetworkConfig[] hostNetworkConfig;
   ManagedObjectReference vm1Mor = null;
   /** deltaConfigSpec of the VM to restore it to Original form. */
   private VirtualMachineConfigSpec vm1DeltaCfgSpec;
   private boolean updated;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort bound to a VM, from an early "
               + "binding port group to a late binding DVPortGroup with "
               + "bindingOnHostAllowed�=false.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Create early binding DVPortgroup with one
    * port in it. 4. Reconfigure the VM to use the DVPort of early binding
    * DVPortgroup. 5. Create late binding DVPortgroup with one port in it. 6.
    * Use the DVPort early binding DVPortgroup as port key. 7. Use the key of
    * late binding DVPortgroup as destination.
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
      List<String> portgroupKeys = null;
      DVPortgroupConfigSpec aPortGroupCfg = null;
      DVPortgroupPolicy policy = null;
     
         if (super.testSetUp()) {
            hostMor = ihs.getStandaloneHost();
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            if (dvsMor != null) {
               vms = ivm.getAllVMs(hostMor);
               if ((vms != null) && !vms.isEmpty()) {
                  vm1Mor = vms.get(0);
                  Thread.sleep(10000);// FIXME remove this.
                  if (ins.refresh(ins.getNetworkSystem(hostMor))) {
                     log.info("refreshed");
                  }
                  // update the network to use the DVS.
                  hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           dvsMor, hostMor);
                  updated = ins.updateNetworkConfig(
                           ins.getNetworkSystem(hostMor), hostNetworkConfig[0],
                           TestConstants.CHANGEMODE_MODIFY);
                  if (updated) {
                     log.info("Successfully updated the network to use DVS.");
                     portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                              DVPORTGROUP_TYPE_EARLY_BINDING, 1, prefix
                                       + "PG-Early");
                     if (portgroupKey != null) {
                        portKeys = fetchPortKeys(dvsMor, portgroupKey);
                        if ((portKeys != null) && (portKeys.size() >= 1)) {
                           log.info("Reconfigure the VM to use DVPort.");
                           vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor,
                                    connectAnchor, portKeys.get(0),
                                    portgroupKey);
                           if ((vm1DeltaCfgSpec != null)
                                    && ivm.verifyPowerOps(vm1Mor, false)) {
                              log.info("Adding the destination DVPortgroup...");
                              policy = new DVPortgroupPolicy();
                              aPortGroupCfg = buildDVPortgroupCfg(
                                       DVPORTGROUP_TYPE_LATE_BINDING, 1,
                                       policy, null);
                              portgroupKeys = addPortgroups(dvsMor,
                                       aPortGroupCfg);
                              if ((portgroupKeys != null)
                                       && !portgroupKeys.isEmpty()) {
                                 log.info("Successfully created early binding"
                                          + " DVPortgroup.");
                                 portgroupKey = portgroupKeys.get(0);
                                 status = true;
                              } else {
                                 log.error("Failed to add destination "
                                          + "DVPortgroup.");
                              }
                           } else {
                              log.error("Successfully reconfigured the VM.");
                           }
                        } else {
                           log.error("Failed to get DVPort from the early "
                                    + "bind DVPortgroup.");
                        }
                     } else {
                        log.error("Failed to add the port group.");
                     }
                  } else {
                     log.error("Failed to update the network.");
                  }
               } else {
                  log.error("Failed to get required VM.");
               }
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
   @Test(description = "Move a DVPort bound to a VM, from an early "
               + "binding port group to a late binding DVPortGroup with "
               + "bindingOnHostAllowed�=false.")
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
         // get the VM's to previous state.
         try {
            if ((vm1DeltaCfgSpec != null)
                     && ivm.setVMState(vm1Mor, POWERED_OFF, false)) {
               status = ivm.reconfigVM(vm1Mor, vm1DeltaCfgSpec);
            }
         } catch (Exception e) {
            TestUtil.handleException(e);
         }
         if (updated) {
            status &= ins.updateNetworkConfig(ins.getNetworkSystem(hostMor),
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
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
