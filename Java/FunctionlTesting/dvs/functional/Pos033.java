/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL;

import org.testng.Assert;
import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import ch.ethz.ssh2.Connection;

import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostConnectSpec;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.UserSession;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.SSHUtil;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.AuthorizationManager;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Disconnect the host(H1) from the VC, Using hostd Create a VM (VM1) to connect
 * to a ephemeral portgroup.
 */
public class Pos033 extends FunctionalTestBase
{
   private SessionManager sessionManager = null;
   /*
    * Private data variables
    */
   private VirtualMachineConfigSpec vmConfigSpec = null;
   private DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   private ManagedObjectReference vmMor = null;
   private ConnectAnchor hostConnectAnchor = null;
   private Connection conn = null;
   private String hostName = null;
   private String vmName = null;
   private HostConnectSpec hostConnectSpec = null;

   /**
    * Set test description.
    */
   public void setTestDescription()
   {
      setTestDescription("Disconnect the host(H1) from the VC, Using hostd "
               + "Create a VM (VM1) to connect to a ephemeral " + "portgroup.");
   }

   /**
    * Method to setup the environment for the test. 1. Create the DVSwitch. 2.
    * Create the Standalone DVPort. 3. Create the VM ConfigSpec.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if setup is successful.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      sessionManager = new SessionManager(connectAnchor);

      boolean status = false;
      String pgKey = null;
      log.info("test setup Begin:");
      int timeout = TestConstants.MAX_WAIT_CONNECT_TIMEOUT;
      if (super.testSetUp()) {

            this.hostName = this.ihs.getHostName(this.hostMor);
            hostConnectSpec = this.ihs.getHostConnectSpec(hostMor);
            pgKey = iDVS.addPortGroup(this.dvsMor, DVPORTGROUP_TYPE_EPHEMERAL,
                     1, this.getTestId() + "-pg");
            if (pgKey != null) {
               log.info("Successfully Created the ephemeral  "
                        + "portgroup");
               // create the DistributedVirtualSwitchPortConnection object.
               dvsPortConnection = new DistributedVirtualSwitchPortConnection();
               dvsPortConnection.setSwitchUuid(this.dvSwitchUUID);
               dvsPortConnection.setPortgroupKey(pgKey);
               this.vmName = this.getTestId() + "-vm";
               vmConfigSpec = DVSUtil.buildCreateVMCfg(connectAnchor,
                        this.dvsPortConnection,
                        VM_VIRTUALDEVICE_ETHERNET_PCNET32, this.vmName,
                        this.hostMor);
               if (vmConfigSpec != null) {
                  log.info("Successfully created VMConfig spec.");
                  if (this.ihs.disconnectHost(this.hostMor)) {
                     this.hostConnectAnchor = new ConnectAnchor(
                              this.ihs.getHostName(hostMor),
                              data.getInt(TestConstants.TESTINPUT_PORT));
                     if (this.hostConnectAnchor != null) {
                        log.info("Successfully "
                                 + "obtained the "
                                 + "connect anchor "
                                 + "to the host");
                        status = true;
                     } else {
                        status = false;
                        log.error("Can not obtain "
                                 + "the connect "
                                 + "anchor to the " + "host");
                     }
                  } else {
                     status = false;
                     log.error("Can not disconnect"
                              + " the Host from the VC");
                  }
               } else {
                  log.error("The VM config spec is null");
               }
            } else {
               log.error("Failed to get the standalone DVPortkeys ");
            }

      }
      assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test. 1. Create the VM. 2. Varify the ConfigSpecs and Power-ops
    * operations.
    *
    * @param connectAnchor ConnectAnchor.
    */
   @Test(description = "Disconnect the host(H1) from the VC, Using hostd "
               + "Create a VM (VM1) to connect to a ephemeral " + "portgroup.")
   public void test()
      throws Exception
   {
      boolean status = false;
      ManagedObjectReference hostHostMor = null;
      UserSession newLoginSession = null;
      AuthorizationManager newAuthentication = null;
      ManagedObjectReference newAuthenticationMor = null;
      try {
         newAuthentication = new AuthorizationManager(hostConnectAnchor);
         sessionManager = new SessionManager(hostConnectAnchor);
         newAuthenticationMor = sessionManager.getSessionManager();
         if (newAuthenticationMor != null) {
            newLoginSession = sessionManager.login(newAuthenticationMor,
                     TestConstants.ESX_USERNAME, TestConstants.ESX_PASSWORD,
                     null);
            if (newLoginSession != null) {
               this.ivm = new VirtualMachine(this.hostConnectAnchor);
               this.ihs = new HostSystem(this.hostConnectAnchor);
               hostHostMor = this.ihs.getConnectedHost(false);
               this.vmMor = new Folder(hostConnectAnchor).createVM(
                        this.ivm.getVMFolder(), this.vmConfigSpec,
                        this.ihs.getPoolMor(hostHostMor), hostHostMor);
               if (this.vmMor != null) {
                  log.info("Successfully created VM.");
                  status = true;
               } else {
                  log.error("Unable to create VM.");
               }
            } else {
               log.error("Can not login into the host " + this.hostName);
            }
         } else {
            log.error("The session manager object is null");
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
         status &= false;
      } finally {
         try {
            status &= sessionManager.logout(newAuthenticationMor);
         } catch (Exception e) {
            log.error("Can not logut from hostd");
            TestUtil.handleException(e);
            status &= false;
         }
      }
      assertTrue(status, "Test Failed");
   }

   /**
    * Method to restore the state as it was before the test is started.
    *
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = true;

      this.ihs = new HostSystem(connectAnchor);
      this.ivm = new VirtualMachine(connectAnchor);
      if (this.hostMor != null && !this.ihs.isHostConnected(this.hostMor)) {
         Assert.assertTrue(this.ihs.reconnectHost(hostMor,
                  this.hostConnectSpec, null), " Host not connected");
         if (this.vmName != null && this.vmMor != null) {
            this.vmMor = this.ivm.getVM(this.vmName);
            if (this.vmMor != null) {
               if (this.ivm.destroy(this.vmMor)) {
                  log.info("Destroyed the created VM " + this.vmName);
               } else {
                  log.error("Can not destroy the VM " + this.vmName);
                  status = false;
               }
            }
         }
      }
      status &= super.testCleanUp();
      assertTrue(status, "Cleanup failed");
      return status;
   }
}