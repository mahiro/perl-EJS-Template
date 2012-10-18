use 5.006;
use strict;
use warnings;

package EJS::Template::JSEngine::JE;
use base 'EJS::Template::JSEngine';

use Scalar::Util qw(reftype);
use JE;

=head2 new

=cut

sub new {
	my ($class) = @_;
	my $context = JE->new;
	return bless {context => $context}, $class;
}

=head2 bind

=cut

sub bind {
	my ($self, $variables) = @_;
	
	my $assign;
	
	$assign = sub {
		my ($target, $source) = @_;
		
		for my $name (keys %$source) {
			my $ref = reftype $source->{$name};
			
			if ($ref && $ref eq 'HASH') {
				$assign->($target->{$name} = {}, $source->{$name});
			} else {
				$target->{$name} = $source->{$name};
			}
		}
	};
	
	my $context = $self->context;
	$assign->($context, $variables);
	
	return $context;
}

1;
