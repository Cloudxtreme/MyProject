/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create DVSwitch with the following parameters with the following parameters
 * set in the configSpec: - DVSConfigSpec.configVersion is set to an empty
 * string. - DVSConfigSpec.name is set to "CreateDVS-Pos021" -
 * DVSConfigSpec.maxPort set to a valid number greater than numPorts -
 * DVSConfigSpec.numPort set to a valid number -
 * DistributedVirtualSwitchHostMemberConfigSpec.operation set to add -
 * DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor -
 * DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy
 * selection with pnic spec having a valid pnic device and uplinkPortKey set to
 * null - DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set
 * to a valid number
 */
public class Pos021 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
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
      super.setTestDescription("Create DVSwitch with the following parameters"
               + " with the following parameters set in the configSpec:\n"
               + "- DVSConfigSpec.configVersion is set to an empty string,\n"
               + "- DVSConfigSpec.name is set to 'CreateDVS-Pos021',\n"
               + "- DVSConfigSpec.maxPort set to a valid number greater than numPorts\n"
               + "- DVSConfigSpec.numPort set to a valid number,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null,\n"
               + "DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set to a valid number "
               + "equal to numPorts.");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      String dvsName = this.getTestId();
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
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(dvsName);
               String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
               if (physicalNics != null) {
                  pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                  pnicSpec.setPnicDevice(physicalNics[0]);
                  pnicSpec.setUplinkPortKey(null);
                  this.configSpec.setMaxPorts(11);
                  this.configSpec.setNumStandalonePorts(5);
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  hostConfigSpecElement.setHost(this.hostMor);
                  hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(5));
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
                  this.configSpec.getHost().clear();
                  this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
                  status = true;
               } else {
                  log.info("No physical nics found on the host");
               }
            } else {
               log.error("Failed to create the network folder");
            }
         } else {
            log.error("Failed to login");
         }
     

      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Method that creates the DVS.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Create DVSwitch with the following parameters"
               + " with the following parameters set in the configSpec:\n"
               + "- DVSConfigSpec.configVersion is set to an empty string,\n"
               + "- DVSConfigSpec.name is set to 'CreateDVS-Pos021',\n"
               + "- DVSConfigSpec.maxPort set to a valid number greater than numPorts\n"
               + "- DVSConfigSpec.numPort set to a valid number,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null,\n"
               + "DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set to a valid number "
               + "equal to numPorts.")
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
               Thread.sleep(10000);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  if (iDistributedVirtualSwitch.validateDVSConfigSpec(
                           this.dvsMOR, this.configSpec, null)) {
                     status = true;
                  } else {
                     log.info("The config spec of the Distributed Virtual "
                              + "Switch is not created as per specifications");
                  }
               } else {
                  log.error("Cannot create the distributed "
                           + "virtual switch with the config spec passed");
               }
            } else {
               log.error("Cannot create the distributed virtual "
                        + "switch with the config spec passed");
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
     
         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}