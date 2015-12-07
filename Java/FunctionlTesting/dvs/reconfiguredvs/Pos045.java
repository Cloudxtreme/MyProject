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
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.host.NetworkSystem;

import dvs.CreateDVSTestBase;

/**
 * Reconfigure an existing DVS as follows: - Set the DVSConfigSpec.configVersion
 * to a valid config version string - Set the DVSConfigSpec.name to a valid
 * string - Set DistributedVirtualSwitchHostMemberConfigSpec.operation to EDIT -
 * Set DistributedVirtualSwitchHostMemberConfigSpec.host to a valid hostMor -
 * Set DistributedVirtualSwitchHostMemberConfigSpec.proxy to a valid pnic proxy
 * selection with the pnic spec(s) containing a valid pnic key and a null value
 * for uplinkPortKey
 */
public class Pos045 extends CreateDVSTestBase
{

   /*
    * private data variables
    */
   private HostSystem ihs = null;
   private Vector<ManagedObjectReference> allHosts = null;
   private ManagedObjectReference hostMor = null;
   private NetworkSystem iNetworkSystem = null;
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DVSConfigSpec deltaConfigSpec = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      super.setTestDescription("Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set the DVSConfigSpec.name to a valid string\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.operation to EDIT\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.host to a valid hostMor\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.proxy  to a valid pnic proxy selection"
               + " with the pnic spec(s) containing a valid pnic key and a null value "
               + " for uplinkPortKey.");
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
            this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
            if (this.networkFolderMor != null) {
               this.ihs = new HostSystem(connectAnchor);
               this.iNetworkSystem = new NetworkSystem(connectAnchor);
               this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
                        connectAnchor);
               allHosts = this.ihs.getAllHost();

               if (allHosts != null) {
                  this.hostMor = (ManagedObjectReference) allHosts.get(0);
               } else {
                  log.error("Valid Host MOR not found");
               }
               this.configSpec = new DVSConfigSpec();
               this.configSpec.setName(this.getClass().getName());
               DistributedVirtualSwitchHostMemberConfigSpec initialHostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
               DistributedVirtualSwitchHostMemberPnicBacking initialPnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
               initialPnicBacking.getPnicSpec().clear();
               initialPnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
               initialHostConfigSpecElement.setBacking(initialPnicBacking);
               initialHostConfigSpecElement.setHost(this.hostMor);
               initialHostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_ADD);
               this.configSpec.getHost().clear();
               this.configSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { initialHostConfigSpecElement }));
               this.dvsMOR = this.iFolder.createDistributedVirtualSwitch(
                        this.networkFolderMor, this.configSpec);
               if (this.dvsMOR != null) {
                  log.info("Successfully created the DVSwitch");
                  this.deltaConfigSpec = new DVSConfigSpec();
                  DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
                  DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
                  DistributedVirtualSwitchHostMemberConfigSpec hostConfigSpecElement = null;
                  String validConfigVersion = this.iDistributedVirtualSwitch.getConfig(
                           dvsMOR).getConfigVersion();
                  this.deltaConfigSpec.setConfigVersion(validConfigVersion);
                  String[] physicalNics = iNetworkSystem.getPNicIds(hostMor);
                  if (physicalNics != null) {
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(physicalNics[0]);
                     pnicSpec.setUplinkPortKey(null);
                  }
                  pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                  hostConfigSpecElement = new DistributedVirtualSwitchHostMemberConfigSpec();
                  pnicBacking.getPnicSpec().clear();
                  pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                  hostConfigSpecElement.setBacking(pnicBacking);
                  hostConfigSpecElement.setHost(this.hostMor);
                  hostConfigSpecElement.setOperation(TestConstants.CONFIG_SPEC_EDIT);
                  this.deltaConfigSpec.getHost().clear();
                  this.deltaConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostConfigSpecElement }));
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
   @Test(description = "Reconfigure an existing DVS as follows:\n"
               + "  - Set the DVSConfigSpec.configVersion to a valid config version"
               + " string\n"
               + "  - Set the DVSConfigSpec.name to a valid string\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.operation to EDIT\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.host to a valid hostMor\n"
               + "  - Set DistributedVirtualSwitchHostMemberConfigSpec.proxy  to a valid pnic proxy selection"
               + " with the pnic spec(s) containing a valid pnic key and a null value "
               + " for uplinkPortKey.")
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