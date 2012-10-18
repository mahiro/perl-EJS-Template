use 5.006;
use strict;
use warnings;

package EJS::Template::Executor;

use EJS::Template::IO;
use EJS::Template::JSEngine;

=head2 new

=cut

sub new {
	my ($class, $config) = @_;
	$config = {} unless ref $config;
	return bless {config => $config}, $class;
}

=head2 execute

=cut

sub execute {
	my ($self, $input, $variables, $output) = @_;
	my $engine = EJS::Template::JSEngine->create($self->{config}{engine});
	
	my ($out, $out_close) = EJS::Template::IO->output($output);
	my $ret;
	
	eval {
		$engine->bind({print => sub { print $out @_ }});
		$engine->bind($variables);
		
		my ($in, $in_close) = EJS::Template::IO->input($input);
		
		eval {
			local $/;
			
			if (defined(my $js = <$in>)) {
				$ret = $engine->eval($js) or die $@;
			} else {
				$ret = 1;
			}
		};
		
		my $e = $@;
		close $in if $in_close;
		die $e if $e;
	};
	
	my $e = $@;
	close $out if $out_close;
	die $e if $e;
	
	return $ret;
}

1;
