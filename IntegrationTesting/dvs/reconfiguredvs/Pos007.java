/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Arrays;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.Event;
import com.vmware.vc.EventFilterSpec;
import com.vmware.vc.EventFilterSpecByEntity;
import com.vmware.vc.EventFilterSpecByTime;
import com.vmware.vc.EventFilterSpecRecursionOption;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.ResultsEnum;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.CreateDVSTestBase;
import dvs.EventsComparator;

/**
 * Reconfigure an existing DVS by setting the - DVSConfigSpec.configVersion to a
 * valid config version string - DVSConfigSpec.numPorts to 1016 -
 * DVSConfigSpec.maxPorts to 1015 - DVSConfigSpec.uplinkPortPolicy to {}
 */
public class Pos007 extends CreateDVSTestBase
{
   private EventManager iEvent = null;
   private ManagedObjectReference eventManagerMor = null;
   private EventFilterSpec eventFilterSpec = null;
   private ServiceInstance iServiceInstance = null;
   private ManagedObjectReference historyCollectorMor = null;

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS by setting the \n"
               + " - DVSConfigSpec.numPorts to 1016\n"
               + " - DVSConfigSpec.maxPorts to 1015\n"
               + " - DVSConfigSpec.uplinkPortPolicy to {}");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      EventFilterSpecByTime filterSpecTime = null;
      EventFilterSpecByEntity eventFilterSpecByEntity = null;

      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.iEvent = new EventManager(connectAnchor);
            this.iServiceInstance = new ServiceInstance(connectAnchor);
            this.eventManagerMor = this.iEvent.getEventManager();
            this.eventFilterSpec = new EventFilterSpec();
            eventFilterSpecByEntity = new EventFilterSpecByEntity();
            eventFilterSpecByEntity.setEntity(this.dcMor);
            eventFilterSpecByEntity.setRecursion(EventFilterSpecRecursionOption.ALL);
            this.eventFilterSpec.setEntity(eventFilterSpecByEntity);
            filterSpecTime = new EventFilterSpecByTime();
            filterSpecTime.setBeginTime(this.iServiceInstance.getServerCurrentTime());
            this.eventFilterSpec.setTime(filterSpecTime);
            this.historyCollectorMor = this.iEvent.createCollectorForEvents(
                     this.eventManagerMor, this.eventFilterSpec);
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  this.deltaConfigSpec = new DVSConfigSpec();
                  String[] uplinkPortNames = new String[1];
                  DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
                  uplinkPolicyInst.getUplinkPortName().clear();
                  uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                  String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  this.deltaConfigSpec.setMaxPorts(1016);
                  this.deltaConfigSpec.setNumStandalonePorts(1015);
                  // this.deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
                  status = true;
               } else {
                  log.error("Cannot create the distributed virtual "
                           + "switch with the config spec passed");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing DVS by setting the \n"
               + " - DVSConfigSpec.numPorts to 1016\n"
               + " - DVSConfigSpec.maxPorts to 1015\n"
               + " - DVSConfigSpec.uplinkPortPolicy to {}")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         assertTrue(status, "Test Failed");
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      Vector<Event> events = null;
      boolean founddvsPortCreatedEvent = false;
      boolean foundCreateDVSEvent = false;
      boolean foundDestroyDVSEvent = false;
      Object eventsArr[] = null;

     
         status &= super.testCleanUp();
         if (this.historyCollectorMor != null) {
            events = this.iEvent.getEvents(this.historyCollectorMor);
            if (events != null && events.size() > 0) {
               eventsArr = events.toArray();
               Arrays.sort(eventsArr, new EventsComparator());
               events = (Vector) TestUtil.arrayToVector(eventsArr);
               for (Event event : events) {
                  if (Class.forName(DVSTestConstants.EVENT_DVSCREATEDEVENT).isInstance(
                           event)) {
                     foundCreateDVSEvent = true;
                  } else if (founddvsPortCreatedEvent
                           && Class.forName(
                                    DVSTestConstants.EVENT_DVSDESTROYEDEVENT).isInstance(
                                    event)) {
                     foundDestroyDVSEvent = true;
                     break;
                  } else if (foundCreateDVSEvent
                           && Class.forName(
                                    DVSTestConstants.EVENT_DVSPORTCREATEDEVENT).isInstance(
                                    event)) {
                     founddvsPortCreatedEvent = true;
                  }
               }
            }
         }
         if (foundDestroyDVSEvent == false) {
            log.error("Failed to verify the DVS events");
            super.setOutcome(ResultsEnum.FAIL);
         } else {
            log.info("Successfully verified the events are in order");
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}