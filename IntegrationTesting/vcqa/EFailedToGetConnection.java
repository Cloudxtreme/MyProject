/* ************************************************************************
*
* Copyright 2005 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa;


/**
 * EFailedToGetConnection Exception is thrown when a connection to the agent
 * could not be established
 */

public class EFailedToGetConnection extends Exception 
{
	public EFailedToGetConnection(String message,Throwable cause) 
	{
		super(message,cause);
	}
	public EFailedToGetConnection(String message) 
	{
		super(message);
	}
	public EFailedToGetConnection(Throwable cause) 
	{
		super(cause);
	}
}