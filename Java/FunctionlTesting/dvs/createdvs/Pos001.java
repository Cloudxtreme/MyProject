/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Arrays;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.Event;
import com.vmware.vc.EventFilterSpec;
import com.vmware.vc.EventFilterSpecByEntity;
import com.vmware.vc.EventFilterSpecByTime;
import com.vmware.vc.EventFilterSpecRecursionOption;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.ResultsEnum;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.CreateDVSTestBase;
import dvs.EventsComparator;

/**
 * Create a DVS inside a valid folder with the following parameters set in the
 * config spec. DVSConfigSpec.configVersion is set to an empty string.
 */
public class Pos001 extends CreateDVSTestBase
{
   private EventManager iEvent = null;
   private ManagedObjectReference eventManagerMor = null;
   private EventFilterSpec eventFilterSpec = null;
   private ServiceInstance iServiceInstance = null;
   private ManagedObjectReference historyCollectorMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVSwitch inside a valid folder");
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
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(this.getClass().getName());
               status = true;
            } else {
               log.error("Failed to create the network folder");
            }
         } else {
            log.error("Test setup failed.");
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create a DVSwitch inside a valid folder")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.configSpec != null) {
            this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                     this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               if (iDistributedVirtualSwitch.validateDVSConfigSpec(this.dvsMOR,
                        this.configSpec, null)) {
                  status = true;
               } else {
                  log.info("The config spec of the Distributed Virtual Switch"
                           + "is not created as per specifications");
               }
            } else {
               log.error("Cannot create the distributed "
                        + "virtual switch with the config spec passed");
            }
         }
     
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
      boolean foundCreatedEvent = false;
      boolean foundDestroyedEvent = false;
      Vector<Event> events = null;
     
         status &= super.testCleanUp();
         events = this.iEvent.getEvents(this.historyCollectorMor);
         if (this.historyCollectorMor != null) {
            if (events != null && events.size() > 0) {
               Object eventsArr[] = events.toArray();
               ;
               Arrays.sort(eventsArr, new EventsComparator());
               events = (Vector) TestUtil.arrayToVector(eventsArr);
               for (Event event : events) {
                  if (Class.forName("com.vmware.vc.DvsCreatedEvent").isInstance(
                           event)) {
                     foundCreatedEvent = true;
                  } else if (foundCreatedEvent
                           && Class.forName("com.vmware.vc.DvsDestroyedEvent").isInstance(
                                    event)) {
                     foundDestroyedEvent = true;
                     break;
                  }
               }
            }
         }
         if (foundDestroyedEvent == false) {
            log.error("Failed to verify the DVS events");
            super.setOutcome(ResultsEnum.FAIL);
         } else {
            log.info("Successfully verified the events are in order");
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}