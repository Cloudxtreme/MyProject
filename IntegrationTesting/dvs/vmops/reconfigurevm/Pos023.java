/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;
import static com.vmware.vcqa.vim.dvs.DVSTestConstants.DVPORTGROUP_TYPE_EPHEMERAL;

import org.testng.annotations.BeforeMethod;



/**
 * Reconfigure a VM to an existing ephemeral DVPortgroup. The device is of type
 * VirtualPCNet32, the backing is of type DVPort backing and the port connection
 * is a DVPortgroup connection.
 */
public class Pos023 extends ReconfigureVMBase
{

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a VM on a standalone host to connect"
               + " to an existing ephemeral DVPortgroup. The device is "
               + "of type VirtualPCNet32, the  backing is of type "
               + "DVPort backing and the port connection is a "
               + "DVPortgroup connection.");
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
      deviceType = VM_VIRTUALDEVICE_ETHERNET_PCNET32;
      connectToPort = false;
      portgroupType = DVPORTGROUP_TYPE_EPHEMERAL;
      return super.testSetUp();
   }
}