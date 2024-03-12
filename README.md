# Amazon Pay API Sample Code (Perl)

This Sample Code will allow you to integrate your application with the Amazon Pay v2 API.

# Setup

## clone

```
git clone https://github.com/amazonpay-labs/amazonpay-sample-perl-v2.git
cd amazonpay-sample-perl-v2
```

## install dependencies of perl modules

```
# ex.install Crypt for sign
cpan Digest::SHA
cpan Crypt::PK::RSA
```

This sample code use the following modules.

* LWP::UserAgent
* URI::Split qw(uri_split)
* Digest::SHA qw(sha256_hex)
* Crypt::PK::RSA
* MIME::Base64 qw(encode_base64)
* URI::Escape
* DateTime


# Functions
## Initiate Client

Before issuing any API call, you will have to create a configuration object and pass this to the constructor of the client class. You can then use the client for any of the following code samples of the Amazon Checkout v2 API.

```
use lib '.'; # set a signature.pm on the samne directory
use signature;
use Bytes::Random::Secure qw(random_bytes_hex);
use Data::Dumper;

my $client = AmazonPayClient->new(
    region => 'jp', #us/eu/jp
    public_key_id => 'XXX',
    private_key => 'XXX.pem',
    sandbox => 'true',
    amazon_signature_algorithm => 'AMZN-PAY-RSASSA-PSS-V2'
);
```

> [!NOTE]
'amazon_signature_algorithm' is optional, and it's defalut value is 'AMZN-PAY-RSASSA-PSS'.
If you specify 'AMZN-PAY-RSASSA-PSS-V2' as 'amazon_signature_algorithm', you have to specify same algorithm on Amazon Pay's button script as well by following the page below:
https://developer.amazon.com/docs/amazon-pay-checkout/amazon-pay-script.html


## GenerateButtonSignature

```
my $button_signature = $client->generate_button_signature('{"webCheckoutDetails":{"checkoutReviewReturnUrl":"http://XXX"},"storeId":"XXX","scopes":["name","email","phoneNumber","billingAddress"]}');
```

## GetCheckoutSession

```
my $checkoutsessionid = ''; # set a checkoutsessionid

my $getcheckoutsession_response = $client->api_call(
    url_fragment => "checkoutSessions/$checkoutsessionid",
    method => "GET"
);
```

## Other functions
Please check the [testrun.pl](https://github.com/amazonpay-labs/amazonpay-sample-perl-v2/blob/main/testrun.pl)

# Exception
The instance of AmazonPayClient may throw exceptions in case the parameters you specified are wrong, faces network error, and so on. 
If required, please enclose the process of AmazonPayClient with `eval` clause and deal with the exception like below.
```perl
eval {
    my $client = AmazonPayClient->new(...);
    my $createcheckoutsession_response = $client->api_call(...);
}
if($@) {
    print "Exception occurs: $@";
}
```

# license
Licensed under the Apache License, Version 2.0 (the “License”).
