#/* **********************************************************
# * Copyright 2009 VMware, Inc.  All rights reserved.
# * -- VMware Confidential
# * **********************************************************/

package perl::foundryqasrc::fqaclient;
use perl::foundryqasrc::TestOutput;
use strict;
use warnings;
use IO::Socket;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(new);
use constant PACKET_FUNCSIZE => 256;
use constant PACKET_ARGFMTSIZE => 256;
use constant PACKET_ARGDATASIZE => 2048;
use constant RETURN_TYPE_CHAR => 3;
my $remote = 0;
#This function convert hex to ascii
sub h_to_a
  {
    (my $str = shift) =~ s/([a-fA-F0-9]{2})/chr(hex ($1))/eg;
    return $str;
  }
# Change the endianness of nibbles in an integer-from big endian to  little endian
sub h_to_i
  {
    my @bytes = $_[0] =~ /([a-fA-F0-9]{2})/g;
    my @rbytes = reverse @bytes;
    my $h = join ("", @rbytes);
    my $htoi = hex $h;
    return $htoi;
  }
sub close_connection
  {

    my $EndOfComm ="\r\nEndOfCommunication\r\n";
    my $send_buf = $EndOfComm."\0" x (PACKET_FUNCSIZE - length($EndOfComm))."\0" x(PACKET_ARGFMTSIZE). "\0"x (PACKET_ARGDATASIZE);
#    printf("\n buf: %s  len of send_buf: %d\n",  $send_buf, length($send_buf));
    my $close_buf;
    $remote->send($send_buf);
    $remote->recv($close_buf, length($send_buf));
#    print "\nClose_buf: $close_buf\n";
    $remote->close();

  }
# if you want to get execute some function through C server then you need to call like this
# execute_on_server ( <host name>, <port>, <fun name>, <format>, <arguments>, ...)
# e.g. execute_on_server ("ugupta-dev1.eng.vmware.com",  "31415",  "getdevicelist", "%s%d", "/vmfs/volumes/storage2/winxp/winxp.vmx", "8");
sub execute_on_server
  {
    my $self = shift;
    my $host = shift;
    my $port = shift;
    my $fname = shift;
    my $fmt = shift;
    my $argList = "";

    my $recv_hex_data = undef;
    while((my $argValue = shift)) {
      $argList = $argList.$argValue.";";
    }

    my $send_buf = $fname."\0" x (PACKET_FUNCSIZE - length($fname)).$fmt."\0" x(PACKET_ARGFMTSIZE - length($fmt)). $argList."\0"x (PACKET_ARGDATASIZE - length($argList));
     $remote = IO::Socket::INET->new(Proto     => "tcp",
				     PeerAddr  => $host,
				     PeerPort  => $port,
				   );
    unless ($remote) {
      TestError "Can not connect to server $host";
      return undef;
    }
    $remote->autoflush(1);

    my $recv_raw_data;
    TestInfo "Send data: $send_buf";
    $remote->send($send_buf);
    $remote->recv($recv_raw_data, (PACKET_FUNCSIZE + PACKET_ARGFMTSIZE + PACKET_ARGDATASIZE));
    $recv_hex_data = unpack("H*", $recv_raw_data);
# Interpreting the C struture into local data
# Argument of unpack (A8 A2 A2048 A*) is dependent on the data structure "_server_packet" defined in packet.h
# struct _server_packet{
#        _server_return_type type;              // (4 bytes -int parsed in nibbles as A8)
#        bool exception_occurred;               // (1 byte - bool parsed in nibbles as A2)
#        char retData[PACKET_ARGDATASIZE];      // (2048 bytes - char parsed as A2048)
#       char exceptionData[PACKET_ARGDATASIZE]; // (2048 bytes - char parsed as A*)
#}

    (my $type, my $excep_occured, my $retdata, my $excepdata) = unpack('A8A2A2048A*', $recv_hex_data);
    $type = h_to_i($type);
    TestInfo "Return data Type from server: $type";
    if ($type == RETURN_TYPE_CHAR) {
      $retdata = h_to_a($retdata);
    } else {
      $retdata = h_to_i($retdata);
    }
    TestInfo "Return data from server: $retdata";
    close_connection();
    if ($excep_occured >= 1) {
      $excepdata = h_to_a($excepdata);
      TestError "Exception occured at the server, exception msg: ".$excepdata;
      $retdata = undef;
    }

    return $retdata;
  }
1;