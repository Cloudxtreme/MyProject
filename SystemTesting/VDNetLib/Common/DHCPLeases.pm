########################################################################
# Copyright (C) 2010 VMWare, Inc.
# # All Rights Reserved
########################################################################
package VDNetLib::Common::DHCPLeases;

#
# VDNetLib::Common::DHCPLeases Module
#
# Attributes:
# 1. dhcp (This stores different dhcpServer as its values)
#
# Methods:
# 1. new() - constructor
# 2. GetPage()
# 3. ParseLeases()
# 4. GetLeases()
# 5. GetDHCPServer()
#

use strict;
use warnings;
use LWP::UserAgent;
use VDNetLib::Common::VDErrorno qw(VDSetLastError VDGetLastError FAILURE SUCCESS);


########################################################################
#
# new --
#     Entry to VDNetLib::Common::DHCPLeases. Creates an instance of
#     VDNetLib::Common::DHCPLeases object.
#
# Input:
#     None
#
# Results:
#      A VDNetLib::Common::DHCPLeases object
#
# Side effects:
#      None
#
########################################################################

sub new
{
    my $class = shift;      # IN: Invoking instance or class name.

    my $self = {
    };

    bless $self => $class;
    return $self;
}


########################################################################
#
# GetPage --
#     Returns the text content of the given page.
#     Uses LWP::UserAgent package to read content from the given
#     html webpage. The html page expected in this package is
#     dhcp server's lease page.
#
# Input:
#     page: URL to html page from which contents have to be returned
#           Example, "http://10.17.131.12/dhcpd.leases"
#
# Results:
#     text content from the given page if success, undef otherwise
#
# Side effects:
#      None
#
########################################################################

sub GetPage
{
  my $self = shift;
  my $page = shift;
  my $ua = LWP::UserAgent->new();
  my $resp = $ua->get($page);
  if ($resp->is_success) {
    return $resp->content;
  } else {
    return undef;
  }
}


########################################################################
#
# ParseLeases --
#     This method parses the given the lease information (text content)
#     obtained from  VDNetLib::Common::DHCPLeases::GetPage() method.
#     It returns a hash with all different mac address entries in the
#     given page as keys and corresponding ip address as their values.
#
# Input:
#     1. Text content from dhcpserver lease page (for example, contents of
#        http://<dhcpServer>/dhcpd.leases).
#        Use VDNetLib::Common::DHCPLeases::GetPage() to get this
#        input value.
#
# Results:
#      A hash with mac address as keys and corresponding ip address as
#      their values. The mac address and ip address information are
#      obtained from the given dhcpserver text content.
#
# Side effects:
#      None
#
########################################################################

sub ParseLeases
{
   my $self = shift;
   my $page = shift;
   my %returnHash;

   # Store all the blocks "lease <ip address> {<lease info>}" from
   # the given page in an array.
   #
   # In the following regex, smg refers to 'treat string as single
   # line', 'multiple lines' and 'global match' respectively.
   #
   my @leases = $page =~ /(lease .*? {.*?})/smg;
   for my $lease (reverse @leases) {
      my $ipregex = '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';
      my $macregex = '(?:[0-9a-f]{2}:){5}[0-9a-f]{2}';
      my $binding = 'binding state active';
      #
      # Add different <mac address> as keys to %returnHash and
      # <ip address> as their values, if the content matches the
      # following pattern:
      #   lease <ip address> {
      #   <...>
      #   <...>
      #   <...>
      #   <...>
      #   binding state active;
      #   hardware ethernet <mac address>;
      #   <...>
      #   }
      #
      if (my ($ip, $mac) = $lease
         =~ /lease ($ipregex) {.*$binding.*hardware ethernet ($macregex)/smg) {
         unless (exists $returnHash{$mac}) {
            $returnHash{$mac} = $ip;
         }
      }
   }
   return \%returnHash;
}


########################################################################
#
# GetLeases --
#     This method updates the class attribute
#     $self->{dhcp}->{<dhcpServer>} for the given <dhcpServer>
#
# Input:
#     DHCP server ip/name as string
#
# Results:
#      Updates $self->{dhcp}->{<dhcpServer>} with a hash (obtained from
#      ParseLeases() method) if the given <dhcpServer> is valid.
#
# Side effects:
#      None
#
########################################################################

sub GetLeases
{
   my $self = shift;
   my $dhcpServer = shift;

   if ($dhcpServer) {
      my $html = $self->GetPage("http://$dhcpServer/dhcpd.leases");
      if (not defined $html) {
         return undef;
      }
      my $leases = $self->ParseLeases($html);
      $self->{dhcp}->{$dhcpServer} = $leases;
   }
}


########################################################################
#
# GetDHCPServer --
#     Returns the DHCP server for the given host
#
# Input:
#     1) host: host for which the DHCP server need to be determined
#     2) stafHelper: reference to a valid VDNetLib::Common::STAFHelper
#                    object
#
# Results:
#      dhcp server address if success,
#      "FAILURE", in case of any error
#
# Side effects:
#      None
#
########################################################################

sub GetDHCPServer
{
   my $self            = shift;
   my $host            = shift;
   my $stafHelper      = shift;
   my $command;

   if (not defined $host || not defined $stafHelper) {
      VDSetLastError("EINVALID");
      return FAILURE;
   }

   my $hostOS = $stafHelper->GetOS($host);
   if ($hostOS eq "FAILURE") {
      VDSetLastError(VDGetLastError());
      return FAILURE;
   }

   if ($hostOS =~ /VMkernel/i) {
      $command = "cat /var/lib/dhcp/dhclient-*.leases";
   } else {
      $command = "cat /var/lib/dhclient/dhclient-*.leases";
   }
   $command = "START SHELL COMMAND $command WAIT RETURNSTDOUT " .
              "STDERRTOSTDOUT";
   my $dhcpServer = $stafHelper->runStafCmd($host,
                                            "PROCESS",
                                             $command);

   $dhcpServer =~ s/\n//g;
   if ($dhcpServer =~
         /dhcp-server-identifier\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/i) {
      $dhcpServer = $1;
      return $dhcpServer;
   } else {
      VDSetLastError("ENOTDEF");
      return FAILURE;
   }
}

1;
