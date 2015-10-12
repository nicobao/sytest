push our @EXPORT, qw( matrix_sync );

=head2 matrix_sync

    my ( $sync_body ) = matrix_sync( $user, %query_params )->get;

Make a v2_alpha/sync request for the user. Returns the response body as a
reference to a hash.

=cut

sub matrix_sync {
    my ( $user, %params ) = @_;
    do_request_json_for( $user,
        method  => "GET",
        uri     => "/v2_alpha/sync",
        params  => \%params,
    )->on_done(sub {
        my ( $body ) = @_;
        require_json_keys( $body, qw( rooms presence next_batch ) );
        require_json_keys( $body->{presence}, qw( events ));
        require_json_keys( my $rooms = $body->{rooms}, qw( joined invited archived ) );
    });
}

test "Can sync",
    requires => [qw( first_api_client can_create_filter )],
    provides => [qw( can_sync )],

    do => sub {
        my ( $http ) = @_;
        my ( $user, $filter_id );
        matrix_register_user_with_filter( $http, {} )->then( sub {
            ( $user, $filter_id ) = @_;
            matrix_sync( $user, filter => $filter_id )
        })->then( sub {
            my ( $body ) = @_;
            matrix_sync( $user,
                filter => $filter_id,
                since => $body->{next_batch},
            )
        })->then( sub {
            provide can_sync => 1;
            Future->done(1);
        })
    };
