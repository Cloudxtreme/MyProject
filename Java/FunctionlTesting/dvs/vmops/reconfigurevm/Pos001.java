/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.vmops.reconfigurevm;

import static com.vmware.vcqa.TestConstants.VM_VIRTUALDEVICE_ETHERNET_PCNET32;

import org.testng.annotations.BeforeMethod;

/**
 * Reconfigure a VM on a standalone host to connect to an existing standalone DV
 * port. The device is of type VirtualPCNet32, the backing is of type DVPort
 * backing and the port connection is a DVPort connection.
 */
public class Pos001 extends CopyOfReconfigureVMBase
{
   @Override
   public void setTestDescription()
   {
      setTestDescription(" Reconfigure a VM on a standalone host to connect"
               + " to an existing standalone DV port. The device is of type"
               + " VirtualPCNet32, the  backing is of type DVPort backing"
               + " and the port connection is a DVPort connection.");
   }

   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      deviceType = VM_VIRTUALDEVICE_ETHERNET_PCNET32;
      return super.testSetUp();
   }
}
