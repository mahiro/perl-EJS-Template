use 5.006;
use strict;
use warnings;

package EJS::Template::Parser;
use base 'EJS::Template::Base';

use EJS::Template::IO;
use EJS::Template::Parser::Context;

=head2 parse

=cut

sub parse {
	my ($self, $input, $output) = @_;
	my ($in, $in_close) = EJS::Template::IO->input($input);
	
	my $context;
	
	eval {
		$context = EJS::Template::Parser::Context->new($self->config);
		
		while (my $line = <$in>) {
			$line =~ s/\r+\n?$/\n/;
			$context->read_line($line);
		}
	};
	
	my $e = $@;
	close $in if $in_close;
	die $e if $e;
	
	my ($out, $out_close) = EJS::Template::IO->output($output);
	
	eval {
		print $out $_ foreach @{$context->result};
	};
	
	$e = $@;
	close $out if $out_close;
	die $e if $e;
	
	return 1;
}

1;
