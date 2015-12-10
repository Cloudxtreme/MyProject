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
 * Move a DVPort connected to a powered on VM from the early binding DVPortgroup
 * with livePortMovingAllowed flag set to true, to a late binding DVPortgroup.
 */
public class Pos011 extends MovePortBase
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
      setTestDescription("Move a DVPort connected to a powered on VM from "
               + "the early binding DVPortgroup with livePortMovingAllowed "
               + "flag set to true, to a late binding DVPortgroup.");
   }

   /**
    * Test setup. 1. Create DVS. 2. Get A VM, used for connecting the DVPort to
    * be moved. 3. Create early binding DVPortgroup with
    * livePortMovingAllowed=true and connect the VM to a DVPort in it and use it
    * as port to be moved. 4. Create late binding DVPortgroup and use it as
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
      DVPortgroupPolicy policy = null;// used to set 'LivePortMovingAllowed'.
     
         if (super.testSetUp()) {
            hostMor = ihs.getStandaloneHost();
            if (hostMor != null) {
               dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
               vms = ivm.getAllVMs(hostMor);
               if ((dvsMor != null) && (vms != null) && (vms.size() >= 1)) {
                  vm1Mor = vms.get(0);// get the VM.
                  policy = new DVPortgroupPolicy();
                  policy.setLivePortMovingAllowed(true);
                  log.info("Adding early binding DVPortgroup...");
                  aPortGroupCfg = buildDVPortgroupCfg(
                           DVPORTGROUP_TYPE_EARLY_BINDING, 1, policy, null);
                  portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                  if (portgroupKeys != null) {
                     log.info("Added early binding DVPortgroup: "
                              + portgroupKeys);
                     // fetch the port key of this early bind port group.
                     portKeys = fetchPortKeys(dvsMor, portgroupKeys.get(0));
                     log.info("Reconfigure the VM to use DVPort.");
                     vm1DeltaCfgSpec = reconfigVM(vm1Mor, dvsMor,
                              connectAnchor, portKeys.get(0),
                              portgroupKeys.get(0));
                     if ((vm1DeltaCfgSpec != null)
                              && ivm.powerOnVM(vm1Mor, hostMor, false)) {
                        log.info("Adding the destination DVPortgroup...");
                        aPortGroupCfg = buildDVPortgroupCfg(
                                 DVPORTGROUP_TYPE_LATE_BINDING, 1, policy, null);
                        portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                        if ((portgroupKeys != null)
                                 && (portgroupKeys.size() > 0)) {
                           log.info("Successfully added late binding "
                                    + "DVPortgroup.");
                           portgroupKey = portgroupKeys.get(0);
                           status = true;
                        } else {
                           log.error("Failed to add late binding DVPortgroup.");
                        }
                     } else {
                        log.error("Failed to bind VM to DVPort.");
                     }
                  } else {
                     log.error("Failed to add early binding DVPortgroup.");
                  }
               } else {
                  log.error("Failed to get required number of VM's from host.");
               }
            } else {
               log.error("Failed to get the host.");
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
   @Test(description = "Move a DVPort connected to a powered on VM from "
               + "the early binding DVPortgroup with livePortMovingAllowed "
               + "flag set to true, to a late binding DVPortgroup.")
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
