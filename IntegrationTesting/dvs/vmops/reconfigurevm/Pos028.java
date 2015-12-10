/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vc.HostSystemConnectionState.CONNECTED;
import static com.vmware.vc.VirtualDeviceConfigSpecOperation.REMOVE;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;
import static com.vmware.vc.VirtualMachinePowerState.POWERED_ON;
import static com.vmware.vcqa.TestConstants.CHANGEMODE_MODIFY;
import static com.vmware.vcqa.util.Assert.assertNotNull;
import static com.vmware.vcqa.util.Assert.assertTrue;
import static com.vmware.vcqa.util.VersionConstants.ESX4x;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.HOST_GET_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_CREATE_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWEROFF_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_FAIL;
import static com.vmware.vcqa.vim.MessageConstants.VM_POWERON_PASS;
import static com.vmware.vcqa.vim.MessageConstants.VM_RECONFIG_FAIL;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.CHECK_GUEST;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.OptionValue;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.internal.vim.dvs.InternalDVSHelper;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.util.ThreadUtil;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.HostSystemInformation;

import dvs.vmops.VMopsBase;



/**
 * Reconfigure a VM on a standalone host to connect to an existing standalone DV
 * port. The device is of type VirtualVmxNet, the backing is of type DVPort
 * backing and the port connection is a DVPort connection.
 */
public class Pos028 extends VMopsBase
{

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true, if setup is successful. false, otherwise.
    */

   protected String deviceType = null;
   protected DistributedVirtualSwitchPortConnection dvsPortConnection = null;
   protected String dvSwitchUuid = null;
   protected String portKey = null;
   protected ManagedObjectReference vmMor = null;
   protected String vmName = null;
   protected VirtualMachineConfigSpec originalVMConfigSpec = null;
   protected String hostIPAddress = null;
   protected String testHostName = null;
   protected String portgroupType = null;
   protected boolean connectToPort = true;
   protected boolean vmCreated;

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp() throws Exception
   {
      boolean status = false;
      Map<ManagedObjectReference, HostSystemInformation> allHosts;
      Vector<ManagedObjectReference> hostVMs;
      assertTrue(super.testSetUp(), "Super setup failed.");
      allHosts = ihs.getAllHosts(ESX4x, CONNECTED);
      log.info("all host");
      assertNotNull(allHosts, HOST_GET_PASS, HOST_GET_FAIL);
      hostMor = allHosts.keySet().iterator().next();
      hostIPAddress = ihs.getIPAddress(hostMor);
      testHostName = ihs.getHostName(hostMor);
      while(!hostIPAddress.equals("10.144.138.3")&(allHosts.keySet().iterator().next()!=null)){
    	  hostMor = allHosts.keySet().iterator().next();
          hostIPAddress = ihs.getIPAddress(hostMor);
          testHostName = ihs.getHostName(hostMor);
      }
      log.info("Host MOR: " + hostMor + "   Host Name: " + testHostName);
      hostVMs = ihs.getVMs(hostMor, null);
      /* If no VM's are found create one */
      if (hostVMs == null || hostVMs.isEmpty()) {
         log.warn("No VMs found in host: " + testHostName
                  + ", Creating...");
         vmName = getTestId() + "-vDS";
         vmMor = ivm.createDefaultVM(vmName, ihs.getPoolMor(hostMor), null);
         assertNotNull(vmMor, VM_CREATE_PASS, VM_CREATE_FAIL);
         vmCreated = true;
      } else {
    	 log.info("in else");
    	 for(ManagedObjectReference Mor:hostVMs){	 
    		 vmName = ivm.getName(Mor);
    		 log.info("vm name:"+vmName);
    		 if(vmName.equals("test")){
    			 vmMor = Mor;
    			 break;
    		 }
         }
      }
      status = true;   
      assertTrue(status, "Setup failed");
      return status;
   }
   
   @Override
   @Test
   public void test()
      throws Exception
   {
       log.info("in test");
	   VirtualMachineConfigSpec vmCfgSpecs;

	   vmCfgSpecs = ivm.getVMConfigSpec(vmMor);
       
	   if (vmCfgSpecs != null) {
	       log.info("Successfully obtained the VM config"
	                  + " spec to update to");
	       originalVMConfigSpec = vmCfgSpecs;
	       log.info("Now reconfigure the VM to have required adopter only");
	       List<OptionValue> extra = new ArrayList<OptionValue>();
	       OptionValue opt = new OptionValue();
	       opt.setKey("ethernet1.filter0.name");
	       opt.setValue("dvfilter-fw");
	       //opt.setValue("");
	       extra.add(opt);
	       //extra = vmCfgSpecs.getExtraConfig();
	       //OptionValue opt1 = new OptionValue();
	      // opt1.setKey("dvfilterctl");
	      // opt.setValue("dvfilter-fw");
	      // opt1.setValue("dvfilter-generic");
	      // extra.add(opt1);
	       vmCfgSpecs.setExtraConfig(extra);

	       assertTrue(ivm.reconfigVM(vmMor, vmCfgSpecs), VM_RECONFIG_FAIL);
	    }
	   else{
		   log.info("vm0 is empty");
	   }
   }

   /**
    * Method to restore the state as it was before the test is started.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return <code>true</code> if successful.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
	   return true;
   }


}


