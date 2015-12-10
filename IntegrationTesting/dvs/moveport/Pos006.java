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
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Move a DVPort in a late binding DVPortGroup having scope set to VM1, to early
 * binding DVPortGroup having the scope set to VM2.
 */
public class Pos006 extends MovePortBase
{
   private ManagedObjectReference vm1Mor;
   private ManagedObjectReference vm2Mor;
   /** deltaConfigSpec of the VM2 to restore it to Original form. */
   private VirtualMachineConfigSpec vm2DeltaCfgSpec;
   private List<String> portgroupKeys = null;

   /**
    * Set the brief description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Move a DVPort in a late binding DVPortGroup "
               + "having scope set to VM1, to early binding DVPortGroup "
               + "having the scope set to VM2.");
   }

   /**
    * Test setup. Create DVS. Get 2 VM's. Create late binding DVPortGroup with
    * VM-1 in scope. Create early binding DVPortGroup with VM-2 in scope.
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
      DVPortgroupConfigSpec aPortGroupCfg = null;
     
         if (super.testSetUp()) {
            hostMor = ihs.getStandaloneHost();
            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            vms = ihs.getAllVirtualMachine(hostMor);
            if ((vms != null) && (vms.size() >= 2)) {
               vm1Mor = vms.get(0);// get the first VM.
               vm2Mor = vms.get(1);// get the second VM.
               /* Add late binding port group. */
               aPortGroupCfg = buildDVPortgroupCfg(
                        DVPORTGROUP_TYPE_LATE_BINDING, 1, null, vm1Mor);
               portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
               if (portgroupKeys != null) {
                  log.info("Added late bind port group.");
                  // fetch the port key of this late bind port group.
                  portKeys = fetchPortKeys(dvsMor, portgroupKeys.get(0));
                  /* now add early bind port group. */
                  aPortGroupCfg = buildDVPortgroupCfg(
                           DVPORTGROUP_TYPE_EARLY_BINDING, 1, null, vm2Mor);
                  portgroupKeys = addPortgroups(dvsMor, aPortGroupCfg);
                  if ((portgroupKeys != null) && (portgroupKeys.size() > 0)) {
                     log.info("Successfully added early bind port group.");
                     portgroupKey = portgroupKeys.get(0);
                     status = true;
                  } else {
                     log.error("Failed to add early binding DVPortgroup.");
                  }
               } else {
                  log.error("Failed to add late binding DVPortgroup.");
               }
            } else {
               log.error("failed to get required number of VM's.");
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
   @Test(description = " Move a DVPort in a late binding DVPortGroup "
               + "having scope set to VM1, to early binding DVPortGroup "
               + "having the scope set to VM2.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         Map<String, DistributedVirtualPort> connectedEntitiespMap = DVSUtil.getConnecteeInfo(
                  connectAnchor, dvsMor, portKeys);
         status = movePort(dvsMor, portKeys, portgroupKey);
         status &= DVSUtil.verifyConnecteeInfoAfterMovePort(connectAnchor,
                  connectedEntitiespMap, dvsMor, portKeys, portgroupKey);

         // Check whether the VM2 can bind to this DVPort.
         vm2DeltaCfgSpec = reconfigVM(vm2Mor, dvsMor, connectAnchor,
                  portKeys.get(0), portgroupKeys.get(0));
         if ((vm2DeltaCfgSpec != null) && ivm.verifyPowerOps(vm2Mor, false)) {
            log.info("Successfully bound VM2 to moved DVPort.");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Test cleanup. * Delete the VM's. * Delete the DVS.
    * 
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
      try {
         if ((vm2DeltaCfgSpec != null)
                  && ivm.setVMState(vm2Mor, POWERED_OFF, false)) {
            status = ivm.reconfigVM(vm2Mor, vm2DeltaCfgSpec);
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
