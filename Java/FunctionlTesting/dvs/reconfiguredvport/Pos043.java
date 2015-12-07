/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.EventFilterSpec;
import com.vmware.vc.EventFilterSpecByEntity;
import com.vmware.vc.EventFilterSpecByTime;
import com.vmware.vc.EventFilterSpecRecursionOption;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.ServiceInstance;
import com.vmware.vcqa.vim.event.EventManager;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos043 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;

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
   @Override
   public void setTestDescription()
   {
      super
               .setTestDescription("Reconfigure DVPort with input list containing "
                        + "one  entry . Operations would be ConfigSpecOperation._remove ");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
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
         eventFilterSpecByEntity
                  .setRecursion(EventFilterSpecRecursionOption.ALL);
         this.eventFilterSpec.setEntity(eventFilterSpecByEntity);
         filterSpecTime = new EventFilterSpecByTime();
         filterSpecTime.setBeginTime(this.iServiceInstance
                  .getServerCurrentTime());
         this.eventFilterSpec.setTime(filterSpecTime);
         this.historyCollectorMor =
                  this.iEvent.createCollectorForEvents(this.eventManagerMor,
                           this.eventFilterSpec);

         this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
         if (this.networkFolderMor != null) {
            this.iDVS = new DistributedVirtualSwitch(connectAnchor);
            configSpec = new DVSConfigSpec();
            configSpec.setName(this.getClass().getName());
            configSpec.setNumStandalonePorts(DVS_PORT_NUM);
            dvsMOR =
                     this.iFolder.createDistributedVirtualSwitch(
                              this.networkFolderMor, this.configSpec);
            if (this.dvsMOR != null) {
               log.info("Successfully created the DVSwitch");
               List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
               if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                  portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
                  portConfigSpecs[0] = new DVPortConfigSpec();
                  portConfigSpecs[0].setKey(String.valueOf(Integer
                           .parseInt(portKeyList.get(0))));
                  portConfigSpecs[0].setOperation(ConfigSpecOperation.REMOVE.value());
                  status = true;
               } else {
                  log.error("Can't get correct port keys");
               }
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
   @Override
   @Test(description = "Reconfigure DVPort with input list containing "
                        + "one  entry . Operations would be ConfigSpecOperation._remove ")
   public void test()
      throws Exception
   {
      assertTrue(this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs), "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      return super.testCleanUp();
   }
}