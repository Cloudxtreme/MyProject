/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectNotFound;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVSwitch by setting - ManagedObjectReference to a
 * valid DVSwitch Mor - DVSConfigSpec.configVersion to a valid config version
 * string - DistributedVirtualSwitchHostMemberConfigSpec.operation to ADD -
 * DistributedVirtualSwitchHostMemberConfigSpec.host to an empty Mor -
 * DVSHostMmemberConfigSpec.proxy to a valid pnic proxy selection
 */

public class Neg031 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVSwitch by setting:\n "
               + " - ManagedObjectReference to a valid DVSwitch Mor,\n"
               + " - DVSConfigSpec.configVersion to a valid config version string,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.operation to ADD,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.host to an empty Mor,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.proxy to a valid pnic proxy selection.");
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
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            this.iNetworkSystem = new NetworkSystem(connectAnchor);
            allHosts = this.ihs.getAllHost();
            if (allHosts != null) {
               this.hostMor = (ManagedObjectReference) allHosts.get(0);
            } else {
               log.error("Valid Host MOR not found");
            }
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
                  String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  DistributedVirtualSwitchHostMemberConfigSpec hostMemberConfigSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
                  DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                  DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  String[] physicalNics = iNetworkSystem.getPNicIds(this.hostMor);
                  if (physicalNics != null) {
                     pnicSpec.setPnicDevice(physicalNics[0]);
                     pnicSpec.setUplinkPortKey(null);
                  }
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                  hostMemberConfigSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  hostMemberConfigSpec.setBacking(pnicBacking);
                  hostMemberConfigSpec.setHost(new ManagedObjectReference());
                  this.deltaConfigSpec.getHost().clear();
                  this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMemberConfigSpec }));
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
   @Test(description = "Reconfigure an existing DVSwitch by setting:\n "
               + " - ManagedObjectReference to a valid DVSwitch Mor,\n"
               + " - DVSConfigSpec.configVersion to a valid config version string,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.operation to ADD,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.host to an empty Mor,\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.proxy to a valid pnic proxy selection.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         ManagedObjectNotFound expectedMethodFault = new 
        		 ManagedObjectNotFound();
         status = TestUtil.checkMethodFault(actualMethodFault,
                  expectedMethodFault);
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
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}