use 5.006;
use strict;
use warnings;

package Template::EJS::Executor;

use Template::EJS::IO;

=head2 new

=cut

sub new {
	my ($class, $config) = @_;
	return bless {config => $config}, $class;
}

=head2 execute

=cut

sub execute {
	my ($self, $input, $variables, $output) = @_;
	$variables ||= {};
	
	eval "use JavaScript::V8";
	
	my ($out, $out_close) = Template::EJS::IO->output($output);
	
	my $context = JavaScript::V8::Context->new();
	$context->bind(print => sub { print $out @_ }); # TODO use $output
	
	for my $name (keys %$variables) {
		$context->bind($name, $variables->{$name});
	}
	
	my ($in, $in_close) = Template::EJS::IO->input($input);
	
	my $ret = do {
		local $/;
		$context->eval(<$in>) or die $@;
	};
	
	close $out if $out_close;
	close $in if $in_close;
	
	return $ret;
}

1;
