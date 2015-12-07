/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvport;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.HashMap;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.ConfigSpecOperation;
import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.MORConstants;
import com.vmware.vcqa.vim.VirtualMachine;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure DVPort. See setTestDescription for detailed description
 */
public class Pos006 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDVS = null;
   private VirtualMachine ivm = null;
   private HostSystem ihs = null;
   private DVPortConfigSpec[] portConfigSpecs = null;
   private final int DVS_PORT_NUM = 1;
   private ManagedObjectReference vmChildFolder = null;
   private HashMap<String, ManagedObjectReference> vmFolderMap = null;
   private HashMap<ManagedObjectReference, VirtualMachinePowerState> vmPowerMap = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure DVPort and set a valid folder Mor "
               + "in scope property");
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
      ManagedObjectReference vmFolderMor = null;
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ivm = new VirtualMachine(connectAnchor);
            this.ihs = new HostSystem(connectAnchor);
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
                  List<String> portKeyList = iDVS.fetchPortKeys(dvsMOR, null);
                  if (portKeyList != null && portKeyList.size() == DVS_PORT_NUM) {
                     this.ivm = new VirtualMachine(connectAnchor);
                     vmFolderMor = ivm.getVMFolder();
                     this.vmChildFolder = this.iFolder.createFolder(
                              vmFolderMor, this.getTestId() + "-childFolder");
                     if (this.vmChildFolder != null) {
                        portConfigSpecs = new DVPortConfigSpec[DVS_PORT_NUM];
                        portConfigSpecs[0] = new DVPortConfigSpec();
                        portConfigSpecs[0].setKey(portKeyList.get(0));
                        portConfigSpecs[0].getScope().clear();
                        portConfigSpecs[0].getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { this.vmChildFolder }));
                        portConfigSpecs[0].setOperation(ConfigSpecOperation.EDIT.value());
                        status = true;
                     } else {
                        log.error("Can not create a valid vm child folder");
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
   @Test(description = "Reconfigure DVPort and set a valid folder Mor "
               + "in scope property")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDVS.reconfigurePort(this.dvsMOR, this.portConfigSpecs);
         if (status) {
            log.info("Successfully reconfigured DVS");
            if (validateScope()) {

            }
         } else {
            log.error("Failed to reconfigure dvs");
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
     
         if (this.vmChildFolder != null) {
            status &= this.iFolder.destroy(this.vmChildFolder);
         }
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }

   private boolean validateScope()
      throws Exception
   {
      boolean rval = false;
      Vector<ManagedObjectReference> allHosts = null;
      ManagedObjectReference vmMor = null;
      List<ManagedObjectReference> vms = null;
      ManagedObjectReference parentNode = null;
      String vmName = null;
      if (this.vmChildFolder != null) {
         allHosts = this.ihs.getAllHost();
         if (allHosts != null && allHosts.size() > 0) {
            for (ManagedObjectReference hostMor : allHosts) {
               if (hostMor != null) {
                  vms = this.ihs.getVMs(hostMor, null);
                  if (vms != null && vms.size() > 0) {
                     vmMor = vms.get(0);
                     if (vmMor != null) {
                        parentNode = this.ivm.getParentNode(vmMor,
                                 MORConstants.FOLDER_MOR);
                        vmName = this.ivm.getVMName(vmMor);
                        if (vmFolderMap == null) {
                           this.vmFolderMap = new HashMap<String, ManagedObjectReference>();
                           this.vmFolderMap.put(vmName, parentNode);
                        }
                        if (this.vmPowerMap == null) {
                           vmPowerMap = new HashMap<ManagedObjectReference, VirtualMachinePowerState>();
                        }
                        vmPowerMap.put(vmMor, this.ivm.getVMState(vmMor));
                     }
                  }
               }
            }
         }
      }
      return rval;
   }
}