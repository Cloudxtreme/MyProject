/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.createdvs;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.InvalidArgument;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Create DVSwitch with the following parameters with the following parameters
 * set in the configSpec: - DVSConfigSpec.configVersion is set to an empty
 * string. - DVSConfigSpec.name is set to "CreateDVS-Neg018" -
 * DVSConfigSpec.maxPort set to a valid number more than the number of uplink
 * ports per host - DVSConfigSpec.numPort set to a valid number less than the
 * number of pnics in the pnic proxy - DVSConfigSpec.uplinkPortPolicy set to a
 * valid array that has number of elements less than the number of pnics being
 * added. ({uplink1,...,uplinkn}) -
 * DistributedVirtualSwitchHostMemberConfigSpec.operation set to add -
 * DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor -
 * DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy
 * selection with pnic spec having a valid pnic device and uplinkPortKey set to
 * null - DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set
 * to a valid number more than the num of uplinks ports per host
 */
public class Neg018 extends CreateDVSTestBase
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
               + "- DVSConfigSpec.name is set to 'CreateDVS-Neg018',\n"
               + "- DVSConfigSpec.maxPort set to a valid number more than the number of"
               + " uplink ports per host.\n"
               + "- DVSConfigSpec.numPort set to a valid number less than the number of "
               + "pnics in the pnic proxy \n"
               + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that has number "
               + "of elements less than the number of pnics being added."
               + "({uplink1, .. uplinkn}),\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set to a valid number "
               + "more than the num of uplinks ports per host.");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      String[] uplinkPortNames = null;
      log.info("Test setup Begin:");
      List<DistributedVirtualSwitchHostMemberPnicSpec> pnicSpecList = null;
     
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
               this.configSpec.setName(this.getTestId());
               String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
               if (physicalNics != null) {
                  pnicSpecList = new ArrayList<DistributedVirtualSwitchHostMemberPnicSpec>();
                  for (int i = 0; i < physicalNics.length; i++) {
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(physicalNics[i]);
                     pnicSpec.setUplinkPortKey(null);
                     pnicSpecList.add(pnicSpec);
                  }
                  uplinkPortNames = new String[physicalNics.length - 1];
                  for (int i = 0; i < physicalNics.length - 1; i++) {
                     uplinkPortNames[i] = "uplink" + i;
                  }
                  this.configSpec.setMaxPorts(uplinkPortNames.length + 6);
                  this.configSpec.setNumStandalonePorts(physicalNics.length + 3);
                  uplinkPolicyInst.getUplinkPortName().clear();
                  uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortNames));
                  this.configSpec.setUplinkPortPolicy(uplinkPolicyInst);
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(pnicSpecList.toArray(new DistributedVirtualSwitchHostMemberPnicSpec[pnicSpecList.size()])));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  hostConfigSpecElement.setHost(this.hostMor);
                  hostConfigSpecElement.setMaxProxySwitchPorts(new Integer(
                           uplinkPortNames.length + 2));
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
               + "- DVSConfigSpec.name is set to 'CreateDVS-Neg018',\n"
               + "- DVSConfigSpec.maxPort set to a valid number more than the number of"
               + " uplink ports per host.\n"
               + "- DVSConfigSpec.numPort set to a valid number less than the number of "
               + "pnics in the pnic proxy \n"
               + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that has number "
               + "of elements less than the number of pnics being added."
               + "({uplink1, .. uplinkn}),\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null,\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.MaxProxySwitchPorts set to a valid number "
               + "more than the num of uplinks ports per host.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      MethodFault expectedMethodFault = null;
      boolean status = false;
      try {
         this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                  this.networkFolderMor, this.configSpec);
         log.error("The API did not throw Exception");
      } catch (Exception actualMethodFaultExcep) {
         MethodFault actualMethodFault = com.vmware.vcqa.util.TestUtil.getFault(actualMethodFaultExcep);
         expectedMethodFault = new InvalidArgument();
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
         if (this.dcMor != null) {
            this.dvsMOR = this.iFolder.getDistributedVirtualSwitch(
                     this.iFolder.getNetworkFolder(this.dcMor),
                     this.getTestId());
         }
         if (this.dvsMOR != null) {
            status &= this.iManagedEntity.destroy(this.dvsMOR);
         }
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}