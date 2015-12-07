/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_VMXNET;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EARLY_BINDING;

import org.testng.annotations.BeforeMethod;



/**
 * Reconfigure a VM on a standalone host to connect to an existing earlyBinding
 * DVPortgroup. The device is of type VirtualVmxNet, the backing is of type
 * DVPort backing and the port connection is a DVPortgroup connection.
 */
public class Pos006 extends ReconfigureVMBase
{

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a VM on a standalone host to connect"
               + " to an existing earlybinding DVportgroup. The device is "
               + "of type VirtualVmxNet, the  backing is of type DVPort backing"
               + " and the port connection is a DVPortgroup connection.");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true, if setup is successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      log.info("test setup Begin:");
      deviceType = VM_VIRTUALDEVICE_ETHERNET_VMXNET;
      connectToPort = false;
      portgroupType = DVPORTGROUP_TYPE_EARLY_BINDING;
      return super.testSetUp();
   }
}
