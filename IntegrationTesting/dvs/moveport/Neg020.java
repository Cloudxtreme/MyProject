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
import com.vmware.vcqa.util.TestUtil;

/**
 * Move a standalone DVPort connected to a powered on VM to early binding
 * DVPortGroup with livePortMovingAllowed flag set to false. This test is a
 * Functional Feature Acceptance Test (FFAT).
 */
public class Neg020 extends MovePortBase
{
   private ManagedObjectReference vm1Mor;
   /** deltaConfigSpec of the VM2 to restore it to Original form. */
   private VirtualMachineConfigSpec vm1DeltaCfgSpec;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a standalone DVPort connected to a "
               + "powered on VM to early binding DVPortGroup with "
               + "livePortMovingAllowed flag set to false. ");
   }

   /**
    * Test setup. 1. Create DVS. 2. Get A VM, used for connecting the DVPort to
    * be moved. 3. Create a standalone DVPort and connect VM-1 to it. 4. Create
    * early binding DVPortgroup with livePortMovingAllowed=true. 5. Use the
    * standalone DVPort as the port to be moved. 6. Use the key of the early
    * binding DVPortgroup as destination.
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
               /* Create a standalone DVPort and connect VM-1 to it. */
               portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               if ((portKeys != null) && (portKeys.size() >= 1)) {
                  vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor, connectAnchor,
                           portKeys.get(0), null);
                  if ((vm1DeltaCfgSpec != null)
                           && ivm.powerOnVM(vm1Mor, hostMor, false)) {
                     /* Create early binding DVPortgroup. */
                     policy = new DVPortgroupPolicy();
                     policy.setLivePortMovingAllowed(false);
                     aPortGroupCfg = buildDVPortgroupCfg(
                              DVPORTGROUP_TYPE_EARLY_BINDING, 1, policy, null);
                     portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                     if ((portgroupKeys != null) && (portgroupKeys.size() >= 1)) {
                        log.info("Successfully added early bind port group.");
                        portgroupKey = portgroupKeys.get(0);
                        status = true;
                     } else {
                        log.error("Failed to add late bind port group.");
                     }
                  } else {
                     log.error("Failed to reconfigure the VM to use DVPort.");
                  }
               }
            } else {
               log.error("Failed to get required number of VM's from host.");
            }
         } else {
            log.error("Unable to login.");
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
   @Test(description = "Move a standalone DVPort connected to a "
               + "powered on VM to early binding DVPortGroup with "
               + "livePortMovingAllowed flag set to false. ")
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
