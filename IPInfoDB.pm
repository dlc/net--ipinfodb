package Net::IPInfoDB;

# ----------------------------------------------------------------------
# Net::IPInfoDB - fetch ip info form ipinfodb.com
# ----------------------------------------------------------------------

use strict;
use vars qw($VERSION $DEBUG @FIELDS);
use vars qw($API_URI $API_VERSION);
use vars qw($WEB_URI);

use LWP::Simple qw(get);
use URI;

$VERSION = '3.0';
$DEBUG = 0 unless defined $DEBUG;

$API_URI = 'http://api.ipinfodb.com';
$API_VERSION = 'v3';

$WEB_URI = 'http://ipinfodb.com/ip_locator.php?ip=';
@FIELDS = qw(status_code status_message ip_address country_code country_name
             region_name city_name zip_code latitude longitude timezone);

sub new {
    my $class = shift;

    my $self = bless {
        _KEY    => '',
        _ERROR  => '',
    } => $class;

    if (@_) {
        $self->key($_[0]);
    }
    elsif (my $k = $ENV{'IPINFODB_TOKEN'}) {
        $self->key($k);
    }

    return $self;
}

sub key {
    my $self = shift;

    if (@_) {
        $self->{ _KEY } = $_[0];
    }

    return $self->{ _KEY };
}

sub error {
    my $self = shift;

    if (@_) {
        $self->{'_ERROR'} = "@_";
        return;
    }

    return $self->{'_ERROR'};
}

sub get_city {
    my $self = shift;
    my $host = shift;

    return $self->_get('ip-city', $host);
}

sub get_country {
    my $self = shift;
    my $host = shift;

    return $self->_get('ip-country', $host);
}

sub _get {
    my $self = shift;
    my $meth = shift;
    my $addr = shift;
    my $raw;
    my $res = Net::IPInfoDB::Result->new;

    my $uri = URI->new("$API_URI/$API_VERSION/$meth");
    $uri->query_form(
        format  => "raw",
        key     => $self->key,
        ip      => $addr,
    );

    if ($raw = get($uri)) {
        my @f = split /;/, $raw;
        for (my $i = 0; $i < @f; $i++) {
            my $m = $FIELDS[ $i ];
            $res->$m($f[ $i ]);
        }
    }


    if ($res->status_code ne "OK") {
        return $self->error($res->status_message);
    }

    $res->web_uri("$WEB_URI$addr");
    $res->_raw($raw);

    return $res;
}

package Net::IPInfoDB::Result;

use Class::Struct;

struct(
    (map { $_ => '$' } @Net::IPInfoDB::FIELDS),
    'web_uri' => '$',
    '_raw'    => '$',
);

sub fields {
    return @Net::IPInfoDB::FIELDS;
}

1;

__END__

=head1 NAME

Net::IPInfoDB - Perl interface to ipinfodb.com's Geolocation XML API

=head1 SYNOPSIS

    use Net::IPInfoDB;

    my $g = Net::IPInfoDB->new($key);
    my $c = $g->get_city("128.103.1.1");

=head1 USAGE

C<Net::IPInfoDB> makes use of the Free Geolocation API from
ipinfodb.com. Note that you'll need to register your app for a
(free) API key in order to use this module. Information on the API
is available at C<http://ipinfodb.com/ip_location_api.php>.

Basic usage follows the API petty closely:

    use Net::IPInfoDB;

    my $g = Net::IPInfoDB->new;
    $g->key($api_key);

    my $ip_info = $g->get_country($ip_address);

=head1 METHODS

=over 4

=item new

Creates a new C<Net::IPInfoDB> instance.

Optionally takes a key as the first argument; if provided, will call
the C<key> method for you. If the $ENV{IPINFODB_TOKEN} exists,
C<Net::IPInfoDB> assumes it contains the token and will call
C<key($ENV{IPINFODB_TOKEN})> for you.

=item key

Use C<key> to specify your API key. Calling C<get_city> or
C<get_country> without specifying a key will result in a failure.

=item get_country

Returns country-level details about the host or ip address. Takes an
IP address or hostname as the only argument.

=item get_city

Returns city-level details, which is more resource-intensive on the
server. If you only need the country name, avoid using the city
precision API.

=back

=head1 CACHING

C<Net::IPInfoDB> does I<not> do any caching of responses. You should
definitely cache your responses using C<Cache::Cache> or something
similar.

=head1 AUTHOR

Darren Chamberlain E<lt>darren@cpan.orgE<gt>

=head1 VERSION

This is version 3.0. Note that the major version of C<Net::IPInfoDB>
matches the ipinfodb.com API version.

