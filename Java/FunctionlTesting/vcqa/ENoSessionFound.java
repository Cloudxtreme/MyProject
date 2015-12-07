/* ************************************************************************
*
* Copyright 2005 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa;


/**
 * ENoSessionFound Exception is thrown when a session to the agent
 * could not be found in the cache
 */

public class ENoSessionFound extends Exception 
{
	public ENoSessionFound(String message,Throwable cause) 
	{
		super(message,cause);
	}
	public ENoSessionFound(String message) 
	{
		super(message);
	}
	public ENoSessionFound(Throwable cause) 
	{
		super(cause);
	}
}
