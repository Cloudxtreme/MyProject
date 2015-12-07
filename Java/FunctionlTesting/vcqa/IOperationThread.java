/* ************************************************************************
 *
 * Copyright 2005 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */

package com.vmware.vcqa;

import java.util.Map;

/**
 * Common Interface defined for doing multithreaded operations on entity objects
 * like VM, Host. 
 */
public interface IOperationThread extends Runnable
{
   /**
    * Set Operation
    *
    * @param operation 
    */
   public void
   setOperation(int operation);
   
   /**
    * Get Operation
    *
    * @param operation 
    */
   public int
   getOperation();

   /**
    *Add argument required for the operation
    *
    *@param argKey   Argument Key
    *@param argValue Argument Value
    */
   public void
   addArgument(String argKey, 
               Object argValue);

   /**
    * Get Task exception generated when Operation fail
    *
    * @return Task exception
    */
   public Exception
   getOpException();

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
   getOpResult();

   /**
    * Get all the arguments
    * @return Arguments map object
    */
   public Map
   getArguments();
}
