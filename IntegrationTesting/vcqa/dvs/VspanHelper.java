package com.vmware.vcqa.vim.dvs;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Vector;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import com.vmware.vc.DVPortgroupConfigSpec;
import com.vmware.vc.DVPortgroupPolicy;
import com.vmware.vc.ManagedObjectReference;
import com.vmware.vc.VMwareDVSVspanConfigSpec;
import com.vmware.vc.VMwareVspanPort;
import com.vmware.vc.VMwareVspanSession;
import com.vmware.vcqa.util.Assert;
import com.vmware.vcqa.util.MultiMap;
import com.vmware.vcqa.util.TestUtil;

/**
 * All buildXXX static methods are used to construct different config objects.<br>
 * <br>
 * <br>
 * <br>
 *
 * @author kirane
 */
@SuppressWarnings("deprecation")
public class VspanHelper
{
   protected static final Logger log = LoggerFactory.getLogger(VspanHelper.class);

   /**
    * Create a DVPortgroupConfigSpec object using the given values.
    *
    * @param type Type of the port group.
    * @param numPort number of ports to create.
    * @param policy the policy to be used.
    * @param scope Scope.
    * @return DVPortgroupConfigSpec with given values set.
    */
   public static final DVPortgroupConfigSpec buildDVPortgroupCfg(String pgName,
                                                                 final String type,
                                                                 final int numPort,
                                                                 final DVPortgroupPolicy policy,
                                                                 final ManagedObjectReference scope)
   {
      final DVPortgroupConfigSpec cfg = new DVPortgroupConfigSpec();
      if (type != null) {
         pgName += type + "-";
      }
      cfg.setName(pgName);
      cfg.setType(type);
      cfg.setNumPorts(numPort);
      cfg.setPolicy(policy);
      cfg.getScope().clear();
      cfg.getScope().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(new ManagedObjectReference[] { scope }));
      return cfg;
   }
   
   /**
    * This method returns the union of all the port keys present in the 
    * vspan session.
    * 
    * @param vmwareVspanSessions
    * @return List<String>
    */
   public static List<String> getPortKeysFromVspanSession(VMwareVspanSession[] 
		                                                  vmwareVspanSessions)
   {
      List<String> portKeys = new ArrayList<String>();
      if(vmwareVspanSessions != null && vmwareVspanSessions.length >=1)
      {
    	  for(VMwareVspanSession vspanSession : vmwareVspanSessions)
          {
    		  VMwareVspanPort srcTransVspanPort = vspanSession.
    				  getSourcePortTransmitted();
    		  if(srcTransVspanPort != null){
    			  String[] srcPortTrans = com.vmware.vcqa.util.TestUtil.vectorToArray(srcTransVspanPort.getPortKey(), java.lang.String.class);
        		  if(srcPortTrans != null){
        			  for(String srcPortTransKey : srcPortTrans){
        				  if(!TestUtil.isPresent(srcPortTransKey, portKeys)){
        					  portKeys.add(srcPortTransKey);
        					  
        				  }
        			  }
        		  }	  
    		  }
    		  VMwareVspanPort srcRecVspanPort = vspanSession.
    				  getSourcePortReceived();
    		  if(srcRecVspanPort != null){
    			  String[] srcPortRec = com.vmware.vcqa.util.TestUtil.vectorToArray(srcRecVspanPort.getPortKey(), java.lang.String.class);
        		  if(srcPortRec != null){
        			  for(String srcPortRecKey : srcPortRec){
        				  if(!TestUtil.isPresent(srcPortRecKey, portKeys)){
        					  portKeys.add(srcPortRecKey);
        					  
        				  }
        			  }
        		  }	  
    		  }
    		  VMwareVspanPort destVspanPort = vspanSession.getDestinationPort();
    		  if(destVspanPort != null){
    			  String[] destPort = com.vmware.vcqa.util.TestUtil.vectorToArray(destVspanPort.getPortKey(), java.lang.String.class);
        		  if(destPort != null){
        			  for(String destPortKey : destPort){
        				  if(!TestUtil.isPresent(destPortKey, portKeys)){
        					  portKeys.add(destPortKey);  
        				  }
        			  }
        		  }	  
    		  }  
          } 
      }
      for(String pKey : portKeys)
      {
    	  log.info("The port key in the port key set : " + pKey);
      }
     
      return portKeys;
   }

   /**
    * Method to construct the VMwareVspanPort using given values.
    *
    * @param portKey key of DVPort to participate in VSPAN.
    * @param portgroupKey remove key of DVPortgroup to participate in VSPAN.
    * @param uplinkPortName name of uplink DVPorts to participate in VSPAN.
    * @return VMwareVspanPort constructed VSPAN port.
    */
   public static final VMwareVspanPort buildVspanPort(final String portKey,
                                                      final String portgroupKey,
                                                      final String uplinkPortName)
   {
      final String[] port = portKey == null ? null : new String[] { portKey };
      final String[] pg = portgroupKey == null ? null
               : new String[] { portgroupKey };
      final String[] up = uplinkPortName == null ? null
               : new String[] { uplinkPortName };
      return buildVspanPort(port, pg, up);
   }

   /**
    * Method to construct the VMwareVspanPort using given values.
    *
    * @param portKey keys of DVPorts to participate in VSPAN.
    * @param portgroupKey keys of DVPortgroup to participate in VSPAN.
    * @param uplinkPortName names of uplink DVPorts to participate in VSPAN.
    * @param wildcard Wildcard PortConnectee Type(s).
    * @return VMwareVspanPort constructed VSPAN port.
    */
   public static final VMwareVspanPort buildVspanPort(final String[] portKey,
                                                      final String[] portgroupKey,
                                                      final String[] uplinkPortName,
                                                      final String[] wildcard)
   {
      final VMwareVspanPort vspanPort = new VMwareVspanPort();
      vspanPort.getPortKey().clear();
      vspanPort.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(portKey));
      vspanPort.getUplinkPortName().clear();
      // vspanPort.setPortgroupKey(portgroupKey);
      vspanPort.getUplinkPortName().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(uplinkPortName));
      vspanPort.getWildcardPortConnecteeType().clear();
      vspanPort.getWildcardPortConnecteeType().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(wildcard));
      return vspanPort;
   }

   /**
    * Method to construct the VMwareVspanPort using given values.
    *
    * @param portKey keys of DVPorts to participate in VSPAN.
    * @param portgroupKey keys of DVPortgroup to participate in VSPAN.
    * @param uplinkPortName names of uplink DVPorts to participate in VSPAN.
    * @return VMwareVspanPort constructed VSPAN port.
    */
   public static final VMwareVspanPort buildVspanPort(final String[] portKey,
                                                      final String[] portgroupKey,
                                                      final String[] uplinkPortName)
   {
      return buildVspanPort(portKey, portgroupKey, uplinkPortName, null);
   }

   /**
    * Method to construct the VMwareDVSVspanConfigSpec from given values.
    *
    * @param vspanSession the VMwareVspanSession.
    * @param operation Operation.
    * @return VMwareDVSVspanConfigSpec.
    */
   public static final VMwareDVSVspanConfigSpec buildVspanCfg(final VMwareVspanSession vspanSession,
                                                              final String operation)
   {
      final VMwareDVSVspanConfigSpec vspanCfg = new VMwareDVSVspanConfigSpec();
      vspanCfg.setVspanSession(vspanSession);
      vspanCfg.setOperation(operation);
      return vspanCfg;
   }

   /**
    * Method to construct the VMwareVspanSession using given values. <br>
    * Setting key is not required, it will be set once session is created.<br>
    * Name and description is set to a the same value.<br>
    * enabled is false by default. <br>
    * encapsulating VLANID will be null by default.<br>
    *
    * @param name The name of the session.
    * @param sourcePortTransmitted source port transmitted.
    * @param sourcePortReceived source port received.
    * @param destinationPort destination port.
    * @return VMwareVspanSession.
    */
   public static final VMwareVspanSession buildVspanSession(final String name,
                                                            final VMwareVspanPort sourcePortTransmitted,
                                                            final VMwareVspanPort sourcePortReceived,
                                                            final VMwareVspanPort destinationPort)
   {
      final VMwareVspanSession vspanSession = new VMwareVspanSession();
      vspanSession.setName(name);
      vspanSession.setDescription(name);
      vspanSession.setSourcePortTransmitted(sourcePortTransmitted);
      vspanSession.setSourcePortReceived(sourcePortReceived);
      vspanSession.setDestinationPort(destinationPort);
      return vspanSession;
   }

   /**
    * Given with the valid values this method will generate 8 combinations
    *
    * @param template A VMwareVspanPort with all valid values.
    * @return VMwareVspanPort[]
    */
   public static VMwareVspanPort[] buildVspanPorts(final VMwareVspanPort template)
   {
      if (template != null) {
         return VspanHelper.buildVspanPorts(com.vmware.vcqa.util.TestUtil.vectorToArray(template.getPortKey(), java.lang.String.class),
                  com.vmware.vcqa.util.TestUtil.vectorToArray(template.getUplinkPortName(), java.lang.String.class));
      }
      log.error("Template null.");
      return null;
   }

   /**
    * Given with the valid values this method will generate 4 combinations.
    *
    * @param portKeys
    * @param portgroupKeys TODO remove this.
    * @return VMwareVspanPort[]
    */
   private static final VMwareVspanPort[] buildVspanPorts(final String[] portKeys,
                                                          final String[] portgroupKeys)
   {
      log.info("Building VMwareVspanPort: Port {}, Portgroup {}",
               Arrays.toString(portKeys), Arrays.toString(portgroupKeys));
      final List<VMwareVspanPort> ports = new ArrayList<VMwareVspanPort>();
      for (int i = 0; i < 2; i++) {
         final VMwareVspanPort vspanPort = new VMwareVspanPort();
         if ((i & 1) == 1) {
            vspanPort.getPortKey().clear();
            vspanPort.getPortKey().addAll(com.vmware.vcqa.util.TestUtil.arrayToVector(portKeys));
         }
         ports.add(vspanPort);
      }
      log.info("Built '{}' VMwareVspanPorts.", ports.size());
      return ports.toArray(new VMwareVspanPort[ports.size()]);
   }

   /**
    * Method to get the string representation of VMwareVspanPort.
    *
    * @param port The port.
    * @return String representation of VMwareVspanPort.
    */
   public static final String toString(final VMwareVspanPort port)
   {
      final StringBuffer sb = new StringBuffer();
      if (port != null) {
         final String[] portKeys = com.vmware.vcqa.util.TestUtil.vectorToArray(port.getPortKey(), java.lang.String.class);
         // final String[] portgroupKeys = port.getPortgroupKey();
         final String[] uplinkPortNames = com.vmware.vcqa.util.TestUtil.vectorToArray(port.getUplinkPortName(), java.lang.String.class);
         final String[] wildcard = com.vmware.vcqa.util.TestUtil.vectorToArray(port.getWildcardPortConnecteeType(), java.lang.String.class);
         sb.append("Port:").append(Arrays.toString(portKeys));
         // sb.append(" PG:").append(Arrays.toString(portgroupKeys));
         sb.append(" Uplnk:").append(Arrays.toString(uplinkPortNames));
         sb.append(" WildCard:").append(Arrays.toString(wildcard));
      }
      return sb.toString();
   }

   public static final String toString(final VMwareVspanSession aSession)
   {
      final StringBuffer sb = new StringBuffer();
      sb.append("Name{" + aSession.getName());
      sb.append("}, Tx{");
      sb.append(toString(aSession.getSourcePortTransmitted()));
      sb.append("}, Rx{");
      sb.append(toString(aSession.getSourcePortReceived()));
      sb.append("}, Dst{");
      sb.append(toString(aSession.getDestinationPort()));
      sb.append("}, Enabled{");
      sb.append(aSession.isEnabled());
      sb.append("}, VlanId{");
      sb.append(aSession.getEncapsulationVlanId());
      sb.append("}, NormalTraffic{");
      sb.append(aSession.isNormalTrafficAllowed());
      sb.append("}, PacketLength{");
      sb.append(aSession.getMirroredPacketLength());
      sb.append("}");
      return sb.toString();
   }

   /**
    * From the MultiMap of PGkey -> Ports; Pop a port of given Portgroup key by
    * removing it.<br>
    */
   public static final String popPort(final MultiMap<String, String> pgs,
                                      final String pgName)
   {
      List<String> ports = pgs.get(pgName);
      Assert.assertNotEmpty(ports, "No ports in given DVPortgroup: " + pgName);
      final String port = ports.remove(0);// Use it by removing.
      log.info("Popping port {} from DVPortgroup{} ", port, pgName);
      if (ports.isEmpty()) {
         pgs.remove(pgName);// remove the PG from the Map.
      }
      return port;
   }

   /**
    * From the MultiMap of PGkey -> Ports; pop a port key by removing it.<br>
    */
   public static final String popPort(final MultiMap<String, String> pgs)
   {
      final Collection<String> keys = pgs.keySet();
      Assert.assertNotEmpty(keys, "No DVPortgroups were given!");
      final String pgName = keys.iterator().next();
      return popPort(pgs, pgName);
   }

   /**
    * From the MultiMap of PGkey -> Ports; pop a DVPortgroup by removing it.<br>
    */
   public static final Map<String, List<String>> popPortgroup(final MultiMap<String, String> pgs)
   {
      final Map<String, List<String>> pg = new HashMap<String, List<String>>();
      final Collection<String> keys = pgs.keySet();
      Assert.assertNotEmpty(keys, "No DVPortgroups were given!");
      final String pgName = keys.iterator().next();
      pg.put(pgName, pgs.remove(pgName));
      return pg;
   }

   /**
    * Filtering the default session is essential as we are not going to use the
    * default session for comparing / editing the session in VSPAN tests.
    *
    * @param sessions VSPAN sessions to filter.
    * @return after removing the default Promiscuous_Vspan_Session.
    */
   public static final VMwareVspanSession[] filterSession(final VMwareVspanSession[] sessions)
   {
      // FIXME kiri remove this method as default session is removed from FVMODL.
      return sessions;
   }
   /**
	 * Create a new raw session
	 *
	 * @param sessionType
	 *            one of five session types used by PortMirror
	 * @return an new VMwareDVSVspanConfigSpec object with default value.
	 */
	public static VMwareDVSVspanConfigSpec getRawVMwareDVSVspanConfigSpec(
			String sessionType) {
		VMwareDVSVspanConfigSpec m_newSpecs = new VMwareDVSVspanConfigSpec();
		VMwareVspanSession vspanSession = new VMwareVspanSession();
		VMwareVspanPort sourceTx = new VMwareVspanPort();
		VMwareVspanPort sourceRx = new VMwareVspanPort();
		VMwareVspanPort destinationPort = new VMwareVspanPort();
		vspanSession.setSourcePortReceived(sourceRx);
		vspanSession.setSourcePortTransmitted(sourceTx);
		vspanSession.setDestinationPort(destinationPort);
		m_newSpecs.setVspanSession(vspanSession);
		if (sessionType.equals("remoteMirrorSource")) {
			/*
			 * For remoteMirrorSoure type, encapsulationVlanid is needed.
			 */
			vspanSession.setEncapsulationVlanId(1);
		}
		if (sessionType.equals("remoteMirrorDest")) {
			/*
			 * For remoteMirrorDest type, the srctx filed must be null.
			 */
			vspanSession.setSourcePortTransmitted(null);
		}
		return m_newSpecs;
	}
	/**
	 * Set the ignored fields for different session type when compared the two
	 * objects.
	 *
	 * @param sessionType
	 * @return Vector which contained the ignored field name.
	 */
	public static Vector<String> getIgnoredField(final String sessionType) {
		Vector<String> r = new Vector<String>();
		r.add("VMwareVspanSession.Description");
		if (sessionType.equals("dvPortMirror")) {
			r.add("VMwareVspanSession.encapsulationVlanId");
			r.add("VMwareVspanSession.StripOriginalVlan");
		} else if (sessionType.equals("remoteMirrorDest")) {
			r.add("VMwareVspanSession.SourcePortTransmitted");
			r.add("VMwareVspanSession.StripOriginalVlan");
		} else if (sessionType.equals("encapsulatedRemoteMirrorSource")) {
			// ...
		} else if (sessionType.equals("remoteMirrorSource")) {
			// ...
		} else if (sessionType.equals("mixedDestMirror")) {
			// ...
		} else {
			Assert.assertTrue(false, "Unsuppport session type!");
		}
		return r;
	}
}
