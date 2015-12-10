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

import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.InvalidRequest;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VMwareDVSConfigSpec;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;

import dvs.CreateDVSTestBase;

/**
 * Create a DVS inside a valid folder with the following parameters set in the
 * config spec. - DVSConfigSpec.configVersion is set to an empty string -
 * DVSConfigSpec.maxPort is set to a valid number that is less than the numPorts
 * - DVSConfigSpec.numPort is set to a valid number that is less than the number
 * of uplink ports per host - DVSConfigSpec.uplinkPortPolicy is set to an
 * invalid array whose number of elements is more than the number of pnics in
 * the pnic proxy spec {uplink1, ..., uplinkn} -
 * DistributedVirtualSwitchHostMemberConfigSpec.operation set to add -
 * DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor -
 * DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy
 * selection
 */
public class Neg016 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector allHosts = null;
   private ManagedObjectReference hostMor = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create a DVS inside a valid folder with the "
               + "following parameters set in the config spec.  "
               + "- DVSConfigSpec.configVersion is set to an empty string\n"
               + " - DVSConfigSpec.maxPort is set to a valid number that is less than "
               + "the numPorts\n"
               + " - DVSConfigSpec.numPort is set to a valid number that is less than "
               + "the number of uplink ports per host\n"
               + " - DVSConfigSpec.uplinkPortPolicy is set to an array whose number of "
               + "elements is more than the number of pnics in the pnic proxy spec "
               + "{uplink1, ..., uplinkn}\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection\n");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      String[] uplinkPortNames = null;
      log.info("Test setup Begin:");
     
         uplinkPolicyInst.getUplinkPortName().clear();
         uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            allHosts = this.ihs.getAllHost();

            if (allHosts != null) {
               this.hostMor = (ManagedObjectReference) allHosts.get(0);
            } else {
               log.error("Valid Host MOR not found");
            }

            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new VMwareDVSConfigSpec();
               this.configSpec.setConfigVersion("");
               uplinkPortNames = new String[2];
               for (int i = 0; i <= 1; i++)
                  uplinkPortNames[i] = "Uplink" + i;

               DistributedVirtualSwitchHostMemberConfigSpec DistributedVirtualSwitchHostMemberConfigSpecInst = new DistributedVirtualSwitchHostMemberConfigSpec();
               DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
               pnicBacking.getPnicSpec().clear();
               pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
               DistributedVirtualSwitchHostMemberConfigSpecInst.setBacking(pnicBacking);
               DistributedVirtualSwitchHostMemberConfigSpecInst.setOperation(TestConstants.CONFIG_SPEC_ADD);
               DistributedVirtualSwitchHostMemberConfigSpecInst.setHost(this.hostMor);

               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { DistributedVirtualSwitchHostMemberConfigSpecInst }));
               DistributedVirtualSwitchHostMemberConfigSpecInst.setMaxProxySwitchPorts(new Integer(
                        uplinkPortNames.length + 1));
               this.configSpec.setMaxPorts(uplinkPortNames.length - 1);
               this.configSpec.setNumStandalonePorts(uplinkPortNames.length + 1);
               this.configSpec.setUplinkPortPolicy(uplinkPolicyInst);
               status = true;
            } else {
               log.error("Network folder is null.Setup fail.");
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
   @Test(description = "Create a DVS inside a valid folder with the "
               + "following parameters set in the config spec.  "
               + "- DVSConfigSpec.configVersion is set to an empty string\n"
               + " - DVSConfigSpec.maxPort is set to a valid number that is less than "
               + "the numPorts\n"
               + " - DVSConfigSpec.numPort is set to a valid number that is less than "
               + "the number of uplink ports per host\n"
               + " - DVSConfigSpec.uplinkPortPolicy is set to an array whose number of "
               + "elements is more than the number of pnics in the pnic proxy spec "
               + "{uplink1, ..., uplinkn}\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + " - DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection\n")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
      try {
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                  this.networkFolderMor, this.configSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         InvalidRequest expectedMethodFault = new InvalidRequest();
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