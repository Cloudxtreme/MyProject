/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_VMXNET2;

import org.testng.annotations.BeforeMethod;



/**
 * Reconfigure a VM on a standalone host to connect to an existing standalone DV
 * port. The device is of type VirtualVMXNet2, the backing is of type DVPort
 * backing and the port connection is a DVPort connection.
 */
public class Pos004 extends ReconfigureVMBase
{

   /**
    * Set test description.
    */
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a VM on a standalone host to connect"
               + " to an existing standalone DV port. The device is of type"
               + " VirtualVMXNet2, the  backing is of type DVPort backing"
               + " and the port connection is a DVPort connection.");
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
      deviceType = VM_VIRTUALDEVICE_ETHERNET_VMXNET2;
      return super.testSetUp();
   }
}