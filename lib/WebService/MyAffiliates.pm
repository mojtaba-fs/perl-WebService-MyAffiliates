package WebService::MyAffiliates;

use strict;
use 5.008_005;
our $VERSION = '0.01';

use Carp;
use Mojo::UserAgent;
use Mojo::Util qw(b64_encode url_escape);
use XML::Simple 'XMLin';

use vars qw/$errstr/;
sub errstr { $errstr }

sub new {
    my $class = shift;
    my %args  = @_ % 2 ? %{$_[0]} : @_;

    for (qw/user pass host/) {
        $args{$_} || croak "Param $_ is required.";
    }

    # fix host with schema
    $args{host} = 'http://' . $args{host} unless $args{host} =~ m{^https?\://};
    $args{host} =~ s{/$}{};

    $args{timeout}  ||= 30; # for ua timeout

    return bless \%args, $class;
}

sub __ua {
    my $self = shift;

    return $self->{ua} if exists $self->{ua};

    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(3);
    $ua->inactivity_timeout($self->{timeout});
    $ua->proxy->detect; # env proxy
    $ua->cookie_jar(0);
    $ua->max_connections(100);
    $self->{ua} = $ua;

    return $ua;
}

## https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+4%3A+Decode+Token

sub decode_token {
    my $self = shift;
    my @tokens = @_;

    $self->request('/feeds.php?FEED_ID=4&TOKENS=' . url_escape(join(',', @tokens)));
}

sub request {
    my ($self, $url, $method, %params) = @_;

    $method ||= 'GET';

    my $ua = $self->__ua;
    my $header = {
        Authorization => 'Basic ' . b64_encode($self->{user} . ':' . $self->{pass}, '')
    };
    my @extra = %params ? (form => \%params) : ();
    my $tx = $ua->build_tx($method => $self->{host} . $url => $header => @extra);

    $tx = $ua->start($tx);
    use Data::Dumper; print STDERR Dumper(\$tx);
    if ($tx->res->headers->content_type and $tx->res->headers->content_type =~ 'text/xml') {
        return XMLin($tx->res->body);
    }
    if (! $tx->success) {
        $errstr = $tx->error->{message};
        return;
    }

    $errstr = "Unknown Response.";
    return;
}

1;
__END__

=encoding utf-8

=head1 NAME

WebService::MyAffiliates - Interface to myaffiliates.com API

=head1 SYNOPSIS

    use WebService::MyAffiliates;

    my $aff = WebService::MyAffiliates->new(
        user => 'user',
        pass => 'pass',
        host => 'admin.example.com'
    );

    my $token_info = $aff->decode_token($token) or die $aff->errstr;

=head1 DESCRIPTION

WebService::MyAffiliates is Perl interface to L<http://www.myaffiliates.com/xmlapi>

=head1 METHODS

=head2 new

=over 4

=item * user

required. the Basic Auth username.

=item * pass

required. the Basic Auth password.

=item * host

required. the Basic Auth url/host.

=back

=head2 decode_token

L<https://myaffiliates.atlassian.net/wiki/display/PUB/Feed+4%3A+Decode+Token>

Feed 4: Decode Token

    my $token_info = $aff->decode_token($token); # $token_info is a HASH which contains TOKEN key
    my $token_info = $aff->decode_token($tokenA, $tokenB);

=head1 AUTHOR

Binary.com E<lt>fayland@binary.comE<gt>

=head1 COPYRIGHT

Copyright 2014- Binary.com

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
