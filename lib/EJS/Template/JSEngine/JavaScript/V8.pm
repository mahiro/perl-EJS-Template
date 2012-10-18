use 5.006;
use strict;
use warnings;

package EJS::Template::JSEngine::JavaScript::V8;
use base 'EJS::Template::JSEngine';

use JavaScript::V8;

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
	
	for my $name (keys %$variables) {
		$context->bind($name, $variables->{$name});
	}
	
	return $context;
}

1;
