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

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.HostSystem;

import dvs.CreateDVSTestBase;

/**
 * Create DVSwitch with the following parameters with the following parameters
 * set in the configSpec: - DVSConfigSpec.maxPort set to a valid number equal to
 * numPorts - DVSConfigSpec.numPort set to a valid number equal to the number of
 * uplinks ports per host - DVSConfigSpec.uplinkPortPolicy set to a valid array
 * that is equal to the max number of pnics per host.({uplink1, ..., uplink32})
 * - DistributedVirtualSwitchHostMemberConfigSpec.operation set to add -
 * DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor -
 * DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy
 * selection with pnic spec having a valid pnic device and uplinkPortKey set to
 * null
 */
public class Pos050 extends CreateDVSTestBase
{
   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference[] hostMors = null;
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Create DVSwitch with the following parameters"
               + " with the following parameters set in the configSpec:\n"
               + "- DVSConfigSpec.maxPort set to a valid number equal to numPorts\n"
               + "- DVSConfigSpec.numPort set to a valid number equal to the number of"
               + "uplinks ports per host\n"
               + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that is equal "
               + "to the max number of pnics per host.\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null");
   }

   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      this.hostMors = new ManagedObjectReference[2];
      DVSConfigInfo configInfo = null;
      DistributedVirtualSwitchHostMemberConfigSpec[] hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec[2];
      String dvsName = this.getTestId();
      log.info("Test setup Begin:");
     
         if (super.testSetUp()) {
            this.ihs = new HostSystem(connectAnchor);
            allHosts = this.ihs.getAllHost();
            if ((allHosts != null) && (allHosts.size() >= 2)) {
               this.hostMors[0] = (ManagedObjectReference) allHosts.get(0);
               this.hostMors[1] = (ManagedObjectReference) allHosts.get(1);
            } else {
               log.error("Valid Host MOR not found");
            }
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setConfigVersion("");
               this.configSpec.setName(dvsName);
               for (int i = 0; i < 2; i++) {
                  hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                  hostConfigSpecElement[i].setHost(this.hostMors[i]);
                  hostConfigSpecElement[i].setOperation(TestConstants.CONFIG_SPEC_ADD);
               }
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  configInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMOR);
                  this.deltaConfigSpec = new DVSConfigSpec();
                  this.deltaConfigSpec.setConfigVersion(configInfo.getConfigVersion());
                  this.deltaConfigSpec.setName(dvsName);
                  for (int i = 0; i < 2; i++) {
                     hostConfigSpecElement[i] = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostConfigSpecElement[i].setHost(this.hostMors[i]);
                     hostConfigSpecElement[i].setOperation(TestConstants.CONFIG_SPEC_REMOVE);
                  }
                  this.deltaConfigSpec.getHost().clear();
                  this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(hostConfigSpecElement));
                  status = true;
               } else {
                  log.error("Failed to create the DVS");
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
               + "- DVSConfigSpec.maxPort set to a valid number equal to numPorts\n"
               + "- DVSConfigSpec.numPort set to a valid number equal to the number of"
               + "uplinks ports per host\n"
               + "- DVSConfigSpec.uplinkPortPolicy set to a valid array that is equal "
               + "to the max number of pnics per host.\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.operation set to add\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.host set to a valid host Mor\n"
               + "- DistributedVirtualSwitchHostMemberConfigSpec.proxy set a a valid pnic proxy selection "
               + "with pnic spec having a valid pnic device and uplinkPortKey set to "
               + "null")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean status = false;
     
         status = this.iDistributedVirtualSwitch.reconfigure(this.dvsMOR,
                  this.deltaConfigSpec);
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
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}