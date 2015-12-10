/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package dvs.merge;

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
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.EventsComparator;

/**
 * Merge a source DVS with a detination DVS with a valid name
 */
public class Pos001 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference rootFolder = null;
   private ManagedObjectReference destDvsMor = null;
   private ManagedObjectReference srcDvsMor = null;
   private DVSConfigSpec configSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private ManagedObjectReference dcMor = null;

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
      setTestDescription("Merge a source DVS with a destination DVS "
               + "with a valid name");
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

      String destDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_DESTINATION_SUFFIX;
      String srcDvsName = DVSTestConstants.DVS_CREATE_NAME_PREFIX
               + this.getTestId() + DVSTestConstants.DVS_SOURCE_SUFFIX;
      log.info("Test setup Begin:");
     
         this.iFolder = new Folder(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         this.rootFolder = this.iFolder.getRootFolder();
         if (this.rootFolder != null) {
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
            this.configSpec = new DVSConfigSpec();
            this.configSpec.setConfigVersion("");
            this.configSpec.setName(destDvsName);
            destDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            this.configSpec.setName(srcDvsName);
            srcDvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), configSpec);
            if (srcDvsMor != null && destDvsMor != null) {
               log.info("Successfully created the source "
                        + "and destination distributed virtual " + "switches");
               status = true;
            } else {
               log.error("Could not create the source or "
                        + "destination distributed virtual " + "switches");
            }
         }
     
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that merges two distributed virtual switches
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Merge a source DVS with a destination DVS "
               + "with a valid name")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         if (this.iDVSwitch.merge(destDvsMor, srcDvsMor)) {
            log.info("Successfully merged the switches");
            status = true;
         } else {
            log.error("Failed to merge the switches");
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
      boolean status = false;
      Vector<Event> events = null;
      boolean foundDVSMergedEvent = false;
      boolean foundCreateDVSEvent = false;
      boolean foundDestroyDVSEvent = false;
      Object eventsArr[] = null;

     
         if (this.destDvsMor != null) {
            status = this.iManagedEntity.destroy(destDvsMor);
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
                     } else if (foundDVSMergedEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVSDESTROYEDEVENT).isInstance(
                                       event)) {
                        foundDestroyDVSEvent = true;
                        break;
                     } else if (foundCreateDVSEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVSMERGEDEVENT).isInstance(
                                       event)) {
                        foundDVSMergedEvent = true;
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

         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}