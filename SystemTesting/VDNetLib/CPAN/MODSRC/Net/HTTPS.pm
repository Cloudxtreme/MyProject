package Net::HTTPS;

use strict;
use vars qw($VERSION $SSL_SOCKET_CLASS @ISA);

$VERSION = "5.819";

# Figure out which SSL implementation to use
if ($SSL_SOCKET_CLASS) {
    # somebody already set it
}
elsif ($Net::SSL::VERSION) {
    $SSL_SOCKET_CLASS = "Net::SSL";
}
elsif ($IO::Socket::SSL::VERSION) {
    $SSL_SOCKET_CLASS = "IO::Socket::SSL"; # it was already loaded
}
else {
    eval { require Net::SSL; };     # from Crypt-SSLeay
    if ($@) {
	my $old_errsv = $@;
	eval {
	    require IO::Socket::SSL;
	};
	if ($@) {
	    $old_errsv =~ s/\s\(\@INC contains:.*\)/)/g;
	    die $old_errsv . $@;
	}
	$SSL_SOCKET_CLASS = "IO::Socket::SSL";
    }
    else {
	$SSL_SOCKET_CLASS = "Net::SSL";
    }
}

require Net::HTTP::Methods;

@ISA=($SSL_SOCKET_CLASS, 'Net::HTTP::Methods');

sub configure {
    my($self, $cnf) = @_;
    #
    # Forcing client to ignore SSL verification to avoid
    # warning reported by IO::Sockets::SSL
    # http://communities.vmware.com/message/2162783
    #
    $cnf->{SSL_verify_mode} = 0; #SSL_VERIFY_NONE;
    $self->http_configure($cnf);
}

sub http_connect {
    my($self, $cnf) = @_;
    $self->SUPER::configure($cnf);
}

sub http_default_port {
    443;
}

# The underlying SSLeay classes fails to work if the socket is
# placed in non-blocking mode.  This override of the blocking
# method makes sure it stays the way it was created.
sub blocking { }  # noop

1;
