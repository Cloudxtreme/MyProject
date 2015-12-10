/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigureportgroups;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Arrays;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
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
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.EventsComparator;

/**
 * Reconfigure an existing portgroup on an existing distributed virtual switch
 * with a valid name which contains all numeric characters.
 */
public class Pos052 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DistributedVirtualPortgroup iDVPortgroup = null;
   private DVPortgroupConfigSpec dvPortgroupConfigSpec = null;
   private List<ManagedObjectReference> dvPortgroupMorList = null;
   private DVPortgroupConfigSpec[] dvPortgroupConfigSpecArray = null;
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
      setTestDescription("Reconfigure an existing portgroup on an existing "
               + "distributed virtual switch with a valid name "
               + "which contains all numeric characters");
   }

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setupDone = false;
      EventFilterSpecByTime filterSpecTime = null;
      EventFilterSpecByEntity eventFilterSpecByEntity = null;
      log.info("Test setup Begin:");
      try {
         this.iFolder = new Folder(connectAnchor);
         this.iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
         this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
         this.iManagedEntity = new ManagedEntity(connectAnchor);
         this.dcMor = this.iFolder.getDataCenter();
         if (this.dcMor != null) {
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
            this.dvsConfigSpec = new DVSConfigSpec();
            this.dvsConfigSpec.setConfigVersion("");
            this.dvsConfigSpec.setName(this.getClass().getName());
            dvsMor = this.iFolder.createDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
            if (dvsMor != null) {
               log.info("Successfully created the distributed "
                        + "virtual switch");
               this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
               this.dvPortgroupConfigSpec.setName(this.getTestId());
               this.dvPortgroupConfigSpec.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
               dvPortgroupConfigSpecArray = new DVPortgroupConfigSpec[] { dvPortgroupConfigSpec };
               dvPortgroupMorList = iDVSwitch.addPortGroups(dvsMor,
                        dvPortgroupConfigSpecArray);
               if (dvPortgroupMorList != null) {
                  if (dvPortgroupMorList.size() == dvPortgroupConfigSpecArray.length) {
                     log.info("Successfully added all the "
                              + "portgroups");
                     setupDone = true;
                  } else {
                     log.error("Could not add all the portgroups");
                  }
               } else {
                  log.error("Failed to add portgroups");
               }
            } else {
               log.error("Failed to create the distributed "
                        + "virtual switch");
            }
         } else {
            log.error("Failed to find a data center in the setup");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(setupDone, "Setup failed");
      return setupDone;
   }

   /**
    * Test method.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Reconfigure an existing portgroup on an existing "
               + "distributed virtual switch with a valid name "
               + "which contains all numeric characters")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      try {
         if (dvPortgroupMorList != null && dvPortgroupMorList.size() > 0) {
            this.dvPortgroupConfigSpec = new DVPortgroupConfigSpec();
            this.dvPortgroupConfigSpec.setConfigVersion(this.iDVPortgroup.getConfigInfo(
                     dvPortgroupMorList.get(0)).getConfigVersion());
            this.dvPortgroupConfigSpec.setName(DVSTestConstants.ALL_NUM_STRING);
            if (this.iDVPortgroup.reconfigure(dvPortgroupMorList.get(0),
                     dvPortgroupConfigSpec)) {
               log.info("Successfully reconfigured the portgroup");
               testDone = true;
            } else {
               log.error("Failed to reconfigure the portgroup");
            }
         } else {
            log.error("There are no portgroups to be reconfigured");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(testDone, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. Destroy
    * the portgroup, followed by the distributed virtual switch
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
      Vector<Event> events = null;
      boolean foundCreateDVSEvent = false;
      boolean foundDVPortgroupCreatedEvent = false;
      boolean foundDvsDestroyedEvent = false;
      boolean foundDVPortgroupReconfiguredEvent = false;
      boolean foundDVPortgroupRenamedEvent = false;
      Object eventsArr[] = null;

      try {
         if (this.dvsMor != null) {
            cleanUpDone &= this.iManagedEntity.destroy(dvsMor);
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
                     } else if (foundCreateDVSEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVPORTGROUPCREATEDEVENT).isInstance(
                                       event)) {
                        foundDVPortgroupCreatedEvent = true;
                     } else if (foundDVPortgroupCreatedEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVPORTGROUPRENAMEDEVENT).isInstance(
                                       event)) {
                        foundDVPortgroupRenamedEvent = true;
                     } else if (foundDVPortgroupRenamedEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVPORTGROUPRECONFIGUREDEVENT).isInstance(
                                       event)) {
                        foundDVPortgroupReconfiguredEvent = true;
                     } else if (foundDVPortgroupReconfiguredEvent
                              && Class.forName(
                                       DVSTestConstants.EVENT_DVSDESTROYEDEVENT).isInstance(
                                       event)) {
                        foundDvsDestroyedEvent = true;
                        break;
                     }
                  }
               }
            }
            if (foundDvsDestroyedEvent == false) {
               log.error("Failed to verify the DVS events");
               super.setOutcome(ResultsEnum.FAIL);
            } else {
               log.info("Successfully verified the events are in order");
            }
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      }
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}