/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.updatevirtualnic;

import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL;

import java.net.InetAddress;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicBacking;
import com.vmware.vc.DistributedVirtualSwitchHostMemberPnicSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.HostSystemConnectionState;
import com.vmware.vc.HostVirtualNicConfig;
import com.vmware.vc.HostVirtualNicSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;

import dvs.VNicBase;

/**
 * 1. Update virtual nic (from legacy) to connect to port on ephemeral port
 * group 2. Disable the virtual nic through esxcfg-vmknic -D command 3.Wait for
 * the host sync.Check for the port and verify that port no longer exist on
 * ephemeral port group.
 */
public class Pos015 extends VNicBase
{
   private String dvSwitchUuid = null;
   private HostVirtualNicSpec origVnicSpec = null;
   private String vNicdevice = null;
   private String portgroupKey = null;
   private Map<String, List<String>> usedPorts = null;
   private String portKey = null;
   private String pgName = null;
   private Connection conn = null;
   private String command = null;
   private String portGroupName = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" 1. Update virtual nic (from legacy) to connect to"
               + " port on ephemeral port group "
               + " 2. Disable the virtual nic through esxcfg-vmknic  -D command "
               + "  3.Wait for the host sync.Check for the port and verify "
               + "that port no longer " + "   exist on ephemeral port group. ");
   }

   /**
    * Method to setup the environment for the test.
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
      DVSConfigSpec dvsConfigSpec = null;
      DistributedVirtualSwitchHostMemberConfigSpec hostMember = null;
      DistributedVirtualSwitchHostMemberPnicBacking pnicBacking = null;
      DistributedVirtualSwitchHostMemberPnicSpec pnicSpec = null;
      HashMap allHosts = null;
      log.info("test setup Begin:");
      if (super.testSetUp()) {
        
            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, HostSystemConnectionState.CONNECTED);
            Set hostsSet = allHosts.keySet();
            if ((hostsSet != null) && (hostsSet.size() > 0)) {
               Iterator hostsItr = hostsSet.iterator();
               if (hostsItr.hasNext()) {
                  hostMor = (ManagedObjectReference) hostsItr.next();
               }
            }
            if (hostMor != null) {
               /*
                * Check for free Pnics
                */
               String[] freePnics = ins.getPNicIds(this.hostMor);
               if ((freePnics != null) && (freePnics.length > 0)) {
                  nwSystemMor = ins.getNetworkSystem(hostMor);
                  if (nwSystemMor != null) {
                     hostMember = new DistributedVirtualSwitchHostMemberConfigSpec();
                     hostMember.setOperation(TestConstants.CONFIG_SPEC_ADD);
                     hostMember.setHost(this.hostMor);
                     pnicBacking = new DistributedVirtualSwitchHostMemberPnicBacking();
                     pnicSpec = new DistributedVirtualSwitchHostMemberPnicSpec();
                     pnicSpec.setPnicDevice(freePnics[0]);
                     pnicBacking.getPnicSpec().clear();
                     pnicBacking.getPnicSpec().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberPnicSpec[] { pnicSpec }));
                     hostMember.setBacking(pnicBacking);
                     dvsConfigSpec = new DVSConfigSpec();
                     dvsConfigSpec.setConfigVersion("");
                     dvsConfigSpec.setName(this.getTestId());
                     dvsConfigSpec.getHost().clear();
                     dvsConfigSpec.getHost().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new DistributedVirtualSwitchHostMemberConfigSpec[] { hostMember }));
                     this.dvsMor = this.iFolder.createDistributedVirtualSwitch(
                              this.iFolder.getNetworkFolder(this.iFolder.getDataCenter()),
                              dvsConfigSpec);
                     if ((this.dvsMor != null)
                              && this.ins.refresh(this.nwSystemMor)
                              && this.iDVSwitch.validateDVSConfigSpec(
                                       this.dvsMor, dvsConfigSpec, null)) {
                        log.info("Successfully created the distributed "
                                 + "virtual switch");
                        pgName = getTestId() + "-pg1";
                        portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                                 DVPORTGROUP_TYPE_EPHEMERAL, 1, pgName);
                        if (portgroupKey != null) {
                           HostNetworkConfig nwCfg = ins.getNetworkConfig(nwSystemMor);
                           if ((nwCfg != null) && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class) != null)
                                    && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class).length > 0)
                                    && (com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0] != null)) {
                              HostVirtualNicConfig vnicConfig = com.vmware.vcqa.util.TestUtil.vectorToArray(nwCfg.getVnic(), com.vmware.vc.HostVirtualNicConfig.class)[0];
                              this.origVnicSpec = vnicConfig.getSpec();
                              vNicdevice = vnicConfig.getDevice();
                              portGroupName = vnicConfig.getPortgroup();

                              log.info("VnicDevice : " + vNicdevice);
                              status = true;
                           } else {
                              log.error("Unable to find valid Vnic");
                           }
                        }
                     } else {
                        log.error("Unable to create DistributedVirtualSwitch");
                     }
                  } else {
                     log.error("The network system Mor is null");
                  }
               } else {
                  log.error("Unable to get free pnics");
               }

            } else {
               log.error("Unable to find the host.");
            }
        
      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test.
    * 
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = " 1. Update virtual nic (from legacy) to connect to"
               + " port on ephemeral port group "
               + " 2. Disable the virtual nic through esxcfg-vmknic  -D command "
               + "  3.Wait for the host sync.Check for the port and verify "
               + "that port no longer " + "   exist on ephemeral port group. ")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      HostVirtualNicSpec updatedVNicSpec = null;
      ManagedObjectReference pgMor = null;
      log.info("test setup Begin:");
     
         List<ManagedObjectReference> pgList = this.iDVSwitch.getPortgroup(dvsMor);
         for (ManagedObjectReference pg : pgList) {
            if (this.iDVPortGroup.getName(pg).equals(this.pgName)) {
               pgMor = pg;
               break;
            }
         }
         DVSConfigInfo info = iDVSwitch.getConfig(dvsMor);
         dvSwitchUuid = info.getUuid();
         // create the DistributedVirtualSwitchPortConnection object.
         portConnection = new DistributedVirtualSwitchPortConnection();
         portConnection.setSwitchUuid(dvSwitchUuid);
         portConnection.setPortgroupKey(portgroupKey);
         portKey = this.iDVSwitch.getFreePortInPortgroup(dvsMor, portgroupKey,
                  this.usedPorts);
         portConnection.setPortKey(portKey);
         if (portConnection != null) {
            updatedVNicSpec = (HostVirtualNicSpec) TestUtil.deepCopyObject(this.origVnicSpec);
            updatedVNicSpec.setDistributedVirtualPort(portConnection);
            updatedVNicSpec.setPortgroup(null);
            if (ins.updateVirtualNic(nwSystemMor, vNicdevice, updatedVNicSpec)) {
               log.info("Successfully updated VirtualNic " + vNicdevice);
               if (this.ihs.isEesxHost(hostMor)) {
                  status = rebootAndVerifyNetworkConnectivity(hostMor);
               } else {
                  status = true;
                  /*
                   * Disable the virtual nic
                   */
                  String strPortKey = this.iDVPortGroup.getPortKeys(pgMor).get(
                           0);
                  InetAddress hostIp = InetAddress.getByName(this.ihs.getHostName(this.hostMor));
                  conn = SSHUtil.getSSHConnection(hostIp.getHostAddress(),
                           TestConstants.ESX_USERNAME,
                           TestConstants.ESX_PASSWORD);
                  command = "esxcfg-vmknic  -D " + vNicdevice + " -v "
                           + strPortKey + " -s "
                           + iDVSwitch.getConfig(dvsMor).getName();
                  status &= SSHUtil.executeRemoteSSHCommand(conn, command);
                  status &= this.ins.refresh(this.nwSystemMor);
                  Thread.sleep(20000);
                  Assert.assertNull(this.iDVPortGroup.getPortKeys(pgMor),
                           "Unable to delele dvport");

               }
            } else {
               log.error("Unable to update VirtualNic " + vNicdevice);

               status = false;
            }
         } else {
            status = false;
            log.error("can not get a free port on the dvswitch");
         }
     
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started. 1.
    * Migrate the VM back to Source host. 3. Remove the vNic and DVSMor.
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
            if (this.origVnicSpec != null) {
               if (ins.updateVirtualNic(nwSystemMor, vNicdevice, origVnicSpec)) {
                  log.info("Successfully restored original VirtualNic "
                           + "config: " + vNicdevice);
                  status = false;
               } else {
                  log.info("Unable to update disabled VirtualNic "
                           + vNicdevice);
                  status = true;
               }
            }
            command = "esxcfg-vmknic  -e " + vNicdevice + " -p  "
                     + portGroupName;
            status &= SSHUtil.executeRemoteSSHCommand(conn, command);

         } catch (Exception e) {
            status = false;
            TestUtil.handleException(e);
         }

         status &= super.testCleanUp();
     
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
