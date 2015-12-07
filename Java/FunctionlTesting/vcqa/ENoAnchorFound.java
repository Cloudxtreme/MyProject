/* ************************************************************************
*
* Copyright 2005 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa;


/**
 * ENoAnchorFound Exception is thrown when a ConnectAnchor to the agent
 * could not be found in the cache
 */

public class ENoAnchorFound extends Exception 
{
	public ENoAnchorFound(String message,Throwable cause) 
	{
		super(message,cause);
	}
	public ENoAnchorFound(String message) 
	{
		super(message);
	}
	public ENoAnchorFound(Throwable cause) 
	{
		super(cause);
	}
}
