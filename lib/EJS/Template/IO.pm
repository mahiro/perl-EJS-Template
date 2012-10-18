use 5.006;
use strict;
use warnings;

package EJS::Template::IO;

use IO::Scalar;
use Scalar::Util qw(openhandle);

=head2 input

=cut

sub input {
	my ($class, $input) = @_;
	
	my $in;
	my $should_close = 0;
	
	if (defined $input) {
		if (openhandle($input)) {
			$in = $input;
		} elsif (ref $input) {
			$in = IO::Scalar->new($input);
			$should_close = 1;
		} else {
			open $in, $input or die "$!: $input";
			$should_close = 1;
		}
	} else {
		$in = \*STDIN;
	}
	
	return ($in, $should_close);
}

=head2 output

=cut

sub output {
	my ($class, $output) = @_;
	
	my $out;
	my $should_close = 0;
	
	if (defined $output) {
		if (openhandle $output) {
			$out = $output;
		} elsif (ref $output) {
			$$output = '';
			$out = IO::Scalar->new($output);
			$should_close = 1;
		} else {
			open($out, '>', $output) or die "$!: $output";
			$should_close = 1;
		}
	} else {
		$out = \*STDOUT;
	}
	
	return ($out, $should_close);
}

1;