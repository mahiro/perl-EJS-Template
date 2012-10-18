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
	my $context = $self->context;
	
	my $assign_hash;
	my $assign_array;
	
	$assign_hash = sub {
		my ($target, $source) = @_;
		
		for my $name (keys %$source) {
			my $ref = reftype $source->{$name};
			
			if ($ref) {
				if ($ref eq 'HASH') {
					$assign_hash->($target->{$name} = {}, $source->{$name});
				} elsif ($ref eq 'ARRAY') {
					$assign_array->($target->{$name} = [], $source->{$name});
				} elsif ($ref eq 'CODE') {
					$target->{$name} = $source->{$name};
				} else {
					# ignore?
				}
			} else {
				$target->{$name} = $source->{$name};
			}
		}
	};
	
	$assign_array = sub {
		my ($target, $source) = @_;
		my $len = scalar(@$source);
		
		for (my $i = 0; $i < $len; $i++) {
			my $ref = reftype $source->[$i];
			
			if ($ref) {
				if ($ref eq 'HASH') {
					$assign_hash->($target->[$i] = {}, $source->[$i]);
				} elsif ($ref eq 'ARRAY') {
					$assign_array->($target->[$i] = [], $source->[$i]);
				} elsif ($ref eq 'CODE') {
					$target->[$i] = $source->[$i];
				} else {
					# ignore?
				}
			} else {
				$target->[$i] = $source->[$i];
			}
		}
	};
	
	$assign_hash->($context, $variables);
	return $context;
}

1;
