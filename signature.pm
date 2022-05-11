package AmazonPayClient;
use strict;
use warnings;
use HTTP::Request;
use HTTP::Headers;
use LWP::UserAgent;
use URI::Split qw(uri_split);
use JSON::PP;
use Data::Dumper;

$JSON::PP::true = 1;
$JSON::PP::false = 0;

my @METHOD_TYPES = ('GET','POST','PUT','PATCH','DELETE');

sub new {
    my $class = shift;
    my %param = @_;

    my $self = bless {}, $class;    
    $self->{helper} = Helper->new(
        region => _valid_regex($param{region}, 'region', '^jp|eu|na$'),
        public_key_id => _valid_regex($param{public_key_id}, 'public_key_id', '^[\-0-9a-zA-Z]+$'),
        private_key_file => _valid_regex($param{private_key}, 'private_key', '\.pem$'),
        environment => $param{sandbox} ? 'sandbox': 'live'
    );
    return $self;
}

sub generate_button_signature {
    my ($self, $payload) = @_;
    die "payload must be string" if(ref($payload) eq "HASH");
    return $self->{helper}->sign($payload);
}

sub api_call {
    my $self = shift;
    my %param = @_;
    
    my $method_regex = join('|', @METHOD_TYPES);

    my ($url_fragment, $method, $payload, $headers, $query_params) = (
        _valid_regex($param{url_fragment}, 'url_fragment', '^buyers|checkoutSessions|chargePermissions|charges|deliveryTrackers|refunds'), 
        _valid_regex($param{method}, 'method', "^$method_regex\$"), 
        _valid_hash($param{payload}, 'payload'), 
        _valid_hash($param{headers}, 'headers'), 
        _valid_hash($param{query}, 'query')
    );
    my $query = $self->{helper}->to_query($query_params);
    my $url = $self->{helper}->base_url() . $url_fragment . $query;

    $method = $self->{helper}->http_method($method);
    my $request_body = $payload ? encode_json($payload) : '';

    my ($scheme, $hosts, $path, $urlquery, $frag) = uri_split($url);
    my $signed_headers = $self->{helper}->signed_headers($method, $hosts, $path, $request_body, $headers, $query);

    my $request = HTTP::Request->new($method => $url, HTTP::Headers->new(%{$signed_headers}));
    $request->content($request_body) if($request_body);

    my $ua = LWP::UserAgent->new(ssl_opts => { verify_hostname => 1 });
    my $uares = $ua->request($request);

    return {
        'status' => $uares->code,
        'body' => decode_json($uares->content)
    };
}

sub _valid_regex {
    my ($target, $argname, $regex) = @_;
    die "$argname is required" unless($target);
    if($regex) {
        die "$argname does not match $regex" unless($target =~ /$regex/);
    }
    return $target;
}

sub _valid_hash {
    my ($target, $argname) = @_;
    if($target) {
        die "$argname must be HASH" unless(ref($target) eq "HASH");
    }
    return $target;
}

package Helper;
use Digest::SHA qw(sha256_hex);
use Crypt::PK::RSA;
use MIME::Base64 qw(encode_base64);
use URI::Escape;
use DateTime;

use constant {
    API_VERSION => 'v2',
    HASH_ALGORITHM => 'SHA256',
    AMAZON_SIGNATURE_ALGORITHM => 'AMZN-PAY-RSASSA-PSS',
};

my %API_ENDPOINTS = (
    'na' => 'pay-api.amazon.com',
    'eu' => 'pay-api.amazon.eu',
    'jp' => 'pay-api.amazon.jp'
);

sub new {
    my $class = shift;
    my %param = @_;
    
    my $env = $param{sandbox} ? 'sandbox' : 'live';
    my $self = bless {
        region => $param{region},
        public_key_id => $param{public_key_id},
        private_key_file => $param{private_key_file},
        environment => $param{environment}
    }, $class;
    return $self;
}

sub base_url {
    my ($self) = @_;
    return "https://$API_ENDPOINTS{$self->{region}}/$self->{environment}/". API_VERSION . "/";
}

sub http_method {
    my ($self, $method) = @_;
    my $uc_method = uc($method);
    die "error" if(!grep {$_ eq $uc_method} @METHOD_TYPES);
    return $uc_method;
}

sub signed_headers {
    my ($self, $method, $hosts, $path, $payload, $user_headers, $query) = @_;
    $payload = '' if $path =~ /account-management\/v2\/accounts/;

    my $headers = { map { $user_headers->{$_} =~ s/\s+/ /g; $_ => $user_headers->{$_} } keys %$user_headers };

    $headers->{'accept'} = $headers->{'content-type'} = 'application/json';
    $headers->{'x-amz-pay-region'} = $self->{region};
    $headers->{'x-amz-pay-date'} = formatted_timestamp();
    $headers->{'X-amz-pay-host'} = $hosts;

    my $lower_headers = { map { lc($_) => $headers->{$_} } keys %$headers };
    my $canonical_headers = join("\n", map { "$_:$lower_headers->{$_}" } sort keys %$lower_headers);
    my $canonical_header_names = join(';', sort keys(%$lower_headers));
    my $hex_and_hash_payload = Digest::SHA::sha256_hex($payload);

    my $canonical_request = "$method\n$path\n$query\n$canonical_headers\n\n$canonical_header_names\n$hex_and_hash_payload";

    my $signature = $self->sign($canonical_request);
    my $signed_headers = "SignedHeaders=$canonical_header_names, Signature=$signature";

    $headers->{'authorization'} = AMAZON_SIGNATURE_ALGORITHM . " PublicKeyId=$self->{public_key_id}, $signed_headers";
    return $headers;
}

sub sign {
    my ($self, $string_to_sign) = @_;
    my $hexhash = Digest::SHA::sha256_hex($string_to_sign);
    my $hashed_canonical_request = AMAZON_SIGNATURE_ALGORITHM . "\n$hexhash";
    my $privateKey = Crypt::PK::RSA->new($self->{private_key_file});
    my $signature = $privateKey->sign_message($hashed_canonical_request, HASH_ALGORITHM, 'pss', 20);
    my $encoded = encode_base64($signature);
    $encoded =~ s/[\r\n]//g;
    return $encoded;
}

sub to_query {
    my ($self, $query_params) = @_;

    my $query = join('&', map { "$_=$query_params->{$_}" } sort keys %$query_params);
    chop($query);
    return $query ? "?$query" : '';
}

sub formatted_timestamp {
    my $now = DateTime->now()->iso8601().'Z';
    return join('', split(/[-:]/, $now));
}
