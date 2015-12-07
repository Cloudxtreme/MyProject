/*
 * ************************************************************************
 *
 * Copyright 2008-2009 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.VersionConstants.ESX4x;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.DC_MOR_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_STALONE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_STALONE_PASS;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Abstract class that declares the common instance variables, common setup and
 * cleanup operations required by the tests of the dvs.functional tests package.
 */
public abstract class FunctionalTestBase extends TestBase
{
   protected Folder iFolder = null;
   protected ManagedEntity iManagedEntity = null;
   protected NetworkSystem ins = null;
   protected HostSystem ihs = null;
   protected DistributedVirtualSwitch iDVS = null;
   protected DistributedVirtualPortgroup iDVPortgroup = null;
   protected VirtualMachine ivm = null;
   protected ManagedObjectReference dcMor = null;
   protected ManagedObjectReference dvsMor = null;
   protected ManagedObjectReference hostMor = null;
   protected ManagedObjectReference nwSystemMor = null;
   protected HostNetworkConfig originalNetworkConfig = null;
   protected String dvSwitchUUID = null;

   /**
    * Method that does the common setup for the functional tests, This creates a
    * DVSwitch and adds the host to that.
    * 
    * @param ConnectAnchor connectAnchor
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      DistributedVirtualSwitchHostMemberConfigSpec hostCfgSpec = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      ManagedObjectReference nwFolderMor = null;
      this.iManagedEntity = new ManagedEntity(connectAnchor);
      this.ins = new NetworkSystem(connectAnchor);
      this.iDVS = new DistributedVirtualSwitch(connectAnchor);
      this.iDVPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      this.ivm = new VirtualMachine(connectAnchor);
      this.ihs = new HostSystem(connectAnchor);
      this.iFolder = new Folder(connectAnchor);
      this.dcMor = this.iFolder.getDataCenter();
      assertNotNull(this.dcMor, DC_MOR_GET_PASS, DC_MOR_GET_FAIL);
      // get standalone host as some tests removes the host.
      this.hostMor = ihs.getStandaloneHostBySupportedVersion(ESX4x);
      assertNotNull(this.hostMor, HOST_GET_STALONE_PASS, HOST_GET_STALONE_FAIL);
      final String dvsHostName = this.ihs.getHostName(this.hostMor);
      log.info("Using the host " + dvsHostName);
      this.nwSystemMor = this.ins.getNetworkSystem(this.hostMor);
      assertNotNull(this.nwSystemMor, "NetworkSystem found",
               "NetworkSystem not found");
      nwFolderMor = this.iFolder.getNetworkFolder(this.dcMor);
      DVSConfigSpec dvsCfg = new DVSConfigSpec();
      HostNetworkConfig[] hostNwCfg = null;
      dvsCfg.setConfigVersion("");
      dvsCfg.setName(this.getTestId());
      hostCfgSpec = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostCfgSpec.setHost(this.hostMor);
      hostCfgSpec.setOperation(TestConstants.CONFIG_SPEC_ADD);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostCfgSpec.setBacking(pnicBacking);
      dvsCfg.getHost().clear();
      dvsCfg.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostCfgSpec }));
      dvsMor = iFolder.createDistributedVirtualSwitch(nwFolderMor, dvsCfg);
      assertNotNull(this.dvsMor, "Created vDS", "Failed to create vDS");
      log.info("Refreshing the network state of host " + dvsHostName);
      assertTrue(this.ins.refresh(this.nwSystemMor), "Refreshed successfully",
               "Refresh failed");
      ThreadUtil.sleep(3000);
      this.dvSwitchUUID = this.iDVS.getConfig(this.dvsMor).getUuid();
      hostNwCfg = this.iDVS.getHostNetworkConfigMigrateToDVS(this.dvsMor,
               this.hostMor);
      assertNotNull(hostNwCfg, "Got network Cfg", "Failed to get network Cfg");
      assertNotNull(hostNwCfg.length >= 2, "Cfg size is vaild",
               "Cfg size is invalid");
      this.originalNetworkConfig = hostNwCfg[1];
      log.info("Update network config to use vDS...");
      assertTrue(this.ins.updateNetworkConfig(nwSystemMor, hostNwCfg[0],
               TestConstants.CHANGEMODE_MODIFY), "Successfully updated",
               "Failed to update");
      return true;
   }

   /**
    * Method to restore the state of the VC inventory. This restores the network
    * config of the host and deletes the DVS MOR created.
    * 
    * @param connectAnchor ConnectAnchor
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
      if (this.originalNetworkConfig != null) {
         log.info("Restoring the original network config of the host");
         cleanUpDone = this.ins.updateNetworkConfig(this.nwSystemMor,
                  this.originalNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
      }
      if (this.dvsMor != null) {
         log.info("Destroying the vDS...");
         cleanUpDone &= this.iManagedEntity.destroy(dvsMor);
      }
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}