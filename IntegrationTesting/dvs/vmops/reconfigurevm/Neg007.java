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
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.Event;
import com.vmware.vc.EventFilterSpec;
import com.vmware.vc.EventFilterSpecByEntity;
import com.vmware.vc.EventFilterSpecByTime;
import com.vmware.vc.EventFilterSpecRecursionOption;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.EventsComparator;
import dvs.vmops.VMopsBase;

/**
 * Test to verify bug 396149 scenario 1 Create DVS. Create Standalone port to
 * it. Connect it to VM. Then reconfigure DVS to change numStandalonePorts to 0.
 */
public class Neg007 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String dvSwitchUuid = null;
   private String portKey = null;
   private ManagedObjectReference vmMor = null;
   private EventManager iEvent = null;
   private ManagedObjectReference eventManagerMor = null;
   private EventFilterSpec eventFilterSpec = null;
   private ServiceInstance iServiceInstance = null;
   private ManagedObjectReference historyCollectorMor = null;
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Test to verify bug 396149 scenario 1\n"
               + " 1.Create DVS\n" + " 2.Create Standalone port to it\n"
               + " 3.Connect it to VM\n"
               + " 4.Then reconfigure DVS to change numStandalonePorts to 0.\n");

   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the VM ConfigSpec.
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
      EventFilterSpecByTime filterSpecTime = null;
      EventFilterSpecByEntity eventFilterSpecByEntity = null;

      List<String> portKeys = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
         try {
            hostMor = ihs.getStandaloneHost();
            log.info("Host MOR: " + hostMor);
            log.info("Host Name: " + ihs.getHostName(hostMor));
            iEvent = new EventManager(connectAnchor);
            iServiceInstance = new ServiceInstance(connectAnchor);
            eventManagerMor = iEvent.getEventManager();
            eventFilterSpec = new EventFilterSpec();
            eventFilterSpecByEntity = new EventFilterSpecByEntity();
            eventFilterSpecByEntity.setEntity(ihs.getDataCenter());
            eventFilterSpecByEntity.setRecursion(EventFilterSpecRecursionOption.ALL);
            eventFilterSpec.setEntity(eventFilterSpecByEntity);
            filterSpecTime = new EventFilterSpecByTime();
            filterSpecTime.setBeginTime(iServiceInstance.getServerCurrentTime());
            eventFilterSpec.setTime(filterSpecTime);
            historyCollectorMor = iEvent.createCollectorForEvents(
                     eventManagerMor, eventFilterSpec);

            // create the DVS by using standalone host.

            dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
            Thread.sleep(10000);// Sleep for 10 Sec
            nwSystemMor = ins.getNetworkSystem(hostMor);
            if (ins.refresh(nwSystemMor)) {
               log.info("refreshed");
            }

            // add the pnics to DVS
            hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                     dvsMor, hostMor);
            if (hostNetworkConfig != null && hostNetworkConfig.length == 2) {
               log.info("Found the network config.");
               // update the network to use the DVS.
               networkUpdated = ins.updateNetworkConfig(nwSystemMor,
                        hostNetworkConfig[0], TestConstants.CHANGEMODE_MODIFY);

               if (networkUpdated) {

                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);

                  if (portKeys != null) {
                     log.info("Successfully get the standalone DVPortkeys");
                     portKey = portKeys.get(0);
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();

                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, portKey, null);
                     vmConfigSpec = buildCreateVMCfg(dvsPortConnection,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32, hostMor);
                     log.info("Successfully created VMConfig spec.");
                     status = true;
                  }

                  else {
                     log.error("Failed to get the standalone DVPortkeys ");
                  }
               } else {
                  log.error("Failed to find network config.");
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
    * operations. 3. Set number of standalone ports to 1. 4. Reconfigure DVS.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = " Test to verify bug 396149 scenario 1\n"
               + " 1.Create DVS\n" + " 2.Create Standalone port to it\n"
               + " 3.Connect it to VM\n"
               + " 4.Then reconfigure DVS to change numStandalonePorts to 0.\n")
   public void test()
      throws Exception
   {
      boolean status = false;
      try {
         vmMor = new Folder(super.getConnectAnchor()).createVM(
                  ivm.getVMFolder(), vmConfigSpec, ihs.getPoolMor(hostMor),
                  hostMor);
         if (vmMor != null) {
            log.info("Successfully created VM.");
            status = verify(vmMor, null, vmConfigSpec);

            log.info("Set stand alone ports to 0 and reconfigureDVS");
            deltaConfigSpec = new DVSConfigSpec();
            String validConfigVersion = iDVSwitch.getConfig(dvsMor).getConfigVersion();
            deltaConfigSpec.setConfigVersion(validConfigVersion);
            deltaConfigSpec.setNumStandalonePorts(0);
            iDVSwitch.reconfigure(dvsMor, deltaConfigSpec);
         } else {
            log.error("Unable to create VM.");
         }

      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         InvalidArgument expectedMethodFault = new InvalidArgument();
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
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      Vector<Event> events = null;
      boolean foundCreateDVSEvent = false;
      boolean foundDvsPortConnectedEvent = false;
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