package com.vmware.vcqa.vim.dvs.listeners;

import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.apache.commons.configuration.HierarchicalConfiguration;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.IInvokedMethod;
import org.testng.IInvokedMethodListener;
import org.testng.ITestNGMethod;
import org.testng.ITestResult;

import com.vmware.vc.HostNetworkInfo;
import com.vmware.vc.HostVirtualNic;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VirtualMachineConfigSpec;
import com.vmware.vcqa.ConnectAnchor;
import com.vmware.vcqa.TestLogHelper;
import com.vmware.vcqa.execution.TestDataHandler;
import com.vmware.vcqa.util.NetworkUtil;
import com.vmware.vcqa.vim.DistributedVirtualSwitch;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.SessionManager;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.dvs.DVSTestConstants;
import com.vmware.vcqa.vim.dvs.DVSUtil;
import com.vmware.vcqa.vim.host.NetworkSystem;

public class VdsCleanupListener implements IInvokedMethodListener
{

   protected static final Logger log = LoggerFactory.getLogger(
            VdsCleanupListener.class);

   @Override
   public void afterInvocation(IInvokedMethod invokedMethod,
                               ITestResult testResult)
   {
       ITestNGMethod method = invokedMethod.getTestMethod();
       boolean vdsCleanup = false;
       String testName = testResult.getTestClass().getName();
       vdsCleanup = TestDataHandler.getSingleton().getData().
               getBoolean("vdsCleanup");
       if (testName.startsWith("dvs")
               && !testName.startsWith("dvs.functional.netvcops")
               && !vdsCleanup) {
          vdsCleanup = true;
       }
       if(method.isAfterClassConfiguration() &&
          method.getMethodName().equalsIgnoreCase("postCleanUp")){
         if(vdsCleanup){
            /*
             * Check inventory status for stale vdses and connect all
             * networking entities using the default network configuration
             */
            try{
               TestLogHelper.startTestLogging("vdscleanup");
                /*
                * For all vms in the inventory, make sure that no vm
                * is connected to a vds
                */
               HierarchicalConfiguration config = (HierarchicalConfiguration)
                        TestDataHandler.getSingleton().getData();
               if(config != null){
                  String hostName = config.getString("hostname");
                  int port = config.getInt("port");
                  String userName = config.getString("username");
                  String password = config.getString("password");
                  ConnectAnchor connectAnchor = new ConnectAnchor(hostName,
                                                                  port);
                  SessionManager.login(connectAnchor, userName, password);
                  VirtualMachine virtualMachine = new
                           VirtualMachine(connectAnchor);
                  Folder f = new Folder(connectAnchor);
                  Vector<ManagedObjectReference> vmList = virtualMachine.
                           getAllVM();
                  List<ManagedObjectReference> vdsMorList =
                          f.getAllDistributedVirtualSwitch(f.
                          getNetworkFolder(f.getDataCenter()));
                  if(vmList != null && vdsMorList != null &&
                          vdsMorList.size() >=1 ){
                     for(ManagedObjectReference vm : vmList){
                         /*
                          * Iterate through the list of ethernet devices
                          */
                         String vmName = virtualMachine.getName(vm);
                         log.info("Checking the vm : " + vmName +
                                 " network backing" );
                         Map<String, String> vmEthernetMap = NetworkUtil.
                                 getEthernetCardNetworkMap(vm, connectAnchor);
                         boolean reconfigure = false;
                         for(String ethernetCard : vmEthernetMap.keySet()){
                             String pgName = vmEthernetMap.get(ethernetCard);
                             if(!pgName.equals("VM Network")){
                                 vmEthernetMap.put(ethernetCard, "VM Network");
                                 reconfigure = true;
                             }
                         }
                         if(reconfigure){
                             VirtualMachineConfigSpec reconfigVmConfigSpec =
                             NetworkUtil.reconfigureVMConnectToPortgroup(vm,
                                             connectAnchor, vmEthernetMap);
                             virtualMachine.reconfigVM(vm,
                                     reconfigVmConfigSpec);
                         }
                    }
                     /*
                      * For all hosts in the inventory, make sure that there is
                      * exactly one virtual nic and no extra nics.
                      */
                     HostSystem hostSystem = new HostSystem(connectAnchor);
                     NetworkSystem networkSystem = new
                              NetworkSystem(connectAnchor);
                     Vector<ManagedObjectReference> hostList = hostSystem.
                              getAllHost();
                     for(ManagedObjectReference host : hostList){
                        ManagedObjectReference networkMor = networkSystem.
                                 getNetworkSystem(host);
                        HostNetworkInfo networkInfo = networkSystem.
                                 getNetworkInfo(networkMor);
                        List<HostVirtualNic> virtualNicList = networkInfo.
                                 getVnic();
                        for(HostVirtualNic hostVirtualNic : virtualNicList){
                           String vNicKey = hostVirtualNic.getDevice();
                           String pgName = hostVirtualNic.getPortgroup();
                           log.info("vnic key : " + vNicKey);
                           log.info("Portgroup name : " + pgName);
                           if(!pgName.equalsIgnoreCase("Management Network") &&
                              !pgName.equalsIgnoreCase("VMkernel")){
                              log.info("Found a vmkernel nic not " +
                                       "connected to the management network " +
                                       "or the VMKernel portgroup : "
                                       + vNicKey);
                              log.info("Removing this host vnic");
                              networkSystem.removeVirtualNic(networkMor,
                                      vNicKey);
                           }
                        }
                     }
                     /*
                      * Remove all vdses in the inventory
                      */

                     DistributedVirtualSwitch vds = new
                              DistributedVirtualSwitch(connectAnchor);
                     if(vdsMorList != null && vdsMorList.size() >= 1){
                         for(ManagedObjectReference vdsMor : vdsMorList){
                             log.info("Destroying switch : " +
                                      vds.getName(vdsMor));
                             vds.destroy(vdsMor);
                         }
                     }
                  } else{
                      log.info("There are no distributed virtual switches " +
                              "in the inventory");
                  }
                  SessionManager.logout(connectAnchor);
               }
            }catch(Exception e){
               e.printStackTrace();
            }finally{
                TestLogHelper.stopTestLogging();
            }
         }
      }
   }

   @Override
   public void beforeInvocation(IInvokedMethod arg0,
                                ITestResult arg1)
   {
      /*
       * No-op
       */

   }

}
