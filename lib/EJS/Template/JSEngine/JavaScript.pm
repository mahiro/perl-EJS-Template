use 5.006;
use strict;
use warnings;

package EJS::Template::JSEngine::JavaScript;
use base 'EJS::Template::JSEngine';

use Encode;
use JavaScript;
use Scalar::Util qw(reftype tainted);

=head2 new

=cut

sub new {
	my ($class) = @_;
	my $runtime = JavaScript::Runtime->new;
	my $context = $runtime->create_context;
	return bless {runtime => $runtime, context => $context}, $class;
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
		my ($parent_path, $name, $source_ref) = @_;
		
		my $reftype = reftype $$source_ref;
		my $path = $parent_path ? "$parent_path.$name" : $name;
		
		if ($reftype) {
			if ($reftype eq 'HASH') {
				#$context->bind_value($path, {});
				JavaScript::Context::jsc_bind_value($context, $parent_path, $name, {});
				$assign_hash->($path, $$source_ref);
			} elsif ($reftype eq 'ARRAY') {
				#$context->bind_value($path, []);
				JavaScript::Context::jsc_bind_value($context, $parent_path, $name, []);
				$assign_array->($path, $$source_ref);
			} elsif ($reftype eq 'CODE') {
				#$context->bind_function($path, $$source_ref);
				JavaScript::Context::jsc_bind_value($context, $parent_path, $name, $$source_ref);
			} else {
				# ignore?
			}
		} else {
			#$context->bind_value($path, $$source_ref);
			JavaScript::Context::jsc_bind_value($context, $parent_path, $name,
					tainted($$source_ref) ? do {$$source_ref =~ /(.*)/s; $1} : $$source_ref);
		}
	};
	
	$assign_hash = sub {
		my ($parent_path, $source) = @_;
		
		for my $name (keys %$source) {
			$assign_value->($parent_path, $name, \$source->{$name});
		}
	};
	
	$assign_array = sub {
		my ($parent_path, $source) = @_;
		my $len = scalar(@$source);
		
		for (my $i = 0; $i < $len; $i++) {
			$assign_value->($parent_path, $i, \$source->[$i]);
		}
	};
	
	$assign_hash->('', $variables);
	return $context;
}

sub DESTROY {
	my ($self) = @_;
	$self->{context}->_destroy();
	$self->{runtime}->_destroy();
	delete $self->{context};
	delete $self->{runtime};
}

1;
