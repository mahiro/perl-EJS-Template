use 5.006;
use strict;
use warnings;

package EJS::Template::Base;

use Scalar::Util qw(reftype);

=head2 new

=cut

sub new {
    my ($class, $config) = @_;
    $config = {} unless ref $config;
    return bless {config => $config}, $class;
}

=head2 config

=cut

sub config {
    my $self = shift;
    my $config = $self->{config};
    
    for my $name (@_) {
        if ((reftype($config) || '') eq 'HASH') {
            $config = $config->{$name};
        } else {
            return undef;
        }
    }
    
    return $config;
}

1;
