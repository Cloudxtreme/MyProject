package dvs.healthcheck;

import org.testng.annotations.Factory;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.Optional;
import org.testng.annotations.Parameters;
import org.testng.annotations.Test;

import java.util.Arrays;
import java.util.Vector;

import com.vmware.vc.Event;
import com.vmware.vc.EventFilterSpec;
import com.vmware.vc.EventFilterSpecByEntity;
import com.vmware.vc.EventFilterSpecByTime;
import com.vmware.vc.EventFilterSpecRecursionOption;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSHealthCheckConfig;
import com.vmware.vc.VMwareDVSTeamingHealthCheckConfig;
import com.vmware.vc.VMwareDVSVlanMtuHealthCheckConfig;

import static com.vmware.vcqa.util.Assert.assertTrue;
import com.vmware.vcqa.execution.TestExecutionUtils;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.EventsComparator;

public class Pos006 extends HealthCheckTestBase {

   private EventManager iEvent = null;
   private ManagedObjectReference eventManagerMor = null;
   private ManagedObjectReference dcMor = null;
   private ServiceInstance iServiceInstance = null;
   private EventFilterSpec eventFilterSpec = null;
   private ManagedObjectReference historyCollectorMor = null;

   /**
    * Factory method to create the data driven tests.
    *
    * @return Object[] TestBase objects.
    *
    * @throws Exception
    */
   @Factory
   @Parameters({ "dataFile" })
   public Object[] getTests(@Optional("") String dataFile) throws Exception {
      return TestExecutionUtils.getTests(this.getClass().getName(), dataFile);
   }

   @BeforeMethod(alwaysRun = true)
   @Override
   public boolean testSetUp() throws Exception {
      EventFilterSpecByTime filterSpecTime = null;
      EventFilterSpecByEntity eventFilterSpecByEntity = null;

      getProperties();
      initialize();
      dvsMor = createDVSWithNics(dvsName);
      setupPortgroups(dvsMor);

      dcMor = folder.getDataCenter();
      if (this.dcMor != null) {
         this.iEvent = new EventManager(connectAnchor);
         this.iServiceInstance = new ServiceInstance(connectAnchor);
         this.eventManagerMor = this.iEvent.getEventManager();
         this.eventFilterSpec = new EventFilterSpec();
         eventFilterSpecByEntity = new EventFilterSpecByEntity();
         eventFilterSpecByEntity.setEntity(this.dcMor);
         eventFilterSpecByEntity
               .setRecursion(EventFilterSpecRecursionOption.ALL);
         this.eventFilterSpec.setEntity(eventFilterSpecByEntity);
         filterSpecTime = new EventFilterSpecByTime();
         filterSpecTime.setBeginTime(this.iServiceInstance
               .getServerCurrentTime());
         this.eventFilterSpec.setTime(filterSpecTime);
         this.historyCollectorMor = this.iEvent.createCollectorForEvents(
               this.eventManagerMor, this.eventFilterSpec);
      }

      return true;
   }

   @Test(description = "Query for the Health Check Events")
   public void test() throws Exception {
      Vector<Event> events = null;
      Object eventsArr[] = null;

      VMwareDVSHealthCheckConfig[] vdsHealthCheckConfig = new VMwareDVSHealthCheckConfig[2];
      vdsHealthCheckConfig[0] = new VMwareDVSVlanMtuHealthCheckConfig();
      vdsHealthCheckConfig[0].setEnable(vlanMtuEnabled);
      vdsHealthCheckConfig[0].setInterval(vlanMtuInterval);
      vdsHealthCheckConfig[1] = new VMwareDVSTeamingHealthCheckConfig();
      vdsHealthCheckConfig[1].setEnable(teamingEnabled);
      vdsHealthCheckConfig[1].setInterval(teamingInterval);
      assertTrue(configHealthCheck(vdsHealthCheckConfig),
            "Successfully to configure HealthCheck",
            "Failed to configure HealthCheck");

      // waiting for HealthCheck Events by sleeping 120 seconds.
      Thread.sleep(120 * 1000);

      boolean foundUplinkPortVlanEvent = false;
      boolean foundUplinkPortMtuEvent = false;
      boolean foundMtuEvent = false;
      boolean foundTeamingEvent = false;

      String eventClassName = null;
      if (this.historyCollectorMor != null) {
         events = this.iEvent.getEvents(this.historyCollectorMor);
         if (events != null && events.size() > 0) {
            eventsArr = events.toArray();
            Arrays.sort(eventsArr, new EventsComparator());
            events = (Vector) TestUtil.arrayToVector(eventsArr);
            for (Event event : events) {

               eventClassName = event.getClass().getName();
               if (eventClassName
                     .equals(DVSTestConstants.EVENT_UPLINKPORTVLANUNTRUNKEDEVENT) || eventClassName
                     .equals(DVSTestConstants.EVENT_UPLINKPORTVLANTRUNKEDEVENT)) {

                  log.debug("Get UplinkPortVlan Event: " + eventClassName);
                  foundUplinkPortVlanEvent = true;
               } else if (eventClassName
                     .equals(DVSTestConstants.EVENT_UPLINKPORTMTUNOTSUPPORTEVENT) || eventClassName
                     .equals(DVSTestConstants.EVENT_UPLINKPORTMTUSUPPORTEVENT)) {

                  log.debug("Get UplinkPortMtu Event: " + eventClassName);
                  foundUplinkPortMtuEvent = true;
               } else if (eventClassName
                     .equals(DVSTestConstants.EVENT_MTUMATCHEVENT) || eventClassName
                     .equals(DVSTestConstants.EVENT_MTUMISMATCHEVENT)) {

                  log.debug("Get Mtu Event: " + eventClassName);
                  foundMtuEvent = true;
               } else if (eventClassName
                     .equals(DVSTestConstants.EVENT_TEAMINGMISMATCHEVENT) || eventClassName
                     .equals(DVSTestConstants.EVENT_TEAMINGMATCHEVENT)) {

                  log.debug("Get Teaming Event: " + eventClassName);
                  foundTeamingEvent = true;
               }
            }
         }
      }

      assertTrue(foundUplinkPortVlanEvent,
            "Succeeded to get UplinkPortVlanEvent",
            "Failed to get UplinkPortVlanEvent");
      assertTrue(foundUplinkPortMtuEvent,
            "Succeeded to get UplinkPortMtuEvent",
            "Failed to get UplinkPortMtuEvent");
      assertTrue(foundMtuEvent, "Succeeded to get Mtu Event",
            "Failed to get MtuEvent");
      assertTrue(foundTeamingEvent, "Succeeded to get Teaming Event",
            "Failed to get Teaming Event");
   }

   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp() throws Exception {

      boolean done = false;
      log.info("Destroying the DVS: {} ", dvsName);
      done = destroy(dvsMor);
      return done;

   }

}
