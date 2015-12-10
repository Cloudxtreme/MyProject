/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.createvm;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.Arrays;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.Event;
import com.vmware.vc.EventFilterSpec;
import com.vmware.vc.EventFilterSpecByEntity;
import com.vmware.vc.EventFilterSpecByTime;
import com.vmware.vc.EventFilterSpecRecursionOption;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ResultsEnum;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.EventsComparator;
import dvs.vmops.VMopsBase;

/**
 * Create a VM on a standalone host to connect to an existing earlyBinding
 * DVPortgroup.The device is of type VirtualPCNet32,the backing is of type
 * DVPort backing and the port connection is a DVPortgroup connection.
 */
public class Pos005 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private String dvSwitchUuid = null;
   private ManagedObjectReference vmMor = null;

   private EventManager iEvent = null;
   private ManagedObjectReference eventManagerMor = null;
   private EventFilterSpec eventFilterSpec = null;
   private ServiceInstance iServiceInstance = null;
   private ManagedObjectReference historyCollectorMor = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create a VM on a Standalone host to connect to"
               + "an existing earlyBinding DVPortgroup.");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the earlyBinding DVPortgroup. 3. Create the VMConfigSpec
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
      String portgroupKey = null;
      EventFilterSpecByTime filterSpecTime = null;
      EventFilterSpecByEntity eventFilterSpecByEntity = null;

      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            hostMor = ihs.getStandaloneHost();
            log.info("Host MOR: " + hostMor);
            // create the DVS by using standalone host.
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
                  portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                           DVPORTGROUP_TYPE_EARLY_BINDING, 1,
                           DVSTestConstants.DV_PORTGROUP_CREATE_NAME_PREFIX
                                    + "-pg1");
                  if (portgroupKey != null) {
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, null, portgroupKey);
                     vmConfigSpec = buildCreateVMCfg(dvsPortConnection,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32, hostMor);
                     log.info("Successfully created VMConfig spec.");
                     status = true;
                  } else {
                     log.error("Failed to add the portgroup to DVS.");
                  }
               } else {
                  log.error("Failed to find network config.");
               }
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the VM. 2. Verify the configSpecs and power-ops
    * operations.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Create a VM on a Standalone host to connect to"
               + "an existing earlyBinding DVPortgroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
     
         vmMor = new Folder(super.getConnectAnchor()).createVM(
                  ivm.getVMFolder(), vmConfigSpec, ihs.getPoolMor(hostMor),
                  hostMor);
         if (vmMor != null) {
            log.info("Successfully created VM.");
            status = verify(vmMor, null, vmConfigSpec);
         } else {
            log.error("Unable to create VM.");
         }
     
      assertTrue(status, "Test Failed");
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
      boolean status = false;
      Vector<Event> events = null;
      boolean foundCreateDVSEvent = false;
      boolean foundDvsPortConnectedEvent = false;
      boolean foundDvsPortLinkUpEvent = false;
      boolean foundDvsPortLinkDownEvent = false;
      boolean foundDvsPortDisconnectedEvent = false;
      Object eventsArr[] = null;
      try {
         if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
            status = destroy(vmMor);// destroy the VM.

            /*
             * DvsEvent verification
             */

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
                     } else if (foundDvsPortConnectedEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVSPORTLINKUPEVENT).isInstance(
                                       event)) {
                        foundDvsPortLinkUpEvent = true;
                     } else if (foundDvsPortLinkUpEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVSPORTLINKDOWNEVENT).isInstance(
                                       event)) {
                        foundDvsPortLinkDownEvent = true;
                     } else if (foundDvsPortLinkDownEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVSPORTDISCONNECTEDEVENT).isInstance(
                                       event)) {
                        foundDvsPortDisconnectedEvent = true;
                        break;
                     }
                  }
               }
            }
            if (foundDvsPortDisconnectedEvent == false) {
               log.error("Failed to verify the DVS events");
               super.setOutcome(ResultsEnum.FAIL);
            } else {
               log.info("Successfully verified the events are in order");
            }
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
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
