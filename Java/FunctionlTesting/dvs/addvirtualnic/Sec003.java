/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.addvirtualnic;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import java.util.HashMap;
import java.util.List;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.VersionConstants;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;

import dvs.VNicBase;

/**
 * Add a VNIC to connect to a standalone port on a DVSwitch by an user having
 * network.assign privilege .
 */
public class Sec003 extends VNicBase
{
   private HostNetworkConfig origHostNetworkConfig = null;
   private List<String> portKeys = null;
   private String vNic = null;
   private String dvsUuid = null;
   private String portgroupKey = null;
   private String hostName = null;

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription("Add a vmkernel vnic to connect to an "
               + "existing standalone port on an existing DVSwitch"
               + " by an user having network.assign privilege  ");
   }

   /**
    * Method to setup the environment for the test.
    *
    * @param connectAnchor ConnectAnchor object
    * @return true if setup is successful.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
      HashMap allHosts = null;
      ManagedObjectReference pgMor = null;
      log.info("Test setup begin... ");
      if (super.testSetUp()) {

            allHosts = ihs.getAllHosts(VersionConstants.ESX4x, CONNECTED);
            if ((allHosts != null) && !allHosts.isEmpty()) {
               hostMor = (ManagedObjectReference) allHosts.keySet().iterator().next();
               if (hostMor != null) {
            	  hostName = ihs.getName(hostMor);
                  log.info("Got the host: " + hostName);
                  nwSystemMor = ins.getNetworkSystem(hostMor);
               } else {
                  log.error("Unable to find the host.");
               }
            }
            if (nwSystemMor != null) {
               dvsMor = iFolder.createDistributedVirtualSwitch(dvsName, hostMor);
               if (dvsMor != null) {
                  dvsUuid = iDVSwitch.getConfig(dvsMor).getUuid();
                  log.info("Add a standalone DVPort to connect the VNIC...");
                  portKeys = iDVSwitch.addStandaloneDVPorts(dvsMor, 1);
               } else {
                  log.error("Failed to create DVS.");
               }
               if ((portKeys != null) && !portKeys.isEmpty()) {
                  log.info("got portkeys: " + portKeys);
                  hostNetworkConfig = iDVSwitch.getHostNetworkConfigMigrateToDVS(
                           dvsMor, hostMor);
                  if (hostNetworkConfig != null) {
                     origHostNetworkConfig = hostNetworkConfig[1];
                     log.info("updating the host to use the DVS...");
                     if (ins.updateNetworkConfig(nwSystemMor,
                              hostNetworkConfig[0],
                              TestConstants.CHANGEMODE_MODIFY)) {
                        log.info("Successfully updated the host network.");
                        portgroupKey = iDVSwitch.addPortGroup(dvsMor,
                                 DVPORTGROUP_TYPE_EARLY_BINDING, 1, getTestId()
                                          + "-pg1");
                        if (portgroupKey != null) {
                           List<ManagedObjectReference> dvPortgroupMorList = this.iDVSwitch.getPortgroup(dvsMor);
                           if ((dvPortgroupMorList != null)
                                    && (dvPortgroupMorList.size() > 0)) {
                              for (int i = 0; i < dvPortgroupMorList.size(); i++) {
                                 pgMor = dvPortgroupMorList.get(i);
                                 String key = this.iDVPortGroup.getKey(pgMor);
                                 if ((key != null)
                                          && key.equalsIgnoreCase(portgroupKey)) {
                                    break;
                                 }
                              }

                           }
                           permissionSpecMap.put(
                                    DVSTestConstants.PRIVILEGE_HOST_CONFIG_NETWORK,
                                    this.ihs.getParentNode(this.hostMor));
                           permissionSpecMap.put(
                                    DVSTestConstants.PRIVILEGE_NETWORK_ASSIGN,
                                    pgMor);
                           if (addRolesAndSetPermissions(permissionSpecMap)
                                    && performSecurityTestsSetup(connectAnchor)) {
                              status = true;
                           }
                        }
                     } else {
                        log.error("Failed to update network.");
                     }
                  } else {
                     log.error("Failed to get the Network config to "
                              + "migrate to DVS.");
                  }
               } else {
                  log.error("Failed to get the standalone DVPort.");
               }
            } else {
               log.error("The network system Mor is null");
            }

      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the hostVirtualNic and add the VirtualNic to the
    * NetworkSystem. 2. Get the HostVNic Id and select the VNic for VMotion 3.
    * Migrate the VM.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Override
   @Test(description = "Add a vmkernel vnic to connect to an "
               + "existing standalone port on an existing DVSwitch"
               + " by an user having network.assign privilege  ")
   public void test()
      throws Exception
   {
      boolean status = false;
      DistributedVirtualSwitchPortConnection portConnection = null;
      log.info("test Begin...");


         portConnection = buildDistributedVirtualSwitchPortConnection(dvsUuid,
                  null, portgroupKey);
         hostMor = ihs.getHost(hostName);
         vNic = addVnic(hostMor, portConnection);
         if (vNic != null) {
            log.info("Successfully added the VNIC.");
            status = true;
         } else {
            log.error("Failed to add the virtual nic");
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
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;
      try {
         status = performSecurityTestsCleanup(connectAnchor,
                  data.getString(TestConstants.TESTINPUT_USERNAME),
                  data.getString(TestConstants.TESTINPUT_PASSWORD));
         if (vNic != null) {
        	hostMor = ihs.getHost(hostName);
        	nwSystemMor = ins.getNetworkSystem(hostMor);
            status &= ins.removeVirtualNic(nwSystemMor, vNic);
            if (status) {
               log.info("Successfully remove the add vNic.");
            } else {
               log.error("Failed to remove the added vNic");
               status = false;
            }
         }
         if ((this.portKeys != null) && (this.portKeys.size() > 0)
                  && (this.portKeys.get(0) != null)) {
            log.info("Sleeping for 4 seconds");
            Thread.sleep(4000);
            if (this.iDVSwitch.refreshPortState(this.dvsMor,
                     new String[] { portKeys.get(0) })) {
               log.info("Successfully refreshed the port state");
            } else {
               log.error("Can not refresh the port state");
               status = false;
            }

         }
         if (origHostNetworkConfig != null) {
            status &= ins.updateNetworkConfig(nwSystemMor,
                     origHostNetworkConfig, TestConstants.CHANGEMODE_MODIFY);
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         status &= super.testCleanUp();
      }
      assertTrue(status, "Cleanup failed");
      return status;
   }
}
