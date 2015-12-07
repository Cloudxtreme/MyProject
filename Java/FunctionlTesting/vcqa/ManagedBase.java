/* ************************************************************************
 *
 * Copyright 2007-2011 VMware, Inc. All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.InternalVimPortType;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vcqa.resourcelocker.LockHelper;
import com.vmware.vcqa.resourcelocker.LockerException;
import com.vmware.vcqa.resourcelocker.ResourceLocker;

/**
 * ManagedBase is a base class for all Managed classes. It encapsulates the
 * common methods, constants for all Managed classes.
 */
public abstract class ManagedBase implements IOperationThread
{
   private GenericConnectAnchor genericAnchor = null;
   private long opStartTime    = 0;
   private long opMiddleTime   = 0;
   private long opCompleteTime = 0;

   private int operation = 0;
   private Map<String,Object> arguments = null;
   private Exception opException = null;
   private Object opResult = null;

   private static final Logger log = LoggerFactory.getLogger(ManagedBase.class);

   /**
    * Constructor
    *
    * @param connectAnchor Reference to the ConnectAnchor object
    */
   protected
   ManagedBase (GenericConnectAnchor connectAnchor)
   {
      this.genericAnchor = connectAnchor;
      this.arguments = new HashMap<String,Object>();

   }

   /**
    * Dummy implementation of Runnable.run() in ManagedBase to enable all the
    * Managed classes to implement their own run methods.
    */
   public void
   run()
   {

   }

   /**
    * Add argument required for the operation
    *
    * @param argKey Argument Key
    * @param argVal Argument Value
    */
   public void
   addArgument(String argKey, Object argVal)
   {
      this.arguments.put(argKey, argVal);
   }

   /**
    * Get all the arguments
    *
    * @return Arguments map object
    */
   public Map
   getArguments()
   {
      return this.arguments;
   }

   /**
    * Method to create a ConnectAnchor, given a host name and port number
    *
    * @param hostName The name of the host
    * @param port     Port number
    *
    * @return Reference to the ConnectAnchor object
    *
    * @throws Exception
    */
   protected ConnectAnchor
   createConnectAnchor(String hostName,
                    int port)
                    throws Exception
   {
      ConnectAnchor connectAnchor = new ConnectAnchor(hostName, port);
      return connectAnchor;
   }

   /**
    * Get ConnectAnchor
    *
    * @return ConnectAnchor object
    */
   protected ConnectAnchor
   getConnectAnchor()
   {
      return (ConnectAnchor)this.genericAnchor;
   }

   /**
    * Get GenericConnectAnchor
    *
    * @return GenericConnectAnchor object
    */
   protected GenericConnectAnchor
   getGenericConnectAnchor()
   {
      return this.genericAnchor;
   }

   /**
    * Set Operation type
    *
    * @param operation Operation type
    */
   public void
   setOperation(int operation)
   {
      this.operation = operation;
   }

   /**
    * Get Operation type
    *
    * @return operation Operation type
    */
   public int
   getOperation()
   {
      return this.operation;
   }

   /**
    * Get Task fault generated when Operation fail
    *
    * @return Task MethodFault exception generated
    */
   public Exception
   getOpException()
   {
      return this.opException;
   }

   /**
    * Set Task exception generated when Operation fail
    *
    * @param exception Task Exception
    */
   protected void
   setOpException(Exception exception)
   {
      this.opException = exception;
   }

   /**
    * Get Operation Result Object
    *
    * @return Operatation result Object. Returned primitive datatype from the
    *         operation will be wrapped as Object and user have to get
    *         primitive data from the wrapped object.
    *
    *         null, on unsuccessful  Operation
    */
   public Object
   getOpResult()
   {
      return this.opResult;
   }

   /**
    * Set Operation Result Object
    *
    * @param result Operatation result Object
    */
   protected void
   setOpResult(Object result)
   {
      this.opResult = result;
   }

   /**
    * Method to get the Init time of the Operation
    *
    * @return opStartTime The time in millis at the start of operation
    */
   public long
   getOpStartTime()
   {
      return opStartTime;
   }

   /**
    * Method to get the time in between the two operations
    *
    * @return opMiddleTime The time in millis in between two operations
    */
   public long
   getOpMiddleTime()
   {
      return opMiddleTime;
   }

   /**
    * Method to get the Completion time of the operation
    *
    * @return opCompleteTime The time in millis at the end of operation
    */
   public long
   getOpCompleteTime()
   {
      return opCompleteTime;
   }

   /**
    * Get BasePortType implementation object
    *
    * @return Constrcuted host binding object
    */
   protected InternalVimPortType
   getBasePortType()
   {
      return (InternalVimPortType)
         genericAnchor.getPortType();
   }


   /**
    * Get InternalVimPortType implementation object
    *
    * @return Constrcuted host vim binding object
    */
   public InternalVimPortType
   getPortType()
   {
	   return (InternalVimPortType)genericAnchor.getPortType();
//      return (InternalVimService)genericAnchor.getService();
   }

   /**
    * Method to set the initial time
    */
   protected void
   setOpStartTime()
   {
      Calendar cal  = Calendar.getInstance();
      opStartTime = cal.getTimeInMillis();
   }

   /**
    * Method to set the time between the operations
    */
   protected void
   setOpMiddleTime()
   {
      Calendar cal = Calendar.getInstance();
      opMiddleTime = cal.getTimeInMillis();
   }

   /**
    * Method to set the time after the completion of the operation
    */
   protected void
   setOpCompleteTime()
   {
      Calendar cal = Calendar.getInstance();
      opCompleteTime = cal.getTimeInMillis();
      if (System.getProperty("GET_LATENCY_TIME") != null
               && System.getProperty("GET_LATENCY_TIME").equalsIgnoreCase(
                        "true")) {
         StackTraceElement[] elements = Thread.currentThread().getStackTrace();
         if (elements != null && elements.length > 1) {
            for (int i = 1; i < elements.length; i++) {
               if (elements[i] != null) {
                  if (!elements[i].getMethodName().equalsIgnoreCase(
                           "setOpCompleteTime")) {
                     printVcOpsPerformanceStats(elements[i].getMethodName());
                     break;
                  }
               }
            }
         }
      }
   }

   /**
    * Initialize instance variables
    */
   protected void
   initialize()
   {
      opStartTime    = 0;
      opMiddleTime   = 0;
      opCompleteTime = 0;

      opException = null;
      opResult = null;
   }

   /**
    * Method to print relevant performance related statistics of an operation
    *
    * @param operation pertains to operation whose performance statistics is to
    *                  be printed
    */
   public void
   printVcOpsPerformanceStats(String operation)
   {
      SimpleDateFormat dateFormat =
         new SimpleDateFormat("yyyy-MM-dd HH:mm:ss.SSS");
      Date startTime = new Date(getOpStartTime());
      Date completeTime = new Date(getOpCompleteTime());
      log.info("<operation>" + operation + "</operation>\n" +
      "<opThreadId>" + Thread.currentThread().getId() + "</opThreadId>\n" +
      "<opStartTime>" + dateFormat.format(startTime) + "</opStartTime>\n<opCompletionTime>"
      + dateFormat.format(completeTime) + "</opCompletionTime>\n<opLatencyTime>" +
      (getOpCompleteTime() - getOpStartTime()) + "</opLatencyTime>");
   }
   /**
    * sharedLock method locks a managedObjectReference using sharedlock
    *
    * @param morObject
    * @throws LockerException
    */
   public void sharedLock(ManagedObjectReference morObject)
      throws LockerException
   {
      ResourceLocker.singleton().sharedLock(morObject);
   }

   /**
    * exclusiveLock method locks a managedObjectReference using exclusivelock
    */
   public void exclusiveLock(ManagedObjectReference morObject)
      throws LockerException
   {
      ResourceLocker.singleton().exclusiveLock(morObject);
   }

   /**
    * sharedLock method locks array of managedObjectReferences using sharedlock
    *
    * @param morObjects
    * @throws LockerException
    */
   public void sharedLock(ManagedObjectReference[] morObjects)
      throws LockerException
   {
      LockHelper.singleton().sharedLock(morObjects);
   }

   /**
    * exclusiveLock method locks array of managedObjectReferences using
    * exclusiveLock
    *
    * @param morObjects
    * @throws LockerException
    */
   public void exclusiveLock(ManagedObjectReference[] morObjects)
      throws LockerException
   {
      LockHelper.singleton().exclusiveLock(morObjects);
   }

   /**
    * SharedLock method locks a managedObjectReference and its children based on
    * the lockChild flag.
    *
    * @param morObject Object to be shareLocked
    * @param lockChild true/false flag to lock children
    *
    */
   public void sharedLock(ManagedObjectReference morObject,
                          boolean lockChildren)
      throws LockerException, Exception
   {
      LockHelper.singleton().sharedLock(morObject, lockChildren, this.getConnectAnchor());

   }

   /**
    * exclusiveLock method locks a managedObjectReference and its children based
    * on the lockChild flag.
    *
    * @param morObject Object to be shareLocked
    * @param lockChild true/false flag to lock children
    *
    */
   public void exclusiveLock(ManagedObjectReference morObject,
                             boolean lockChildren)
      throws LockerException, Exception
   {
      LockHelper.singleton().exclusiveLock(morObject, lockChildren,
               this.getConnectAnchor());
   }


   /**
    * isParallelExecutionEnabled checks whether parallel execution is enabled.
    *
    * @return
    */
   public boolean isParallelExecutionEnabled()
   {
      return LockHelper.singleton().isParallelExecutionEnabled();
   }

}
