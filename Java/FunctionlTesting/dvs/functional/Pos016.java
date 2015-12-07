/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.functional;

import static com.vmware.vcqa.util.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;
import org.testng.annotations.Test;

import com.vmware.vc.DVPortConfigSpec;
import com.vmware.vc.DVSConfigInfo;
import com.vmware.vc.DVSConfigSpec;
import com.vmware.vc.DistributedVirtualPort;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.DistributedVirtualSwitchPortCriteria;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualMachinePowerState;
import com.vmware.vcqa.TestConstants;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Datacenter;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;

/**
 * Unregister a VM that connects to a standalone DVPort, Remove the standalone
 * DVPort from the DVSwitch. Register the VM back.
 */
public class Pos016 extends FunctionalTestBase
{
   // private instance variables go here.
   private ManagedObjectReference vmMor = null;
   private VirtualMachineConfigSpec vmOrgConfigSpec = null;
   private VirtualMachinePowerState oldPowerState = null;
   private String vmName = null;
   private String hostIpAdress = null;
   private String ipAddress = null;
   private String vmPath = null;
   private String[] usedPorts = null;
   private ManagedObjectReference vmParent = null;
   private ManagedObjectReference vmResourcePool = null;
   private static final boolean checkGuest = DVSTestConstants.CHECK_GUEST;
   private Datacenter idc = null;

   /**
    * Sets the test description.
    * 
    * @param testDescription the testDescription to set
    */
   public void setTestDescription()
   {
      setTestDescription("Unregister a VM that connects to a standalone DVPort,"
               + " Remove the standalone DVPort from the DVSwitch. "
               + "Register the VM back.");
   }

   /**
    * Method to setup the environment for the test.
    * 
    * @param connectAnchor ConnectAnchor object
    * @return boolean true if successful, false otherwise.
    */
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean setUpDone = false;
      Vector<ManagedObjectReference> allVms = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      int numCards = 0;
      DVSConfigInfo configInfo = null;
      DVSConfigSpec configSpec = null;
      List<String> freePorts = null;
      DistributedVirtualSwitchPortConnection portConnection = null;
      List<DistributedVirtualSwitchPortConnection> portConnectionList = null;
      VirtualMachineConfigSpec[] vmConfigSpec = null;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
     
         setUpDone = super.testSetUp();
         if (setUpDone) {
            configInfo = this.iDVS.getConfig(this.dvsMor);
            allVms = this.ihs.getAllVirtualMachine(this.hostMor);
            if (allVms != null && allVms.size() > 0) {
               this.vmMor = allVms.get(0);
               if (this.vmMor != null) {
                  this.vmResourcePool = this.ivm.getResourcePool(this.vmMor);
                  this.vmParent = this.ivm.getParentNode(this.vmMor);
                  this.oldPowerState = this.ivm.getVMState(this.vmMor);
                  this.vmName = this.ivm.getVMName(this.vmMor);
                  setUpDone = this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                  if (setUpDone) {
                     log.info("Succesfully powered off the vm "
                              + this.vmName);
                     vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                              this.vmMor, connectAnchor);
                     if (vdConfigSpec != null) {
                        numCards = vdConfigSpec.size();
                        if (numCards > 0) {
                           portCriteria = this.iDVS.getPortCriteria(false,
                                    null, null, null, null, false);
                           freePorts = this.iDVS.fetchPortKeys(this.dvsMor,
                                    portCriteria);
                           if (freePorts == null || freePorts.size() < numCards) {
                              log.info("There are not enough free ports "
                                       + "on the dvs");
                              configSpec = new DVSConfigSpec();
                              configSpec.setConfigVersion(configInfo.getConfigVersion());
                              if (freePorts == null) {
                                 configSpec.setNumStandalonePorts(configInfo.getNumStandalonePorts()
                                          + numCards);
                              } else {
                                 configSpec.setNumStandalonePorts(configInfo.getNumStandalonePorts()
                                          + (numCards - freePorts.size()));
                              }
                              setUpDone = this.iDVS.reconfigure(dvsMor,
                                       configSpec);
                              if (!setUpDone) {
                                 log.error("Can not reconfigure the DVS to"
                                          + " contain the required number "
                                          + "of standalone ports");
                              } else {
                                 log.info("Successfully reconfigured the "
                                          + "DVS to contain the required "
                                          + "number of standalone ports");
                              }
                              freePorts = this.iDVS.fetchPortKeys(this.dvsMor,
                                       portCriteria);
                           }
                           if (freePorts != null
                                    && freePorts.size() >= numCards) {
                              this.usedPorts = freePorts.toArray(new String[freePorts.size()]);
                              portConnectionList = new ArrayList<DistributedVirtualSwitchPortConnection>(
                                       numCards);
                              for (int i = 0; i < numCards; i++) {
                                 portConnection = new DistributedVirtualSwitchPortConnection();
                                 portConnection.setPortKey(freePorts.get(i));
                                 portConnection.setSwitchUuid(this.dvSwitchUUID);
                                 portConnectionList.add(portConnection);
                              }
                              vmConfigSpec = DVSUtil.getVMConfigSpecForDVSPort(
                                       this.vmMor,
                                       connectAnchor,
                                       portConnectionList.toArray(new DistributedVirtualSwitchPortConnection[portConnectionList.size()]));
                              if (vmConfigSpec != null
                                       && vmConfigSpec.length == 2
                                       && vmConfigSpec[0] != null
                                       && vmConfigSpec[1] != null) {
                                 setUpDone = this.ivm.reconfigVM(this.vmMor,
                                          vmConfigSpec[0]);
                                 if (setUpDone) {
                                    this.vmOrgConfigSpec = vmConfigSpec[1];
                                    log.info("Successfully reconfigured the"
                                             + " VM to use the DV Ports");
                                    setUpDone = this.ivm.powerOnVM(this.vmMor,
                                             null, checkGuest);
                                    if (setUpDone) {
                                       log.info("successfully powered on"
                                                + " the VM " + this.vmName);
                                    } else {
                                       log.error("can not power on the VM "
                                                + this.vmName);
                                       assertTrue(setUpDone, "Setup failed");
                                       return setUpDone;
                                    }
                                 } else {
                                    log.error("Can not reconfigure the VM"
                                             + " to use the DV Ports");
                                 }
                              } else {
                                 log.error("Can not obtain the original and "
                                          + "VM config spec to update to");
                              }
                           } else {
                              setUpDone = false;
                              log.error("Can not find enough free "
                                       + "standalone ports to "
                                       + "reconfigure the VM");
                           }
                        } else {
                           setUpDone = false;
                           log.error("There are no ethernet cards configured"
                                    + " on the VM");
                        }
                     } else {
                        setUpDone = false;
                        log.error("The vm does not have any ethernet cards"
                                 + " configured");
                     }
                  } else {
                     log.error("Can not power off the VM " + this.vmName);
                  }
               } else {
                  setUpDone = false;
                  log.error("The vm mor object is null");
               }
            } else {
               setUpDone = false;
               log.error("Can not find any vm's on the host");
            }

            if (setUpDone) {
               if (checkGuest) {
                  this.ipAddress = this.ivm.getIPAddress(this.vmMor);
                  if (this.ipAddress != null) {
                     this.hostIpAdress = this.ihs.getIPAddress(this.hostMor);
                     if (this.hostIpAdress != null) {
                        setUpDone = DVSUtil.checkNetworkConnectivity(
                                 this.hostIpAdress, this.ipAddress, true);
                        if (setUpDone) {
                           log.info("The vm has the network connectivity");

                        } else {
                           log.error("The VM does not have network connectivity");
                        }
                     } else {
                        setUpDone = false;
                        log.error("Can not get the host ipaddress "
                                 + this.ihs.getHostName(this.hostMor));
                     }
                  } else {
                     setUpDone = false;
                     log.error("Can not get a valid ip for the VM "
                              + this.vmName);
                  }
               }
               if (setUpDone) {
                  this.vmPath = this.ivm.getVMConfigInfo(this.vmMor).getFiles().getVmPathName();
                  if (this.vmPath != null) {
                     setUpDone = this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false);
                     if (setUpDone) {
                        log.info("Succesfully powered off the VM "
                                 + this.vmName);
                     } else {
                        log.error("Can not power off the VM "
                                 + this.vmName);
                     }
                  } else {
                     log.error("Can not get the path to the VM "
                              + this.vmName);
                     setUpDone = false;
                  }
               }
            }
         }
     
      assertTrue(setUpDone, "Setup failed");
      return setUpDone;
   }

   /**
    * Method that performs the test.
    * 
    * @param connectAnchor ConnectAnchor object
    */
   @Test(description = "Unregister a VM that connects to a standalone DVPort,"
               + " Remove the standalone DVPort from the DVSwitch. "
               + "Register the VM back.")
   public void test()
      throws Exception
   {
      log.info("Test Begin:");
      boolean testDone = false;
      DistributedVirtualSwitchPortCriteria portCriteria = null;
      List<DVPortConfigSpec> portConfigSpecs = null;
      DistributedVirtualPort port = null;
      DVPortConfigSpec portConfigSpec = null;
      List<DistributedVirtualPort> ports = null;
      Iterator<DistributedVirtualPort> it = null;
     
         testDone = this.ivm.unregisterVM(this.vmMor);
         if (testDone) {
            if (this.usedPorts != null && this.usedPorts.length > 0) {
               portCriteria = this.iDVS.getPortCriteria(null, null, null, null,
                        this.usedPorts, false);
               ports = this.iDVS.fetchPorts(dvsMor, portCriteria);
               if (ports != null && ports.size() > 0) {
                  it = ports.iterator();
                  while (it.hasNext()) {
                     if (portConfigSpecs == null) {
                        portConfigSpecs = new ArrayList<DVPortConfigSpec>();
                     }
                     port = it.next();
                     portConfigSpec = new DVPortConfigSpec();
                     if (port.getConfig() != null) {
                        portConfigSpec.setConfigVersion(port.getConfig().getConfigVersion());
                     }
                     portConfigSpec.setOperation(TestConstants.CONFIG_SPEC_REMOVE);
                     portConfigSpec.setKey(port.getKey());
                     portConfigSpecs.add(portConfigSpec);
                  }
                  if (portConfigSpecs != null && portConfigSpecs.size() > 0) {
                     testDone = this.iDVS.reconfigurePort(
                              this.dvsMor,
                              portConfigSpecs.toArray(new DVPortConfigSpec[portConfigSpecs.size()]));
                     if (testDone) {
                        log.info("Successfully removed the used ports ");
                        idc = new Datacenter(connectAnchor);
                        this.vmMor = new com.vmware.vcqa.vim.Folder(
                                 super.getConnectAnchor()).registerVm(
                                 this.vmParent, this.vmPath, this.vmName,
                                 false, this.vmResourcePool, this.hostMor);
                        if (this.vmMor != null) {
                           testDone = this.ivm.powerOnVM(this.vmMor, null,
                                    checkGuest);
                           if (testDone) {
                              log.info("Successfully powered on the VM "
                                       + this.vmName);
                              if (checkGuest) {
                                 this.ipAddress = this.ivm.getIPAddress(this.vmMor);
                                 if (ipAddress == null) {
                                    log.info("Verified that there is no network "
                                             + "connectivity to the VM "
                                             + this.vmName);
                                 } else {
                                    testDone = false;
                                    log.error("There is network connectivity to "
                                             + "the VM " + this.vmName);
                                 }
                              }
                           } else {
                              log.error("Can not power on the VM "
                                       + this.vmName);
                           }
                        } else {
                           testDone = false;
                           log.error("Can not power on the VM "
                                    + this.vmName);
                        }
                     }
                  } else {
                     log.error("Can not reconfigure the DVS "
                              + this.iDVS.getName(this.dvsMor));
                  }
               } else {
                  log.error("There are no standalone ports on the switch");
               }
            } else {
               testDone = false;
               log.error("The used ports array is null");
            }
         }
     
      assertTrue(testDone, "Test Failed");
   }

   /**
    * Restores the state prior to running the test.
    * 
    * @param connectAnchor ConnectAnchor Object
    */
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean cleanUpDone = true;
     
         if (this.vmMor != null && !this.iManagedEntity.isExists(this.vmMor)
                  && this.vmName != null) {
            this.vmMor = this.ivm.getVMByName(this.vmName, null);
         }
         if (this.vmMor != null) {
            if (this.vmOrgConfigSpec != null) {
               cleanUpDone &= this.ivm.setVMState(this.vmMor, VirtualMachinePowerState.POWERED_OFF, false);
               log.info("Successfully powered off the VM " + this.vmName);
               if (this.vmOrgConfigSpec != null) {
                  cleanUpDone &= this.ivm.reconfigVM(this.vmMor,
                           this.vmOrgConfigSpec);
                  if (cleanUpDone) {
                     log.info("Successfully reconfigured the VM to it's"
                              + " original config spec " + this.vmName);
                  } else {
                     log.error("Can not reconfigure the VM to it's "
                              + "original state " + this.vmName);
                  }
               }
            } else {
               cleanUpDone = false;
               log.error("Can not power off the VM " + this.vmName);
            }
            if (this.oldPowerState != null) {
               cleanUpDone &= this.ivm.setVMState(this.vmMor,
                        this.oldPowerState, false);
               if (!this.oldPowerState.equals(this.ivm.getVMState(this.vmMor))) {
                  log.error("Can not set the VM " + this.vmName + "to "
                           + this.oldPowerState);
               } else {
                  log.info("Successfully set the VM " + this.vmName
                           + "to " + this.oldPowerState);
               }
            }
         }
         cleanUpDone &= super.testCleanUp();
     
      assertTrue(cleanUpDone, "Cleanup failed");
      return cleanUpDone;
   }
}