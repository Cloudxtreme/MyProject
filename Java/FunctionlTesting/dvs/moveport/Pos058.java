/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.moveport;

import static com.vmware.vcqa.util.Assert.assertNotEmpty;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_LATE_BINDING;

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
 * Move a DVPort connected to a powered off VM from a late binding DVPortgroup
 * with livePortMovingAllowed = true, to a late binding DVPortgroup with
 * livePortMovingAllowed = false. <br>
 * Procedure:<br>
 * SETUP:<br>
 * 1. Create a DVS.<br>
 * 2. Get a VM, used for connecting the DVPort to be moved.<br>
 * 3. Create late binding DVPortgroup with livePortMovingAllowed = true and
 * connect the VM to a DVPort in it and use it as port to be moved.<br>
 * 4. Create late binding DVPortGroup with livePortMovingAllowed = false and use
 * it as destination.<br>
 * TEST:<br>
 * 5. Move the DVPort to destination, should be successful.<br>
 * CLEANUP:<br>
 * 6. Restore the VM to its original configuration. <br>
 * 7. Delete the DVS and logout.<br>
 */
public class Pos058 extends MovePortBase
{
   private ManagedObjectReference vm1Mor;
   /** deltaConfigSpec of the VM to restore it to Original form. */
   private VirtualMachineConfigSpec vmDeltaCfgSpec;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Move a DVPort connected to a powered off VM from "
               + "a late binding DVPortgroup with livePortMovingAllowed = true"
               + ", to a late binding DVPortgroup with "
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
      List<String> portgroupKeys = null;
      List<ManagedObjectReference> vms = null;
      DVPortgroupConfigSpec aPortGroupCfg = null;
      DVPortgroupPolicy policy = null;// used to set 'LivePortMovingAllowed'.
      assertTrue(super.testSetUp(), "testSetUp failed");
      hostMor = ihs.getStandaloneHost();
      assertNotNull(hostMor, "Unable to find host");
      dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
      assertNotNull(dvsMor, "Unable to create  DistributedVirtualSwitc");
      vms = ihs.getAllVirtualMachine(hostMor);
      assertTrue((vms != null && vms.size() >= 1),
               "Failed to get required number of VM's from host.");
      vm1Mor = vms.get(0);// get the VM.
      assertNotNull(vm1Mor, "Unable to vm");
      log.info("Adding late binding DVPortgroup...");
      policy = new DVPortgroupPolicy();
      policy.setLivePortMovingAllowed(true);
      aPortGroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_LATE_BINDING, 1,
               policy, null);
      portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
      assertTrue((portgroupKeys != null), "Added late binding DVPortgroup: "
               + portgroupKeys, "Failed to addPortgroups");
      log.info("Added late binding DVPortgroup: " + portgroupKeys);
      portKeys = fetchPortKeys(dvsMor, portgroupKeys.get(0));
      assertTrue((portKeys != null && portKeys.size() >= 1),
               "Failed to get portKey");
      log.info("Reconfigure the VM to use DVPort." + portKeys);
      vmDeltaCfgSpec = reconfigVM(vm1Mor, dvsMor, connectAnchor,
               portKeys.get(0), portgroupKeys.get(0));
      assertTrue((vmDeltaCfgSpec != null && ivm.setVMState(vm1Mor, VirtualMachinePowerState.POWERED_OFF, false)),
               "Failed to reconfigure the VM to use DVPort.");
      log.info("Adding the destination DVPortgroup...");
      policy = new DVPortgroupPolicy();
      policy.setLivePortMovingAllowed(false);
      aPortGroupCfg = buildDVPortgroupCfg(DVPORTGROUP_TYPE_LATE_BINDING, 1,
               policy, null);
      portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
      assertNotEmpty(portgroupKeys, "Successfully added early binding "
               + "DVPortgroup.", "Failed to add late bind port group.");
      portgroupKey = portgroupKeys.get(0);
      return true;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Move a DVPort connected to a powered off VM from "
               + "a late binding DVPortgroup with livePortMovingAllowed = true"
               + ", to a late binding DVPortgroup with "
               + "livePortMovingAllowed = false.")
   public void test()
      throws Exception
   {

      assertTrue(movePort(dvsMor, portKeys, portgroupKey), "Test failed");
   }

   /**
    * Test cleanup. Restore VM's to original state. Delete the DVS.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
     
         if (vmDeltaCfgSpec != null) {
            status &= ivm.reconfigVM(vm1Mor, vmDeltaCfgSpec);
         } else {
            log.error("failed to power off the VM.");
         }
     
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;

   }
}
