/* ************************************************************************
*
* Copyright 2005 VMware, Inc.  All rights reserved. -- VMware Confidential
*
* ************************************************************************
*/
package com.vmware.vcqa;
import java.net.SocketException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Date;
import java.util.Enumeration;
import java.util.Hashtable;
import java.util.Iterator;
import java.util.Vector;
import java.util.concurrent.locks.ReentrantReadWriteLock;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.UserSession;
import com.vmware.vcqa.vim.SessionManager;

/**
 * ConnectAnchorCache maintains cache of Connect Anchors and session Handles This
 * class is designed to be used in staf services where through a service
 * commands can be used to perform operations on various VC instances and ESX
 * Servers
 */
public class ConnectAnchorCache
{
   private static final Logger log = LoggerFactory.getLogger(ConnectAnchorCache.class); 
   /*Anchor class will be stored in the Hashtable, will encapsulate
   all the information necessary to re-create the session if the 
   session has inactivity for more than 26 minutes. Default session
   timeout is 30 minutes. */
   
   protected static class Anchor 
   {
      private ConnectAnchor _anchor;
      private ManagedObjectReference _authMor;
      private ManagedObjectReference _sessionMor;
      private UserSession _loginSession;
      private Date lastUsed;
      private int port;
      private String user;
      private String passwd;
      private String keyPath;
      private ReentrantReadWriteLock rwl;
      
      /**
       * constructor
       * 
       * @param anchor
       * @param authMor
       * @param sessionMor
       * @param loginSession
       * @param sessionPort
       * @param sessionUser
       * @param sessionPassword
       * @param keyStorePath
       */
      public Anchor(ConnectAnchor anchor,
                    ManagedObjectReference authMor,
                    ManagedObjectReference sessionMor,
                    UserSession loginSession,
                    int sessionPort,
                    String sessionUser,
                    String sessionPassword,
                    String keyStorePath)
      {
         rwl = new ReentrantReadWriteLock();
         _anchor = anchor;
         _authMor = authMor;
         _sessionMor = sessionMor;
         _loginSession = loginSession;
         lastUsed = new Date();
         port = sessionPort;
         user = sessionUser;
         passwd = sessionPassword;
         keyPath = keyStorePath;
      }
      
      /**
       * method checks the last access time and re-creates the session if 
       * necessary
       * 
       * @return
       * @throws Exception
       */
      public void 
      reConnectIfStale()
                throws Exception
      {
         try {
            rwl.writeLock().lock();
            Date currTime = new Date();
            long diffInTime = currTime.getTime() - lastUsed.getTime();
            if (diffInTime > TestConstants.STAF_SERVICE_VIM_SESSION_TIMEOUT) {
               String host = _anchor.getHostName();
               /* this is just doing best effort here, even if the logout fails
               we will continue with the new session creation */
               try {
            	   _anchor.getPortType().logout(_authMor);
               } catch (Exception eExcep) {
//                  NoPermission e = com.vmware.vcqa.util.TestUtil.getFault(eExcep);
                  // do not have to do anything as it is already logged out
                  ;
               }
               connectionHandles.remove(host);
               Object[] objList = connect(host,port,user,passwd,keyPath);
               _anchor = (ConnectAnchor) objList[0];
               _authMor = (ManagedObjectReference) objList[1];
               _sessionMor = (ManagedObjectReference) objList[2];
               _loginSession = (UserSession) objList[3];
               connectionHandles.put(host, new Anchor(_anchor, _authMor, 
                     _sessionMor, _loginSession, port, user, passwd, keyPath));
             }
         } finally {
            lastUsed = new Date();
            rwl.writeLock().unlock();
         }
      }
      
      /**
       * returns ConnectAnchor object for the session.
       * Before returning checks for staleness and re-creates the session if
       * necessary
       *   
       * @return
       * @throws Exception
       */
      public ConnectAnchor
      getAnchor()
                throws Exception
      {
         reConnectIfStale();
         return _anchor;
      }
      
      /**
       * logs out from the session
       * @throws Exception
       */
      public void
      logout()
             throws Exception
      {
         try {
        	 _anchor.getPortType().logout(_authMor);
         } catch (Exception eExcep) {
//            NoPermission e = com.vmware.vcqa.util.TestUtil.getFault(eExcep);
            // do not have to do anything as it is already logged out
            ;
         }
      }
   }
   
   private static Hashtable<String, Anchor> connectionHandles = 
      new Hashtable<String, Anchor>();

   /**
    * handleConnection establishes connection to the Agent and pushes the
    * connection handle to a Hashtable with the host name as the key. Skips
    * creating ConnectAnchor in case it is already cached or the session is not
    * stale
    * 
    * @param host - Host name
    * @param port - port number
    * @param userId - user for the session
    * @param password - password of the user
    * @param reconnect - forces connection 
    * @param keyStorePath if specified an SSL session is attempted,
    *                      if null non-SSL session is attempted
    * 
    * @return key (host name) of the Anchor
    * 
    * @throws Exception
    */
   public static String 
   handleConnection(String host,
                    int port,
                    String userId,
                    String password,
                    boolean reconnect,
                    String keyStorePath) 
                    throws Exception
   {
      if (reconnect || !connectionHandles.containsKey(host)) {
         if (connectionHandles.containsKey(host)) {
            removeAnchor(host);
         }
         Object[] objList = connect(host, port, userId, password,
                                               keyStorePath);
         connectionHandles.put(host, new Anchor((ConnectAnchor) objList[0],
                  (ManagedObjectReference) objList[1],
                  (ManagedObjectReference) objList[2],
                  (UserSession) objList[3], port, userId, password,
                  keyStorePath));
      } else {
         ((Anchor) connectionHandles.get(host)).reConnectIfStale();
      }
      return host;
   }
   
   /**
    * method creates the ConnectAnchor object and authenticates the session
    * 
    * @param host
    * @param port
    * @param userId
    * @param password
    * @param keyStorePath
    * @return
    * @throws Exception
    */
   public static Object[]
   connect(String host,
           int port,
           String userId,
           String password,
           String keyStorePath)
           throws Exception
   {
      ConnectAnchor connectAnchor = null;
      if (keyStorePath == null) {
         connectAnchor = new ConnectAnchor(host, port);
      } else {
         connectAnchor = new ConnectAnchor(host, port, keyStorePath);
      }
      SessionManager sessionManager = new SessionManager(connectAnchor);
      ManagedObjectReference authenticationMor = sessionManager
            .getSessionManager();
      UserSession loginSession =new SessionManager(connectAnchor).login(authenticationMor,
            userId, password, null);
      ManagedObjectReference mor = connectAnchor.getSC().getSessionManager();
      Object[] objList = new Object[4];
      objList[0] = connectAnchor;
      objList[1] = authenticationMor;
      objList[2] = mor;
      objList[3] = loginSession;
      return objList;
   }

   
   /**
    * returns ConnectAnchor object for the key (host name)
    * 
    * @param host
    * @return
    * @throws ENoAnchorFound
    * @throws Exception
    */
   public static ConnectAnchor 
   getAnchor(String host) 
             throws Exception
   {
      if (connectionHandles.containsKey(host)) {
         return (ConnectAnchor) ((Anchor) connectionHandles.get(host))
                  .getAnchor();
      } else {
         throw new ENoAnchorFound("No anchor found for agent:" + host);
      }
   }
   
   /**
    * Returns All ConnectAnchors in the Cache
    *
    * @return vector of ConnectAnchors in the cache
    * @throws ENoAnchorFound
    * @throws Exception
    */
   public static Vector <ConnectAnchor>
   getAnchors()
              throws Exception
   {
      Vector <ConnectAnchor> connectAnchors = null;
      if (!connectionHandles.isEmpty()) {
         connectAnchors = new Vector <ConnectAnchor> ();
         Collection <Anchor> anchorValues =  new ArrayList<Anchor>(
               connectionHandles.values());
         Iterator<Anchor> itr = anchorValues.iterator();
         while (itr.hasNext()) {
            Anchor anchor = (Anchor)itr.next();
            connectAnchors.add(anchor.getAnchor());
         }
      }
      return connectAnchors;
   }

   /**
    * returns Login id for the session
    * 
    * @param anchor
    * @return user
    * @throws ENoAnchorFound
    * @throws Exception
    */
   public static String
   getAnchorLogin(ConnectAnchor anchor)
                  throws Exception
   {	  
      String anchorName = anchor.getHostName();
      if (connectionHandles.containsKey(anchorName)) {
         return ((Anchor) connectionHandles.get(anchorName)).user;
      } else {
         throw new ENoAnchorFound("Login could not be attained. " +
            "No anchor found for agent:" + anchorName);
      }
   }
    
   /**
    * returns Login password for the session
    *   
    * @param anchor
    * @return passwd
    * @throws ENoAnchorFound
    * @throws Exception
    */
   public static String
   getAnchorPassword(ConnectAnchor anchor)
                     throws Exception
   {	   
      String anchorName = anchor.getHostName();
      if (connectionHandles.containsKey(anchorName)) {    	  
         return ((Anchor) connectionHandles.get(anchorName)).passwd;         
      } else {
         throw new ENoAnchorFound("Password could not be attained." +
            "No anchor found for agent:" + anchorName);
      }
   }   
   
   /**
    * logs out the session and removes the ConnectAnchor object for the 
    * key (host name)
    * 
    * @param host
    * @return
    * @throws ENoAnchorFound
    * @throws Exception
    */
   public static void 
   removeAnchor(String host) 
                throws Exception
   {
      if (connectionHandles.containsKey(host)) {
         try {
            ((Anchor) connectionHandles.get(host)).logout();
         } catch (SocketException e) {
            //That means vpxd is crashed, thats why this cleanup is being done
            ;
         }
         connectionHandles.remove(host);
      } else {
         throw new ENoAnchorFound("No anchor found for agent:" + host);
      }
   }
   
   
   /**
    * logs out the session and removes the ConnectAnchor object for the 
    * key (host name)
    * 
    * @param host
    * @param checkAnchorExistence
    * @return
    * @throws ENoAnchorFound
    * @throws Exception
    */
   public static void 
   removeAnchor(String host, 
                boolean checkAnchorExistence) 
                throws Exception
   {
      if (checkAnchorExistence) {
         removeAnchor(host);
      } else {
         connectionHandles.remove(host);
      }
   }
   
   
   public static void 
   removeAllAnchors() 
                    throws Exception
   {
      Enumeration<String> en = connectionHandles.keys();
      while (en.hasMoreElements()) {
         removeAnchor((String)en.nextElement());
      }
   }
}
