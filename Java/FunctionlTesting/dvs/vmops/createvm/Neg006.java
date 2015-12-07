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

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.ResourceNotAvailable;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;

import dvs.vmops.VMopsBase;

/**
 * Create 3 VM's on a standalone host to connect to 2 unused DVPorts in early
 * Binding DVPortgroup.The device is of type VirtualPCNet32,the backing is of
 * type DVPort backing and the port connection is a DVPort connection.
 */
public class Neg006 extends VMopsBase
{
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private ManagedObjectReference vmMor = null;
   private String dvSwitchUuid = null;
   private List<ManagedObjectReference> vmMors = null;

   /**
    * Set description of this test.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Create 3 VM's on a standalone host to connect to 2"
               + " unused DVPort in earlyBinding DVPortgroup.The device is of"
               + " typeVirtualPCNet32.");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the earlyBinding portgroup,it has 2 unsued DVPorts. 3. Create the
    * VMConfigSpec.
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
      log.info("test setup Begin:");
      if (super.testSetUp()) {

            hostMor = ihs.getStandaloneHost();
            log.info("Host MOR: " + hostMor);
            log.info("Host Name: " + ihs.getHostName(hostMor));
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
                  // Get the portgroupKey.
            	  DVPortgroupConfigSpec pgConfigSpec = new
            			  DVPortgroupConfigSpec();
            	  pgConfigSpec.setName(getTestId()+"-PG");
            	  pgConfigSpec.setType(DVPORTGROUP_TYPE_EARLY_BINDING);
            	  pgConfigSpec.setNumPorts(2);
            	  pgConfigSpec.setAutoExpand(false);
            	  List<ManagedObjectReference> pgMorList = iDVSwitch.
            	     addPortGroups(dvsMor, new DVPortgroupConfigSpec[]{
            	        pgConfigSpec});
            	  portgroupKey = iDVPortGroup.getKey(pgMorList.get(0));
                  //portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                           //DVPORTGROUP_TYPE_EARLY_BINDING, 2, getTestId()
                                    //+ "-PG");
                  if (portgroupKey != null) {
                     // Get the DVSUuid.
                     DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
                     dvSwitchUuid = info.getUuid();
                     log.info("DVSUuid :" + dvSwitchUuid);
                     // create the DistributedVirtualSwitchPortConnection
                     // object.
                     dvsPortConnection = buildDistributedVirtualSwitchPortConnection(
                              dvSwitchUuid, null, portgroupKey);
                     vmConfigSpec = buildCreateVMCfg(dvsPortConnection,
                              VM_VIRTUALDEVICE_ETHERNET_PCNET32, hostMor);
                     log.info("Successfully created VMConfigspec.");
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
    * Test. 1. Create the First VM with VMConfigSpec. 2. Create the Second VM
    * with same VMConfigSpec.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Create 3 VM's on a standalone host to connect to 2"
               + " unused DVPort in earlyBinding DVPortgroup.The device is of"
               + " typeVirtualPCNet32.")
   public void test()
      throws Exception
   {
      boolean status = false;
      boolean created = true;
      vmMors = new ArrayList<ManagedObjectReference>();
      MethodFault expectedFault = new ResourceNotAvailable();

         for (int i = 1; created && i < 4; i++) {
            vmConfigSpec.setName(getTestId() + "-" + i);
            if (i == 1 || i == 2) {
               vmMor = new Folder(super.getConnectAnchor()).createVM(
                        ivm.getVMFolder(), vmConfigSpec,
                        ihs.getPoolMor(hostMor), hostMor);
               if (vmMor != null) {
                  log.info("Successfully created a VM.");
                  vmMors.add(vmMor);
                  status = verify(vmMor, null, vmConfigSpec);
               } else {
                  log.error("Unable to create a VM.");
                  created = false;
               }
            } else {
               try {
                  vmMor = new Folder(super.getConnectAnchor()).createVM(
                           ivm.getVMFolder(), vmConfigSpec,
                           ihs.getPoolMor(hostMor), hostMor);
               } catch (Exception actualMethodFaultExcep) {
                  MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
                  status &= TestUtil.checkMethodFault(actualMethodFault,
                           expectedFault);
               }
            }
         }

      if (!status) {
         log.error("API didn't throw expected exception: "
                  + expectedFault.getClass().getSimpleName());
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
      boolean status = true;
      try {
         Iterator vmIterator = vmMors.iterator();
         while (vmIterator.hasNext()) {
            vmMor = (ManagedObjectReference) vmIterator.next();
            if (vmMor != null && ivm.setVMState(vmMor, POWERED_OFF, false)) {
               status &= destroy(vmMor);// destroy the VM.
            } else {
               log.warn("VM not found");
            }
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status = false;
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
