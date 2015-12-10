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

import com.vmware.vc.ClusterConfigSpecEx;
import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.ResourceConfigSpec;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ResourcePool;
import com.vmware.vcqa.vim.VirtualMachine;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos014 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private VirtualMachine ivm = null;
   private ClusterComputeResource icr = null;
   private HostSystem ihs = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private ResourcePool irp = null;
   private ManagedObjectReference nestedResPoolMor = null;
   private ManagedObjectReference nestedFolderMor = null;
   private ManagedObjectReference clusterExMor = null;
   private final int DVS_PORT_NUM = 1;

   /**
    * Sets the test description.
    *
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort and set multiple "
               + "managedEntity Mor in scope property");
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

      log.info("Test setup Begin:");
      DistributedVirtualSwitchPortCriteria portCriteria = null;

         if (super.testSetUp()) {
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.iDVS = new DistributedVirtualSwitch(connectAnchor);
               configSpec = new DVSConfigSpec();
               configSpec.setName(this.getClass().getName());
               configSpec.setNumStandalonePorts(DVS_PORT_NUM);
               dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  portCriteria = this.iDistributedVirtualSwitch.getPortCriteria(
                           false, null, null, null, null, false);
                  List<String> portKeyList = iDVS.fetchPortKeys(this.dvsMOR,
                           portCriteria);
                  if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                     ivm = new VirtualMachine(connectAnchor);
                     icr = new ClusterComputeResource(connectAnchor);
                     ihs = new HostSystem(connectAnchor);
                     irp = new ResourcePool(connectAnchor);
                     if (ihs.getAllHost() != null && ivm.getAllVM() != null) {
                        portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
                        portConfigSpecs[0] = new DVPortConfigSpec();
                        portConfigSpecs[0].setKey(portKeyList.get(0));
                        portConfigSpecs[0].getScope().clear();
                        portConfigSpecs[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(this.createScopeList()));
                        portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
                        status = true;

                     } else {
                        log.error("Can't find host and/or vm in the inventory. "
                                 + "Please check");
                     }
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
   @Test(description = "Reconfigure DVPort and set multiple "
               + "managedEntity Mor in scope property")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;

         status = this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs);
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

         status &= super.testCleanUp();

         if (this.nestedFolderMor != null) {
            if (this.iFolder.destroy(nestedFolderMor)) {
               log.info("Destroyed nested folder");
            } else {
               log.error("Couldn't destroy nested folder");
               status = false;
            }
         }

         if (this.clusterExMor != null) {
            if (iFolder.destroy(clusterExMor)) {
               log.info("cluster deleted");
            } else {
               log.error("Can't delete cluster ");
               status = false;
            }
         }

         if (this.nestedResPoolMor != null) {
            if (this.irp.destroy(this.nestedResPoolMor)) {
               log.info("Removed new resource pool");
            } else {
               log.error("Can't remove new resource pool");
               status = false;
            }
         }

      assertTrue(status, "Cleanup failed");
      return status;
   }

   /**
    * Create a child resource pool
    *
    * @param parentResPoolMor, parent resource pool of the one to be created
    * @return child resource pool mor
    * @throws Exception
    */
   private ManagedObjectReference createChildResPool(ManagedObjectReference parentResPoolMor)
      throws Exception
   {
      ManagedObjectReference childResPoolMor = null;
      ResourceConfigSpec resConfigSpec = this.irp.createDefaultResourceConfigSpec();

      childResPoolMor = irp.createResourcePool(parentResPoolMor, getTestId()
               + "respool", resConfigSpec);
      return childResPoolMor;
   }

   private ManagedObjectReference[] createScopeList()
      throws Exception
   {
      ManagedObjectReference[] scopeMors = new ManagedObjectReference[10];
      /*
       * 1. set VM mor
       */
      scopeMors[0] = ivm.getAllVM().get(0);

      /*
       * 2-4. set vm folder mor and a nested folder mor and host folder mor
       */
      ManagedObjectReference vmFolderMor = ivm.getVMFolder();
      scopeMors[1] = vmFolderMor;
      nestedFolderMor = iFolder.createFolder(vmFolderMor, getTestId());
      scopeMors[2] = nestedFolderMor;
      ManagedObjectReference hostFolderMor = (ManagedObjectReference) iFolder.getAllHostFolders().get(
               0);
      scopeMors[3] = hostFolderMor;

      /*
       * 5-6 set ComputeResource mor and cluster ComputeResource mor
       */
      scopeMors[4] = (ManagedObjectReference) (icr.getAllComputeResources().get(0));
      clusterExMor = iFolder.createClusterEx(hostFolderMor, getTestId(),
               new ClusterConfigSpecEx());
      scopeMors[5] = clusterExMor;

      /*
       * 7. set datacenter mor
       */
      scopeMors[6] = ihs.getDataCenter();

      /*
       * 8. set host mor
       */
      List<ManagedObjectReference> hostList = ihs.getAllHost();
      if (hostList != null) {
         scopeMors[7] = hostList.get(0);
      } else {
         log.error("Can't find host in the inventory");
      }

      /*
       * 10-11. set a valid resourcepool mor and nested resourcepool mor
       */
      ManagedObjectReference rpMor = icr.getResourcePool(ihs.getParentNode(ihs.
               getStandaloneHost()));
      scopeMors[8] = rpMor;
      nestedResPoolMor = this.createChildResPool(rpMor);
      scopeMors[9] = nestedResPoolMor;

      return scopeMors;
   }
}