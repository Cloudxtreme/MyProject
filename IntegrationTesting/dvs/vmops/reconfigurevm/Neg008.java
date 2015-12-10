/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Set;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.Event;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.LimitExceeded;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.EventsComparator;
import dvs.vmops.VMopsBase;

/**
 * Test to verify bug 396149 scenario 2 Create DVS. Create Standalone port to
 * it. Set Maximum ports to 1. Then reconfigure DVS to change Maximum Ports to
 * 0.
 */
public class Neg008 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private String dvSwitchUuid = null;
   private String portKey = null;
   private ManagedObjectReference vmMor = null;
   private EventManager iEvent = null;
   private ManagedObjectReference historyCollectorMor = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Test to verify bug 396149 scenario 2\n"
               + " 1.Create DVS\n" + " 2.Create Standalone port to it\n"
               + " 3.Set Maximum ports to 1\n"
               + " 4.Then reconfigure DVS to change Maximum Ports to 0\n");

   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the Standalone DVPort. 3.Set Maxports to 1. 4. Create the
    * VMConfigSpec.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVSConfigSpec dvsConfigSpec = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      HashMap allHosts = null;
      DistributedVirtualSwitchPortConnection portConnection = null;

      log.info("test setup Begin:");
      if (super.testSetUp()) {
         try {

            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            Set hostsSet = allHosts.keySet();
            if (hostsSet != null && hostsSet.size() > 0) {
               Iterator hostsItr = hostsSet.iterator();
               if (hostsItr.hasNext()) {
                  hostMor = (ManagedObjectReference) hostsItr.next();
               }

               if (hostMor != null) {
                  String[] freePnics = ins.getPNicIds(hostMor);
                  if (freePnics != null && freePnics.length > 0) {
                     nwSystemMor = ins.getNetworkSystem(hostMor);
                     if (nwSystemMor != null) {
                        hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
                        hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
                        hostMember.setHost(hostMor);
                        pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                        pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                        pnicSpec.setPnicDevice(freePnics[0]);
                        pnicBacking.getPnicSpec().clear();
                        pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                        hostMember.setBacking(pnicBacking);
                        dvsConfigSpec = new DVSConfigSpec();
                        dvsConfigSpec.setConfigVersion("");
                        dvsConfigSpec.setName(getTestId());
                        dvsConfigSpec.setNumStandalonePorts(1);
                        dvsConfigSpec.setMaxPorts(1);
                        dvsConfigSpec.getHost().clear();
                        dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
                        dvsMor = iFolder.createDistributedVirtualSwitch(
                                 iFolder.getNetworkFolder(iFolder.getDataCenter()),
                                 dvsConfigSpec);
                        if (dvsMor != null
                                 && ins.refresh(nwSystemMor)
                                 && iDVSwitch.validateDVSConfigSpec(dvsMor,
                                          dvsConfigSpec, null)) {
                           log.info("Successfully created the distributed "
                                    + "virtual switch");
                           DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                           dvSwitchUuid = info.getUuid();
                           portConnection = new DistributedVirtualSwitchPortConnection();
                           portConnection.setSwitchUuid(dvSwitchUuid);
                           portConnection.setPortKey(portKey);
                           vmConfigSpec = buildCreateVMCfg(portConnection,
                                    VM_VIRTUALDEVICE_ETHERNET_PCNET32, hostMor);
                           log.info("Successfully created VMConfig spec.");
                           status = true;
                        }

                     }
                  }
               }
            }
         }

         catch (Exception e) {
            TestUtil.handleException(e);
         }

      }

      Assert.assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the VM. 2. Verify the ConfigSpecs and Power-ops
    * operations. 3.Reconfigure DVS. 4. Set Maximum ports to 0.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = " Test to verify bug 396149 scenario 2\n"
               + " 1.Create DVS\n" + " 2.Create Standalone port to it\n"
               + " 3.Set Maximum ports to 1\n"
               + " 4.Then reconfigure DVS to change Maximum Ports to 0\n")
   public void test()
      throws Exception
   {
      boolean status = false;
      DVSConfigSpec dvsConfigSpec = null;

      try {
         vmMor = new Folder(super.getConnectAnchor()).createVM(
                  ivm.getVMFolder(), vmConfigSpec, ihs.getPoolMor(hostMor),
                  hostMor);
         if (vmMor != null) {
            log.info("Successfully created VM.");
            status = verify(vmMor, null, vmConfigSpec);
            log.info("Reconfigurdvs to set max ports to 0");
            dvsConfigSpec = new DVSConfigSpec();
            dvsConfigSpec.setMaxPorts(0);
            dvsConfigSpec.setConfigVersion(iDVSwitch.getConfigSpec(dvsMor).getConfigVersion());
            iDVSwitch.reconfigure(dvsMor, dvsConfigSpec);

         } else {
            log.error("Unable to create VM.");
         }

      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         LimitExceeded expectedMethodFault = new LimitExceeded();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
      }

   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      Vector<Event> events = null;
      boolean foundCreateDVSEvent = false;
      boolean foundDvsPortConnectedEvent = false;
      boolean foundDvsPortLinkUpEvent = false;
      boolean foundDvsPortDisconnectedEvent = false;
      Object eventsArr[] = null;

      try {
         if (historyCollectorMor != null) {
            events = iEvent.getEvents(historyCollectorMor);
            if (events != null && events.size() > 0) {
               eventsArr = events.toArray();
               Arrays.sort(eventsArr, new EventsComparator());
               events = (Vector) TestUtil.arrayToVector(eventsArr);
               for (Event event : events) {
                  if (Class.forName(DVSTestConstants.EVENT_DVSCREATEDEVENT).isInstance(
                           event)) {
                     foundCreateDVSEvent = true;
                  } else if (foundCreateDVSEvent
                           && Class.forName(
                                    DVSTestConstants.EVENT_DVSPORTCONNECTEDEVENT).isInstance(
                                    event)) {
                     foundDvsPortConnectedEvent = true;
                  } else if (foundCreateDVSEvent
                           && Class.forName(
                                    DVSTestConstants.EVENT_DVSPORTLINKUPEVENT).isInstance(
                                    event)) {
                     foundDvsPortLinkUpEvent = true;
                  } else if (foundDvsPortConnectedEvent
                           && Class.forName(
                                    DVSTestConstants.EVENT_DVSPORTDISCONNECTEDEVENT).isInstance(
                                    event)) {
                     foundDvsPortDisconnectedEvent = true;
                  }
               }
            }
         } else {
            log.info("Successfully verified the events are in order");
         }
         if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            status = destroy(vmMor);// destroy the VM.
            /*
             * DvsEvent verification
             */

         } else {
            log.warn("VM not found");
         }

      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      try {
         if (networkUpdated) {
            // restore the network to use the DVS.

            status &= ins.updateNetworkConfig(nwSystemMor,
                     hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }

      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }
}