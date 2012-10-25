use 5.006;
use strict;
use warnings;

package EJS::Template::JSEngine::JavaScript::V8;
use base 'EJS::Template::JSEngine';

use JavaScript::V8;
use Scalar::Util qw(reftype tainted);

=head2 new

=cut

sub new {
	my ($class) = @_;
	my $context = JavaScript::V8::Context->new();
	return bless {context => $context}, $class;
}

=head2 bind

=cut

sub bind {
	my ($self, $variables) = @_;
	my $context = $self->context;
	
	my $assign_value;
	my $assign_hash;
	my $assign_array;
	
	$assign_value = sub {
		my ($target_ref, $source_ref) = @_;
		my $reftype = reftype $$source_ref;
		
		if ($reftype) {
			if ($reftype eq 'HASH') {
				$assign_hash->($$target_ref = {}, $$source_ref);
			} elsif ($reftype eq 'ARRAY') {
				$assign_array->($$target_ref = [], $$source_ref);
			} elsif ($reftype eq 'CODE') {
				$$target_ref = $$source_ref;
			} else {
				# ignore?
			}
		} else {
			$$target_ref = tainted($$source_ref) ?
					do {$$source_ref =~ /(.*)/s; $1} : $$source_ref;
		}
	};
	
	$assign_hash = sub {
		my ($target, $source) = @_;
		
		for my $name (keys %$source) {
			$assign_value->(\$target->{$name}, \$source->{$name});
		}
	};
	
	$assign_array = sub {
		my ($target, $source) = @_;
		my $len = scalar(@$source);
		
		for (my $i = 0; $i < $len; $i++) {
			$assign_value->(\$target->[$i], \$source->[$i]);
		}
	};
	
	my $clone = {};
	$assign_hash->($clone, $variables);
	
	for my $name (keys %$clone) {
		$context->bind($name, $clone->{$name});
	}
	
	return $context;
}

1;
