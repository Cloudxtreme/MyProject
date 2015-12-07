/* ************************************************************************
 *
 * Copyright 2006 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;

import java.util.Arrays;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.MethodFault;
import com.vmware.vcqa.cim.CIMConstants;
import com.vmware.vcqa.cim.ICIMListener;
import com.vmware.vcqa.cim.ICIMSDK;
import com.vmware.vcqa.cim.ICIMWBEM;
import com.vmware.vcqa.cim.ManagedCIMListener;
import com.vmware.vcqa.cim.ManagedCIMSDK_ESX30;
import com.vmware.vcqa.cim.ManagedCIMWsMan;
import com.vmware.vcqa.cim.ManagedCIMXML;
import com.vmware.vcqa.query.PropertyCollector;
import com.vmware.vcqa.util.OperationThreadConstants;
import com.vmware.vcqa.vim.BaseUserAgent;
import com.vmware.vcqa.vim.ClusterComputeResource;
import com.vmware.vcqa.vim.CoreUserAgent;
import com.vmware.vcqa.vim.CustomizationHelper;
import com.vmware.vcqa.vim.Folder;
import com.vmware.vcqa.vim.FoundationUserAgent;
import com.vmware.vcqa.vim.HostSystem;
import com.vmware.vcqa.vim.IUserAgent;
import com.vmware.vcqa.vim.ManagedEntity;
import com.vmware.vcqa.vim.OvfManager;
import com.vmware.vcqa.vim.ResourcePool;
import com.vmware.vcqa.vim.Task;
import com.vmware.vcqa.vim.VirtualApp;
import com.vmware.vcqa.vim.VirtualMachine;
import com.vmware.vcqa.vim.alarm.AlarmManager;
import com.vmware.vcqa.vim.host.DiagnosticSystem;
import com.vmware.vcqa.vim.scheduler.ScheduledTask;
import com.vmware.vcqa.vim.scheduler.ScheduledTaskManager;


/**
 * Factory to create implementation objects for all the interfaces defined
 * in common code for test clients
 */
public class FactoryImpl
{
   private static final Logger log = LoggerFactory.getLogger(FactoryImpl.class);


   /**
    * Factory method to create IOperationThread implementation object
    *
    * @return IOperationThread implementation object
    *
    * @throws MethodFault, Exception
    */
   public static IOperationThread
   getIOperationThreadImpl(GenericConnectAnchor genericConnectAnchor,
                           int operationObject)
                           throws Exception
   {
      log.info("****Started the method FactoryImpl.getIOperationThreadImpl with operationObject = " + operationObject);
      IOperationThread operationThread = null;
      switch (operationObject) {
         case OperationThreadConstants.OPERATION_VM:
            operationThread =
               new VirtualMachine((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_HOST:
            operationThread =
               new HostSystem((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_TASK:
            operationThread =
               new Task((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_FOLDER:
            operationThread =
               new Folder((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_RESPOOL:
            operationThread =
               new ResourcePool((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_DIAGNOSTICSYSTEM:
            operationThread =
               new DiagnosticSystem((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_ALARM:
            operationThread =
               new AlarmManager((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_COMPUTERESOURCE:
            operationThread =
               new ClusterComputeResource((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_MANAGEDENTITY:
            operationThread =
               new ManagedEntity((ConnectAnchor)genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_PROPFILTER:
            operationThread =
               new PropertyCollector(genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_SCHEDULEDTASKMGR:
            operationThread =
               new ScheduledTaskManager((ConnectAnchor)
                                                genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_SCHEDULEDTASK:
            operationThread =
               new ScheduledTask((ConnectAnchor)
                                                genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_VAPP:
            log.info("****Found case for Operation VAPP");
            operationThread =
               new VirtualApp((ConnectAnchor)
                                                genericConnectAnchor);
            break;
         case OperationThreadConstants.OPERATION_OVF_MANAGER:
            operationThread =
               new OvfManager((ConnectAnchor)
                                                genericConnectAnchor);
            break;
         default:
            log.error("Unknown operation object");
            break;
      }
      return operationThread;
   }

   /**
    * Factory method to create ICIMWBEM implementation object.
    *
    * @return   ICIMWBEM    Returns ManagedCIMWsMan if CIMWSMAN JVM argument
    *                       is set to true, returns ManagedCIMWBEM otherwise.
    *
    * @throws MethodFault, Exception
    */
   public static ICIMWBEM
   getICimWbem() throws Exception
   {
      ICIMWBEM cimSDK;
      String javaArgWsMan = System.getProperty(CIMConstants.CIM_WSMAN);
      if ( (javaArgWsMan !=null) &&
               (javaArgWsMan.equalsIgnoreCase(TestConstants.BOOL_TRUE))){
         cimSDK = new ManagedCIMWsMan();
     }else{
         cimSDK = new ManagedCIMXML();
      }
      return cimSDK;
   }

   /**
    * Factory method to create ICIMListener implementation object.
    *
    * @return   ICIMListener    Instance of ManagedCIMListener
    *
    * @throws MethodFault, Exception
    */
   public static ICIMListener
   getICimListener()
                   throws Exception
   {
      ICIMListener cimListener = new ManagedCIMListener();

      return cimListener;
   }


   /**
    * Factory method to create ICIMSDK implementation object
    *
    * @param connectAnchor ConnectAnchor object
    *
    * @return ICIMSDK implementation object
    *
    * @throws MethodFault, Exception
    */
   public static ICIMSDK
   getICimSdk(ConnectAnchor connectAnchor)
              throws Exception
   {
      return new ManagedCIMSDK_ESX30(connectAnchor);
   }








   /**
    * Factory method to create IUserAgent implementation object
    *
    * @return IUserAgent Implementation object
    *
    * @throws MethodFault, Exception
    */
   public static IUserAgent
   getIUserAgentImpl()
   throws Exception
   {
      IUserAgent userAgentImpl = null;
      if(System.getProperty("UserAgentCompatAxis") == null){
         throw new Exception("The Axis version you are using is not good to run this test." +
                " Please sync your bora-winroot for latest axis.jar");
      }

      if(System.getProperty("USER-AGENT")!= null &&
            System.getProperty("USER-AGENT").length() >0 ){
         String userAgent = System.getProperty("USER-AGENT");
         if(userAgent.equalsIgnoreCase(TestConstants.BASE_USER_AGENT)){
            userAgentImpl = new BaseUserAgent();
         } else if(userAgent.equalsIgnoreCase(TestConstants.CORE_USER_AGENT)){
            userAgentImpl = new CoreUserAgent();
         } else if (userAgent.equalsIgnoreCase(TestConstants.FOUNDATION_USER_AGENT)){
            userAgentImpl = new FoundationUserAgent();
         } else{
            log.error("No user Agent set for the test, please check if you are" +
                    "providing a valid user agent as vm args USER-AGENT to the test");
            throw new Exception("vm argument 'USER-AGENT' is not found. Please run this test with" +
            " a valid userAgent by setting a system variable as 'USER_AGENT'");
         }
      }else {
         log.error("vm argument 'USER-AGENT' is not found. Please run this test with" +
            " a valid userAgent by setting a system variable as 'USER_AGENT' with values one of the follwing :");
         log.info(Arrays.asList(TestConstants.ALL_USER_AGENT_LIST).toString());
         throw new Exception("vm argument 'USER-AGENT' is not found. Please run this test with" +
            " a valid userAgent by setting a system variable as 'USER_AGENT'" );
      }
      return userAgentImpl;
   }


   //   Code commented as CSME feature is out of KL.next 08/14/09 - bpaul
   //
   //    /**
   //    * Factory method to create an IStoredCustomizationSpec implementation object
   //    *
   //    * @param connectAnchor ConnectAnchor object
   //    *
   //    * @return IStoredCustomizationSpec IStoredCustomizationSpec
   //    *
   //    * @throws MethodFault, Exception
   //    */
   //   public static IStoredCustomizationSpec getIStoredCustomizationSpecImpl(ConnectAnchor connectAnchor)
   //      throws MethodFault, Exception
   //   {
   //      IStoredCustomizationSpec iCustSpec = new ManagedStoredCustomizationSpec(
   //               connectAnchor);
   //      return iCustSpec;
   //   }



}
