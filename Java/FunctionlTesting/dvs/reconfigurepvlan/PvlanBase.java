/*
 * ************************************************************************
 *
 * Copyright 2008 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package dvs.reconfigurepvlan;

import static com.vmware.vc.VirtualMachinePowerState.POWERED_OFF;

import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.testng.annotations.AfterMethod;
import org.testng.annotations.BeforeMethod;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DistributedVirtualSwitchPortConnection;
import com.vmware.vc.HostNetworkConfig;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.MethodFault;
import com.vmware.vc.VirtualDevice;
import com.vmware.vc.VirtualDeviceConfigSpec;
import com.vmware.vc.VirtualDeviceConfigSpecOperation;
import com.vmware.vc.VirtualEthernetCard;
import com.vmware.vc.VirtualMachineConfigInfo;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vc.VirtualPCNet32;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestBase;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.TestUtil;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.VMSpecManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.dvs.DistributedVirtualSwitchHelper;
import com.vmware.vcqa.vim.host.NetworkSystem;

/**
 * Class to manage all PVALN related common functions. <br>
 * This class uses the common code wrapper to aggregate the operations. <br>
 */
public abstract class PvlanBase extends TestBase
{
   /** Primary ID of PVLAN-1 */
   public static final int PVLAN1_PRI_1 = 10;
   /** Primary ID of PVLAN-2 */
   public static final int PVLAN2_PRI_1 = 20;
   /** Secondary ID 1 of PVLAN-1 */
   public static final int PVLAN1_SEC_1 = 101;
   /** Secondary ID 1 of PVLAN-2 */
   public static final int PVLAN2_SEC_1 = 201;
   /** Secondary ID 2 of PVLAN-1 */
   public static final int PVLAN1_SEC_2 = 102;
   /** Secondary ID 2 of PVLAN-2 */
   public static final int PVLAN2_SEC_2 = 202;
   /** VmwareDistributedVirtualSwitch used. */
   protected DistributedVirtualSwitchHelper iVmwareDVS;
   protected Folder iFolder;
   protected VirtualMachine ivm;
   protected HostSystem ihs;
   protected NetworkSystem ins;
   protected ManagedEntity iManagedEntity;
   protected DVPortgroupConfigSpec dvPortgroupConfigSpec;
   protected HostNetworkConfig[] hostNetworkConfig;
   protected ManagedObjectReference dvsMor;
   protected ManagedObjectReference hostMor;
   protected String dvsName;// Name of the DVS to be created.

   /**
    * Default setup for all PVLAN tests.
    *
    * @param connectAnchor ConnectAnchor.
    * @return boolean true, If successful. false, otherwise.
    */
   @Override
   @BeforeMethod(alwaysRun=true)
   public boolean testSetUp()
      throws Exception
   {
      boolean status = false;
     
         dvsName = getTestId() + "-vDS";
         iFolder = new Folder(connectAnchor);
         iManagedEntity = new ManagedEntity(connectAnchor);
         ivm = new VirtualMachine(connectAnchor);
         ihs = new HostSystem(connectAnchor);
         ins = new NetworkSystem(connectAnchor);
         iVmwareDVS = new DistributedVirtualSwitchHelper(connectAnchor);
         status = true;
     
      Assert.assertTrue(status, "Setup failed");
      return status;
   }

   /**
    * Test cleanup. Destroy the DVS if it was create in test setup.
    *
    * @param connectAnchor ConnectAnchor.
    * @return true, if test cleanup was successful. false, otherwise.
    */
   @Override
   @AfterMethod(alwaysRun=true)
   public boolean testCleanUp()
      throws Exception
   {
      boolean status = false;
     
         status = destroy(dvsMor);
     
      return status;
   }

   /**
    * Method to check whether the given PVLAN's have connectivity.<br>
    * To check between a PVLAN and a non PVLAN DVPort use Integer.MAX_VALUE for
    * PvlanIdOne. <br>
    * 1. Power on the VM's. <br>
    * 2. Reconfigure the DVS to set given PVLAN ID's to DVPorts. <br>
    * 3. Reconfigure the VM-1 to use the first DVPort.<br>
    * 4. Reconfigure the VM-2 to use the second DVPort.<br>
    * 5. Now check the connectivity between VM-1 and VM-2. <br>
    * 6. Revert the VM's to previous configuration.<br>
    * 7. Power off the VM's.<br>
    *
    * @param PvlanIdOne the PVLAN ID for first DVPort. if Integer.MAX_VALUE is
    *           given a DVPort without any PVLAN will be used.
    * @param PvlanIdTwo the PVLAN ID for second DVPort.
    * @param vm1Mor VM used to assign to PvlanIdOne.
    * @param vm2Mor VM used to assign to PvlanIdTwo.
    * @return true if connected else false.
    */
   public boolean areConnected(ConnectAnchor connectAnchor,
                               int PvlanIdOne,
                               int PvlanIdTwo,
                               ManagedObjectReference vm1Mor,
                               ManagedObjectReference vm2Mor)
      throws Exception
   {
      boolean status = false;
      boolean setupFail = false;
      String dvsUuid = null;
      String portOne = null;
      String portTwo = null;
      String vm1Name = null;
      String vm2Name = null;
      Map<String, String> vm1Ips = null;
      Map<String, String> vm2Ips = null;
      String vm1Ip = null; // IP which uses VM network
      String vm1PvlanIp = null;
      String vm2PvlanIp = null;
      /* delta for reconfiguring and reverting the VM back. */
      VirtualMachineConfigSpec[] deltaVm1ConfigSpecs = null;
      VirtualMachineConfigSpec[] deltaVm2ConfigSpecs = null;
      List<VirtualDeviceConfigSpec> vdConfigSpec = null;
      VirtualMachineConfigInfo vm1ConfigInfo = null;
      DistributedVirtualSwitchPortConnection dvsConn1 = null;
      DistributedVirtualSwitchPortConnection dvsConn2 = null;
      VirtualMachineConfigSpec vmConfigSpec = null;
      VMSpecManager vmSpecManager = ivm.getVMSpecManager(ihs.getResourcePool(
               hostMor).get(0), hostMor);
      List<VirtualDeviceConfigSpec> deviceSpecList = null;
      VirtualDeviceConfigSpec ethernetCardSpec = null;
      boolean srcLinux = true;
      Vector<ManagedObjectReference> vms = null;
      try {
         if (vm1Mor != null && vm2Mor != null) {
            vm1Name = ivm.getName(vm1Mor);
            vm2Name = ivm.getName(vm2Mor);
            dvsUuid = iVmwareDVS.getConfig(dvsMor).getUuid();
            if (ivm.setVMState(vm1Mor, POWERED_OFF, false)
                     && ivm.setVMState(vm2Mor, POWERED_OFF, false)) {
               vm1ConfigInfo = ivm.getVMConfigInfo(vm1Mor);
               if (vm1ConfigInfo != null
                        && vm1ConfigInfo.getGuestFullName() != null
                        && vm1ConfigInfo.getGuestFullName().indexOf("Windows") != -1) {
                  srcLinux = false;
               }
               vdConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(vm1Mor,
                        connectAnchor);
               if (vdConfigSpec == null || vdConfigSpec.size() < 2) {
                  deviceSpecList = new ArrayList<VirtualDeviceConfigSpec>();
                  ethernetCardSpec = vmSpecManager.createEthCardSpec(
                           deviceSpecList, VirtualPCNet32.class, null, null);
                  deviceSpecList.add(ethernetCardSpec);
                  if (vdConfigSpec == null || vdConfigSpec.size() == 0) {
                     ethernetCardSpec = vmSpecManager.createEthCardSpec(
                              deviceSpecList, VirtualPCNet32.class, null, null);
                     deviceSpecList.add(ethernetCardSpec);
                  }
                  vmConfigSpec = new VirtualMachineConfigSpec();
                  vmConfigSpec.getDeviceChange().clear();
                  vmConfigSpec.getDeviceChange().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(deviceSpecList.toArray(new VirtualDeviceConfigSpec[deviceSpecList.size()])));
                  if (ivm.reconfigVM(vm1Mor, vmConfigSpec)) {
                     log.info("Successfully reconfigure the VM to have the "
                              + "required number of ethernet adapters");
                  } else {
                     log.error("Can not reconifgure the VM to have the "
                              + "required number of ethernet adapters");
                     setupFail = true;
                  }
               }
               if (!setupFail) {
                  portTwo = iVmwareDVS.assignPvlanToPort(dvsMor, PvlanIdTwo);
                  if (PvlanIdOne == Integer.MAX_VALUE) {
                     portOne = iVmwareDVS.addStandaloneDVPorts(dvsMor, 1).get(0);
                  } else {
                     portOne = iVmwareDVS.assignPvlanToPort(dvsMor, PvlanIdOne);
                     log.info("Connecting " + vm1Name
                              + " to first PVLAN: " + PvlanIdOne);
                  }
                  dvsConn1 = new DistributedVirtualSwitchPortConnection();
                  dvsConn1.setPortKey(portOne);
                  dvsConn1.setSwitchUuid(dvsUuid);
                  deltaVm1ConfigSpecs = DVSUtil.getVMConfigSpecForDVSPort(
                           vm1Mor,
                           connectAnchor,
                           new DistributedVirtualSwitchPortConnection[] { dvsConn1 });
                  if (deltaVm1ConfigSpecs != null
                           && ivm.reconfigVM(vm1Mor, deltaVm1ConfigSpecs[0])) {
                     log.info("Successfully reconfigured the VM1:"
                              + vm1Name);
                     log.info("Now connecting VM2: " + vm2Name
                              + " to second PVLAN: " + PvlanIdTwo);
                     dvsConn2 = new DistributedVirtualSwitchPortConnection();
                     dvsConn2.setPortKey(portTwo);
                     dvsConn2.setSwitchUuid(dvsUuid);
                     deltaVm2ConfigSpecs = DVSUtil.getVMConfigSpecForDVSPort(
                              vm2Mor,
                              connectAnchor,
                              new DistributedVirtualSwitchPortConnection[] { dvsConn2 });
                     if (deltaVm2ConfigSpecs != null
                              && ivm.reconfigVM(vm2Mor, deltaVm2ConfigSpecs[0])) {
                        log.info("Successfully reconfigured VM2: "
                                 + vm2Name);
                        log.info("Now we have two VMs connected to DVPorts with "
                                 + "PVLAN's, so checking for connectivity...");
                        vms = new Vector<ManagedObjectReference>();
                        vms.add(vm1Mor);
                        vms.add(vm2Mor);
                        ivm.powerOnVMs(vms, true);
                        DVSUtil.WaitForIpaddress();
                        vm1Ips = ivm.getAllIPAddresses(vm1Mor);
                        vm2Ips = ivm.getAllIPAddresses(vm2Mor);
                        if (vm1Ips != null && vm2Ips != null) {
                           log.info("VM1: " + vm1Ips + " VM2: " + vm2Ips);
                           if (vm1Ips.size() >= 2 && vm2Ips.size() >= 1) {
                              vm1PvlanIp = vm1Ips.remove(getMac(deltaVm1ConfigSpecs[0]));
                              if (vm1Ips.keySet().iterator().hasNext()) {
                                 vm1Ip = vm1Ips.get(vm1Ips.keySet().iterator().next());
                              }
                              String vm2Ip = null;
                              vm2PvlanIp = vm2Ips.remove(getMac(deltaVm2ConfigSpecs[0]));
                              log.info(vm1Name + " : PVLAN IP="
                                       + vm1PvlanIp + "  IP=" + vm1Ip);
                              log.info(vm2Name + " : PVLAN IP="
                                       + vm2PvlanIp);
                              if (vm1Ip != null && vm2PvlanIp != null) {
                                 status = DVSUtil.checkNetworkConnectivity(
                                          vm1Ip, vm2PvlanIp, srcLinux);
                                		 //vm1Ip, vm2Ip, srcLinux);
                                 if (status) {
                                    log.info(" Status : Connected.");
                                 } else {
                                    log.info(" Status : Not Connected.");
                                 }
                              } else {
                                 log.error("Can not get the valid ip's for "
                                          + "the VM's");
                                 setupFail = true;
                              }
                           } else {
                              log.error("Not of expected size 2.");
                              setupFail = true;
                           }
                        } else {
                           log.error("Null IP's in VM's");
                           setupFail = true;
                        }
                     } else {
                        log.error("Failed to reconfigure the VM2");
                        setupFail = true;
                     }
                  } else {
                     log.error("Failed to reconfigure the VM1");
                     setupFail = true;
                  }
               }
            } else {
               log.error("Can not power off the VM's");
            }
         } else {
            log.error("The VM mor is null");
            setupFail = true;
         }
      } catch (Exception e) {
         TestUtil.handleException(e);
      } finally {
         try {
            if (deltaVm1ConfigSpecs != null
                     && ivm.reconfigVM(vm1Mor, deltaVm1ConfigSpecs[1])) {
               log.info("Successfully reverted VM1 to previous configuration.");
            } else {
               log.error("Failed to revert VM1 to previous configuration.");
            }
         } catch (Exception e) {
            log.error("Failed to revert VM1 to previous configuration.");
            TestUtil.handleException(e);
         }
         try {
            VirtualEthernetCard ethCard = null;
            VirtualEthernetCard ethCard1 = null;
            List<VirtualDeviceConfigSpec> updatedVDConfigSpec = DVSUtil.getAllVirtualEthernetCardDevices(
                     vm1Mor, connectAnchor);
            VirtualMachineConfigSpec updatedVMConfigSpec = null;
            if (updatedVDConfigSpec.size() > vdConfigSpec.size()) {
               Iterator<VirtualDeviceConfigSpec> it = updatedVDConfigSpec.iterator();
               while (it.hasNext()) {
                  ethernetCardSpec = it.next();
                  if (ethernetCardSpec.getDevice() instanceof VirtualEthernetCard) {
                     ethCard = (VirtualEthernetCard) ethernetCardSpec.getDevice();
                     for (VirtualDeviceConfigSpec originalConfigSpec : vdConfigSpec) {
                        if (originalConfigSpec.getDevice() instanceof VirtualEthernetCard) {
                           ethCard1 = (VirtualEthernetCard) originalConfigSpec.getDevice();
                           if (ethCard1.getMacAddress().equals(
                                    ethCard.getMacAddress())) {
                              it.remove();
                              break;
                           }
                        }
                     }
                  }
               }
               for (VirtualDeviceConfigSpec configSpec : updatedVDConfigSpec) {
                  configSpec.setOperation(VirtualDeviceConfigSpecOperation.REMOVE);
               }
               updatedVMConfigSpec = new VirtualMachineConfigSpec();
               updatedVMConfigSpec.getDeviceChange().clear();
               updatedVMConfigSpec.getDeviceChange().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(updatedVDConfigSpec.toArray(new VirtualDeviceConfigSpec[updatedVDConfigSpec.size()])));
               ivm.reconfigVM(vm1Mor, updatedVMConfigSpec);
            }
         } catch (Exception e) {
            log.error("Can not remove the added virtual device config spec");
            TestUtil.handleException(e);
         }
         try {
            if (deltaVm2ConfigSpecs != null
                     && ivm.reconfigVM(vm2Mor, deltaVm2ConfigSpecs[1])) {
               log.info("Successfully reverted VM2 to previous configuration.");
            } else {
               log.error("Failed to revert VM2 to previous configuration.");
            }
         } catch (Exception e) {
            log.error("Failed to revert VM2 to previous configuration.");
            TestUtil.handleException(e);
         }
         try {
            if (ivm.setVMState(vm1Mor, POWERED_OFF, false)) {
               log.info("Successfully powered off VM1");
            }
            if (ivm.setVMState(vm2Mor, POWERED_OFF, false)) {
               log.info("Successfully powered off VM2");
            }
         } catch (Exception e) {
            log.error("Failed to power off VM's.");
            TestUtil.handleException(e);
         }
         if (setupFail) {
            throw new Exception("Can not setup the VM's to check the "
                     + "network connectivity");
         }
      }
      return status;
   }

   /**
    * Destroy given managed entity.
    *
    * @param mor MOR of the entity to be destroyed.
    * @return boolean true, if destroyed.
    */
   public boolean destroy(ManagedObjectReference mor)
   {
      boolean status = false;
      if (mor != null) {
         try {
            log.info("Destroying: " + iManagedEntity.getName(mor));
            status = iManagedEntity.destroy(mor);
         } catch (Exception e) {
            TestUtil.handleException(e);
         }
      } else {
         log.info("Given MOR is null");
         status = true;
      }
      Assert.assertTrue(status, "Cleanup failed");
      return status;
   }

   // get the MAC from the delta VMCfgSpec which has one change
   private String getMac(VirtualMachineConfigSpec configSpec)
   {
      String macAddress = null;
      VirtualDeviceConfigSpec[] devChanges = com.vmware.vcqa.util.TestUtil.vectorToArray(configSpec.getDeviceChange(), com.vmware.vc.VirtualDeviceConfigSpec.class);
      if (devChanges != null && devChanges.length >= 1) {
         VirtualDeviceConfigSpec devChange = devChanges[0];
         VirtualDevice vd = devChange.getDevice();
         if (VirtualEthernetCard.class.isInstance(vd)) {
            VirtualEthernetCard vEthCard = VirtualEthernetCard.class.cast(vd);
            vEthCard.getBacking();
            macAddress = vEthCard.getMacAddress();
         } else {
            log.error("the VirtualDevice is not a ethernet card.");
         }
      } else {
         log.error("Device change is null or of invalid length");
      }
      return macAddress;
   }
}
