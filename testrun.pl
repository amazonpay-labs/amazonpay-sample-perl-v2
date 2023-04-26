use lib '.';
use signature;
use Bytes::Random::Secure qw(random_bytes_hex);
use Data::Dumper;

### main ###
eval {
    my $client = AmazonPayClient->new(
        region => 'jp',
        public_key_id => 'AFUXXXX',
        private_key => 'AmazonPay_AFUXXXX.pem',
        sandbox => 1
    );

    generate_button_signature($client);
};
if($@) {
    print "Exception occurs: $@";
}


### sample function ###
sub generate_button_signature {
    my ($client) = @_;

    print "--- GenerateButtonSignature ---\n";
    my $button_signature = $client->generate_button_signature('{"webCheckoutDetails":{"checkoutReviewReturnUrl":"http://localhost:8080/confirmation.html"},"storeId":"amzn1\.application-oa2-client\.XXX","scopes":["name","email","phoneNumber","billingAddress"]}');
    print "$button_signature \n";
}

sub create_checkoutsession {
    my ($client) = @_;

    print "\n--- CreateCheckoutSession ---\n";
    my $createcheckoutsession_response = $client->api_call(
        url_fragment => "checkoutSessions",
        method => "POST",
        payload => {
            "webCheckoutDetails" => {
                "checkoutReviewReturnUrl" => "http://localhost:8080/confirmation.html",
            },
            "storeId" => "amzn1\.application-oa2-client\.XXX"
        },
        headers => {
            'x-amz-pay-idempotency-key' => random_bytes_hex(10)
        }
    );
    print Dumper $createcheckoutsession_response;
}

sub get_checkoutsession {
    my ($client) = @_;

    print "\n--- GetCheckoutSession ---\n";
    my $getcheckoutsession_response = $client->api_call(
        url_fragment => "checkoutSessions/XXX",
        method => "GET"
    );
    print Dumper $getcheckoutsession_response;
}

sub update_checkoutsession {
    my ($client) = @_;

    print "\n--- updateCheckoutSession ---\n";
    my $updatecheckoutsession_response = $client->api_call(
        url_fragment => "checkoutSessions/XXX",
        method => "PATCH",
        payload => {
            "webCheckoutDetails" => {
                "checkoutResultReturnUrl" => "https://localhost:8080/thanks.html"
            },
            'paymentDetails' => {
                #  'paymentIntent' => 'Confirm',
                #  'paymentIntent' => 'AuthorizedAndCapture',
                'paymentIntent' => 'Authorize',
                'canHandlePendingAuthorization' => false,
                'chargeAmount' => {
                    'amount' => '1',
                    'currencyCode' => "JPY"
                },
            },
            'merchantMetadata' => {
                'merchantReferenceId' => '2020-00000001',
                'merchantStoreName' => 'Amazon Pay Demo Shop',
                'noteToBuyer' => 'Thank you for your order!'
                # "customInformation" => "customInformation",
            }
        },
        headers => {
            'x-amz-pay-idempotency-key' => random_bytes_hex(10)
        }
    );
    print Dumper $updatecheckoutsession_response;
}

sub complete_checkoutsession {
    my ($client) = @_;

    print "\n--- completeCheckoutSession ---\n";
    my $completecheckoutsession_response = $client->api_call(
        url_fragment => "checkoutSessions/XXX/complete",
        method => "POST",
        payload => {
                'chargeAmount' => {
                    'amount' => '1',
                    'currencyCode' => "JPY"
                }
        },
        headers => {
            'x-amz-pay-idempotency-key' => random_bytes_hex(10)
        }
    );
    print Dumper $completecheckoutsession_response;
}

sub create_charge {
    my ($client) = @_;

    print "\n--- createCharge ---\n";
    my $createcharge_response = $client->api_call(
        url_fragment => "charges",
        method => "POST",
        payload => {
            'chargePermissionId' => "S03-XXX-XXX",
            'chargeAmount' => {
                'amount' => "1",
                'currencyCode' => "JPY"
        },
            'captureNow' => true,
            'canHandlePendingAuthorization' => true
        },
        headers => {
            'x-amz-pay-idempotency-key' => random_bytes_hex(10)
        }
    );
    print Dumper $createcharge_response;
}

sub get_charge {
    my ($client) = @_;

    print "\n--- getCharge ---\n";
    my $getcharge_response = $client->api_call(
        url_fragment => "charges/S03-XXX-XXX-C0XXX",
        method => "GET",
        headers => {
            'x-amz-pay-idempotency-key' => random_bytes_hex(10)
        }
    );
    print Dumper $getcharge_response;    
}

sub capture_charge {
    my ($client) = @_;

    print "\n--- captureCharge ---\n";
    my $capturecharge_response = $client->api_call(
        url_fragment => "charges/S03-XXX-XXX-C0XXX/capture",
        method => "POST",
        payload => {
            'captureAmount' => {
                'amount' => "1",
                'currencyCode' => "JPY"
            }
        },
        headers => {
            'x-amz-pay-idempotency-key' => random_bytes_hex(10)
        }
    );
    print Dumper $capturecharge_response;
}

sub create_refund {
    my ($client) = @_;

    print "\n--- createRefund ---\n";
    my $createrefund_response = $client->api_call(
        url_fragment => "refunds",
        method => "POST",
        payload => {
            'chargeId' => "S03-XXX-XXX-C0XXX",
            'refundAmount' => {
                'amount' => "1",
                'currencyCode' => "JPY"
            }
        },
        headers => {
            'x-amz-pay-idempotency-key' => random_bytes_hex(10)
        }
    );
    print Dumper $createrefund_response;
}