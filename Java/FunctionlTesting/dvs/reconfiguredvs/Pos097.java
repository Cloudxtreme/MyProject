/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfiguredvs;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DVSNameArrayUplinkPortPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;

/**
 * DESCRIPTION: Reducing the number of uplink ports in vDS should delete the
 * corresponding uplink-ports on the host<BR>
 * TARGET: VC NOTE : PR#452126 <BR>
 * SETUP: 1. Create a vDS with host H1 <BR>
 * TEST: 2. Reduce the number of uplink ports in vDS using reconfigure vds api
 * 3. Verify that reducing the number of uplink ports in vDS in turn deleted the
 * corresponding uplink-ports on the host <BR>
 * CLEANUP: 4. Delete vDs
 */
public class Pos097 extends TestBase
{

   /*
    * private data variables
    */
   private DistributedVirtualSwitch iDistributedVirtualSwitch = null;
   private DistributedVirtualPortgroup idvpg = null;
   private Folder iFolder = null;
   private HostSystem ihs = null;
   private ManagedObjectReference hostMor = null;
   private ManagedObjectReference dcMor = null;
   private ManagedObjectReference dvsMor = null;
   private ManagedObjectReference networkFolderMor = null;
   private String vDsUUID = null;
   private int uplinkPortKeysViaVC = -1;
   private DVSConfigInfo vDsConfigInfo = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   @Override
   public void setTestDescription()
   {
      super.setTestDescription("(PR#452126)"
               + "Reducing the number of uplink ports in vDS"
               + " should delete the corresponding uplink-ports on the host");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      this.iFolder = new Folder(connectAnchor);
      this.iDistributedVirtualSwitch = new DistributedVirtualSwitch(
               connectAnchor);
      this.ihs = new HostSystem(connectAnchor);
      this.idvpg = new DistributedVirtualPortgroup(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      this.networkFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
      assertNotNull(networkFolderMor, "Failed to create the network folder");
      hostMor = this.ihs.getStandaloneHost();
      assertNotNull(hostMor, "Failed to get StandaloneHost ");
      this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
               this.getTestId(), hostMor);
      assertNotNull(this.dvsMor, "Cannot create the distributed virtual "
               + "switch with the config spec passed");
      vDsConfigInfo = this.iDistributedVirtualSwitch.getConfig(this.dvsMor);
      this.vDsUUID = vDsConfigInfo.getUuid();
      return true;
   }

   /**
    * Method that performs the test.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "(PR#452126)"
               + "Reducing the number of uplink ports in vDS"
               + " should delete the corresponding uplink-ports on the host")
   public void test()
      throws Exception
   {
      DVSConfigSpec deltaConfigSpec = null;
      DVSNameArrayUplinkPortPolicy uplinkPolicyInst = null;
      deltaConfigSpec = new DVSConfigSpec();
      uplinkPolicyInst = new DVSNameArrayUplinkPortPolicy();
      uplinkPolicyInst.getUplinkPortName().clear();
      uplinkPolicyInst.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new String[] { "uplink1", "uplink2",
               "uplink3" }));
      deltaConfigSpec.setConfigVersion(vDsConfigInfo.getConfigVersion());
      deltaConfigSpec.setUplinkPortPolicy(uplinkPolicyInst);
      assertTrue(this.iDistributedVirtualSwitch.reconfigure(this.dvsMor,
               deltaConfigSpec), "Failed to reconfigure vDs");
      ManagedObjectReference uplinkPGMor = com.vmware.vcqa.util.TestUtil.vectorToArray(this.iDistributedVirtualSwitch.getConfigSpec(
                        this.dvsMor).getUplinkPortgroup(), com.vmware.vc.ManagedObjectReference.class)[0];
      assertNotNull(uplinkPGMor, " Failed to get UplinkPortgroup");
      uplinkPortKeysViaVC = this.idvpg.getPortKeys(uplinkPGMor).size();
      log.info("uplinkPortKeysViaVC : " + uplinkPortKeysViaVC);
      assertTrue(
               InternalDVSHelper.getUplinkPortsOnHost(new ConnectAnchor(
                        this.ihs.getHostName(this.hostMor),
                        data.getInt(TestConstants.TESTINPUT_PORT)), vDsUUID).length == uplinkPortKeysViaVC,
               "Reducing the number of uplink ports in vDS"
                        + " deleted the corresponding uplink-ports on the host",
               "Failed to vrify number of uplink ports host ");

   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      return this.iDistributedVirtualSwitch.destroy(this.dvsMor);
   }
}