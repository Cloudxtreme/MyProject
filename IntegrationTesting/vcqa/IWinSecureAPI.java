/*
 * ************************************************************************
 *
 * Copyright 2009 VMware, Inc.  All rights reserved. -- VMware Confidential
 *
 * ************************************************************************
 */
package com.vmware.vcqa;

import com.sun.jna.Native;
import com.sun.jna.ptr.LongByReference;
import com.sun.jna.win32.StdCallLibrary;
import com.vmware.vcqa.jna.sspi.WinSecurityBufferDescription;
import com.vmware.vcqa.jna.sspi.WinSecurityHandle;
import com.vmware.vcqa.jna.sspi.WinSecurityInteger;

public interface IWinSecureAPI extends StdCallLibrary
{
   IWinSecureAPI INSTANCE = (IWinSecureAPI) Native.loadLibrary(
            "secur32", IWinSecureAPI.class);
   /**
    * variable names in this class are intentionally kept in CAPS, because this
    * way it is easy to refer microsoft documentation (MSDN)
    */
   public final int ISC_REQ_CONFIDENTIALITY = 0x00000010;
   public final int ISC_REQ_CONNECTION = 0x00000800;
   public final int ISC_REQ_REPLAY_DETECT = 0x00000004;
   public final int ISC_REQ_SEQUENCE_DETECT = 0x00000008;

   public final int MAX_TOKEN_SIZE = 12288;
   public final int SEC_E_OK = 0;
   public final int SEC_I_CONTINUE_NEEDED = 0x90312;

   public final int SECPKG_CRED_OUTBOUND = 2;
   public final int SECURITY_NATIVE_DREP = 0x10;

   public final int STANDARD_CONTEXT_ATTRIBUTES = ISC_REQ_CONFIDENTIALITY
            | ISC_REQ_REPLAY_DETECT | ISC_REQ_SEQUENCE_DETECT
            | ISC_REQ_CONNECTION;

   public final int TOKEN_QUERY = 0x00008;
   /**
    * Acquires a handle to preexisting credentials of a security principal. It 
    * is a native method and maps to <B>AcquireCredentialsHandleA</B> method in
    * secur32 library.
    * This handle is required by the InitializeSecurityContext
    * @param principal - userName
    * @param packageName - security package name used, "NTLM" in our case 
    * @param credentialUse - a flag allowing a local client credential to 
    *  prepare an outgoing token
    * @param authenticationID - A locally unique identifier (LUID) that 
    *  identifies the user, it can be passed as 0 (as in our case)
    * @param authData - Information about package specific data can be 0
    * @param getKeyFn - Not in use currently can be set to 0
    * @param getKeyArgument - Not in use currently can be set to 0
    * @param credential - A reference to credential handle structure to
    *  receive credential handle from server  
    * @param expiry -  Ref to a structure that receives the time at which 
    *  the returned credentials expire.
    * @return an int value indicating status of the request, please refer msdn
    *  documentation for further details
    *  
    */
   public int AcquireCredentialsHandleA(
                   String principal, 
                   String packageName, 
                   int credentialUse,
                   int authenticationID,
                   int authData,
                   int getKeyFn,
                   int getKeyArgument,
                   WinSecurityHandle credential, 
                   WinSecurityInteger expiry);
   /**
    * Initiates the client side, outbound security context from a credential 
    * handle. The function is used to build a security context between the 
    * client application and a remote peer. InitializeSecurityContext 
    * returns a token that the client must pass to the remote peer.
    * It is a native method and maps to <B>InitializeSecurityContextA</B> method 
    * in secur32 library.
    * @param credential - A handle to the credentials returned by 
    *  AcquireCredentialsHandle (NTLM). This handle is used to build the 
    *  security context.
    * @param context - A pointer to a CtxtHandle structure. On the first call 
    *  to InitializeSecurityContext (NTLM), this pointer is NULL. On the second 
    *  call, this parameter is a pointer to the handle to the partially formed 
    *  context returned in the phNewContext parameter by the first call.
    * @param targetName - Username
    * @param contextReq - Bit flags that indicate requests for the context.
    * @param reserved1 - Reserved parameter, set to 0
    * @param targetDataRep - The data representation, such as byte ordering, 
    *  on the target
    * @param input - A pointer to a SecBufferDesc structure that contains 
    *  pointers to the buffers supplied as input to the package. The pointer 
    *  must be NULL on the first call to the function. On subsequent calls to 
    *  the function, it is a pointer to a buffer allocated with enough memory 
    *  to hold the token returned by the remote peer.
    * @param reserved2 - Reserved parameter, set to 0
    * @param newContext - A pointer to a CtxtHandle structure. On the first 
    *  call to InitializeSecurityContext (NTLM), this pointer receives the new 
    *  context handle. On the second call, phNewContext can be the same as the 
    *  handle specified in the phContext parameter.
    * @param output A pointer to a SecBufferDesc structure that contains 
    * pointers to the SecBuffer structure that receives the output data.
    * @param contextAttr - A pointer to a variable to receive a set of bit 
    *  flags that indicate the attributes of the established context
    * @param expiry - A Ref to a TimeStamp structure that receives the 
    *  expiration time of the context
    * @return an int value indicating status of the request, please refer msdn
    *  documentation for further details
    */
   public int InitializeSecurityContextA(
                   WinSecurityHandle credential,
                   WinSecurityHandle context, 
                   String targetName,
                   int contextReq,
                   int reserved1,
                   int targetDataRep,
                   WinSecurityBufferDescription input,
                   int reserved2,
                   WinSecurityHandle newContext,
                   WinSecurityBufferDescription output,
                   LongByReference contextAttr,
                   WinSecurityInteger expiry);

}
