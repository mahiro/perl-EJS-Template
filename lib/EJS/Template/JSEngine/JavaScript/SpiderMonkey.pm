use 5.006;
use strict;
use warnings;

package EJS::Template::JSEngine::JavaScript::SpiderMonkey;
use base 'EJS::Template::JSEngine';

use Scalar::Util qw(reftype);
use JavaScript::SpiderMonkey;

=head2 new

=cut

sub new {
	my ($class) = @_;
	my $context = JavaScript::SpiderMonkey->new;
	$context->init();
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
		my ($obj, $source, $parent_path) = @_;
		
		for my $name (keys %$source) {
			my $ref = reftype $source->{$name};
			my $path = $parent_path ? "$parent_path.$name" : $name;
			
			if ($ref) {
				if ($ref eq 'HASH') {
					my $new_obj = $context->object_by_path($path);
					$assign_hash->($new_obj, $source->{$name}, $path);
				} elsif ($ref eq 'ARRAY') {
					my $new_obj = $context->array_by_path($path);
					$assign_array->($new_obj, $source->{$name}, $path);
				} elsif ($ref eq 'CODE') {
					$context->function_set($name, $source->{$name}, $obj);
				} else {
					# ignore?
				}
			} else {
				if ($parent_path) {
					$context->property_by_path($path, $source->{$name});
				} else {
					JavaScript::SpiderMonkey::JS_DefineProperty(
						$context->{context}, $obj, $name, $source->{$name});
				}
			}
		}
	};
	
	$assign_array = sub {
		my ($obj, $source, $parent_path) = @_;
		my $len = scalar(@$source);
		
		for (my $i = 0; $i < $len; $i++) {
			my $ref = reftype $source->[$i];
			my $path = "$parent_path.$i";
			
			if ($ref) {
				if ($ref eq 'HASH') {
					my $new_obj = $context->object_by_path($path);
					$assign_hash->($new_obj, $source->[$i], $path);
				} elsif ($ref eq 'ARRAY') {
					my $new_obj = $context->array_by_path($path);
					$assign_array->($new_obj, $source->[$i], $path);
				} elsif ($ref eq 'CODE') {
					$context->function_set($i, $source->[$i], $obj);
				} else {
					# ignore?
				}
			} else {
				$context->array_set_element($obj, $i, $source->[$i]);
			}
		}
	};
	
	$assign_hash->($context->{global_object}, $variables, '');
	return $context;
}

1;
