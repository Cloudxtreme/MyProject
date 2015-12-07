/*
 * ************************************************************************
 *
 * Copyright 2010 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addportgroups;

import static com.vmware.vcqa.util.Assert.*;
import static com.vmware.vcqa.vim.MessageConstants.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostIpConfig;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.DistributedVirtualPortgroup;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Add an early binding portgroup to an existing distributed virtual switch with
 * scope set to host mor
 */
public class Pos012 extends TestBase
{
   private Folder iFolder = null;
   private ManagedEntity iManagedEntity = null;
   // private ManagedObjectReference rootFolderMor = null;
   private ManagedObjectReference dvsMor = null;
   private DVSConfigSpec dvsConfigSpec = null;
   private DistributedVirtualSwitch iDVSwitch = null;
   private DistributedVirtualPortgroup iDvPortgroup = null;
   private DVPortgroupConfigSpec dvpgCfg = null;
   private List<ManagedObjectReference> dvpgs = null;
   private DVPortgroupConfigSpec[] dvpgCfgs = null;
   // private ManagedObjectReference computeResourceMor = null;
   // private ClusterComputeResource iComputeResource = null;
   private ManagedObjectReference hostMor = null;
   private HostSystem iHostSystem = null;
   private DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
   private NetworkSystem iNetworkSystem = null;
   private ManagedObjectReference networkMor = null;
   private HostNetworkConfig[] hostNetworkConfig = null;
   private String portgroupKey = null;
   private Map<String, List<String>> usedPorts = null;
   private ManagedObjectReference dcMor = null;
   private boolean isEesx = false;

   /**
    * Method to setup the environment for the test. This method creates a
    * distributed virtual switch.
    *
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun = true)
   public boolean testSetUp()
      throws Exception
   {
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      log.info("Test setup Begin:");
      iFolder = new Folder(connectAnchor);
      iDVSwitch = new DistributedVirtualSwitch(connectAnchor);
      iDvPortgroup = new DistributedVirtualPortgroup(connectAnchor);
      iManagedEntity = new ManagedEntity(connectAnchor);
      iHostSystem = new HostSystem(connectAnchor);
      iNetworkSystem = new NetworkSystem(connectAnchor);
      dcMor = iFolder.getDataCenter();
      hostMor = iHostSystem.getConnectedHost(null);
      assertNotNull(hostMor, HOST_GET_PASS, HOST_GET_FAIL);
      isEesx = iHostSystem.isEesxHost(hostMor);
      log.info("Using host {}", iHostSystem.getHostName(hostMor));
      log.info("ESXi = {}", isEesx);
      networkMor = iNetworkSystem.getNetworkSystem(hostMor);
      dvsConfigSpec = new DVSConfigSpec();
      dvsConfigSpec.setConfigVersion("");
      dvsConfigSpec.setName(getTestId());
      hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
      hostMember.setHost(hostMor);
      hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
      pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
      pnicBacking.getPnicSpec().clear();
      pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] {}));
      hostMember.setBacking(pnicBacking);
      dvsConfigSpec.getHost().clear();
      dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
      dvsMor = iFolder.createDistributedVirtualSwitch(
               iFolder.getNetworkFolder(dcMor), dvsConfigSpec);
      assertNotNull(dvsMor, DVS_CREATE_PASS, DVS_CREATE_FAIL);
      log.info("Successfully created the DVS {}", dvsConfigSpec.getName());
      hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(dvsMor,
               hostMor);
      assertNotEmpty(hostNetworkConfig, "Failed to get network Cfg");
      assertTrue(hostNetworkConfig.length == 2, "Failed to get 2 network Cfgs");
      iNetworkSystem.updateNetworkConfig(networkMor, hostNetworkConfig[0],
               TestConstants.CHANGEMODE_MODIFY);
      iNetworkSystem.refresh(networkMor);
      dvpgCfg = new DVPortgroupConfigSpec();
      dvpgCfg.setConfigVersion("");
      dvpgCfg.setName(getTestId());
      dvpgCfg.setDescription(DVSTestConstants.DVPORTGROUP_VALID_DESCRIPTION);
      dvpgCfg.setNumPorts(9);
      dvpgCfg.setType(DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING);
      dvpgCfg.getScope().clear();
      dvpgCfg.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { hostMor }));
      return true;
   }

   /**
    * Method that adds an early binding portgroup to the distributed virtual
    * switch with scope set to host mor
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @Test(description = "Add an early binding portgroup to an existing"
            + " distributed virtual switch with scope" + " set to host mor")
   public void test()
      throws Exception
   {
      HostVirtualNicSpec hostVnicSpec = null;
      DistributedVirtualSwitchPortConnection portConn = null;
      HostIpConfig ipConfig = null;
      String vnicId = null;
      usedPorts = new HashMap<String, List<String>>();
      dvpgCfgs = new DVPortgroupConfigSpec[] { dvpgCfg };
      dvpgs = iDVSwitch.addPortGroups(dvsMor, dvpgCfgs);
      assertNotEmpty(dvpgs, "Added DVPG", "Failed to add DVPG");
      portgroupKey = iDvPortgroup.getKey(dvpgs.get(0));
      log.info("Portgroup key {}", portgroupKey);
      portConn = iDVSwitch.getPortConnection(dvsMor, null, false, usedPorts,
               new String[] { portgroupKey });
      assertNotNull(portConn, "Failed to get port Connection");
      hostVnicSpec = new HostVirtualNicSpec();
      ipConfig = new HostIpConfig();
      ipConfig.setDhcp(true);
      hostVnicSpec.setIp(ipConfig);
      hostVnicSpec.setDistributedVirtualPort(portConn);
      vnicId = iNetworkSystem.addVirtualNic(networkMor, "", hostVnicSpec);
      assertNotNull(vnicId, "Failed to add the vNic");
      log.info("Successfully added vNic to connect to DVPort");
      assertTrue(iNetworkSystem.removeVirtualNic(networkMor, vnicId),
               "Removed the vNic successfully", "Failed to remove vNic.");
   }

   /**
    * Method to restore the state as it was before the test was started. Destroy
    * the distributed virtual switch
    *
    * @param connectAnchor ConnectAnchor object
    */
   @Override
   @AfterMethod(alwaysRun = true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         /*
          * Restore the original network configuration of the host
          */
         status &= iNetworkSystem.updateNetworkConfig(networkMor,
                  hostNetworkConfig[1], TestConstants.CHANGEMODE_MODIFY);
      } catch (final Exception e) {
         TestUtil.handleException(e);
         status = false;
      } finally {
         try {
            status &= iManagedEntity.destroy(dvsMor);
         } catch (final Exception ex) {
            TestUtil.handleException(ex);
            status = false;
         }
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
