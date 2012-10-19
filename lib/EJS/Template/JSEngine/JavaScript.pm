use 5.006;
use strict;
use warnings;

package EJS::Template::JSEngine::JavaScript;
use base 'EJS::Template::JSEngine';

use Scalar::Util qw(reftype);
use JavaScript;

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
	
	my $assign_hash;
	my $assign_array;
	
	$assign_hash = sub {
		my ($source, $parent_path) = @_;
		
		for my $name (keys %$source) {
			my $ref = reftype $source->{$name};
			my $path = $parent_path ? "$parent_path.$name" : $name;
			
			if ($ref) {
				if ($ref eq 'HASH') {
					#$context->bind_value($path, {});
					JavaScript::Context::jsc_bind_value($context, $parent_path, $name, {});
					$assign_hash->($source->{$name}, $path);
				} elsif ($ref eq 'ARRAY') {
					#$context->bind_value($path, []);
					JavaScript::Context::jsc_bind_value($context, $parent_path, $name, []);
					$assign_array->($source->{$name}, $path);
				} elsif ($ref eq 'CODE') {
					#$context->bind_function($path, $source->{$name});
					JavaScript::Context::jsc_bind_value($context, $parent_path, $name, $source->{$name});
				} else {
					# ignore?
				}
			} else {
				#$context->bind_value($path, $source->{$name});
				JavaScript::Context::jsc_bind_value($context, $parent_path, $name, $source->{$name});
			}
		}
	};
	
	$assign_array = sub {
		my ($source, $parent_path) = @_;
		my $len = scalar(@$source);
		
		for (my $i = 0; $i < $len; $i++) {
			my $ref = reftype $source->[$i];
			my $path = "$parent_path\[$i]";
			
			if ($ref) {
				if ($ref eq 'HASH') {
					#$context->bind_value($path, {});
					JavaScript::Context::jsc_bind_value($context, $parent_path, $i, {});
					$assign_hash->($source->[$i], $path);
				} elsif ($ref eq 'ARRAY') {
					#$context->bind_value($path, []);
					JavaScript::Context::jsc_bind_value($context, $parent_path, $i, []);
					$assign_array->($source->[$i], $path);
				} elsif ($ref eq 'CODE') {
					#$context->bind_function($path, $source->[$i]);
					JavaScript::Context::jsc_bind_value($context, $parent_path, $i, $source->[$i]);
				} else {
					# ignore?
				}
			} else {
				#$context->bind_value($path, $source->[$i]);
				JavaScript::Context::jsc_bind_value($context, $parent_path, $i, $source->[$i]);
			}
		}
	};
	
	$assign_hash->($variables, '');
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
