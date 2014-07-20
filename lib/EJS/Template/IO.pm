use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::IO - Normalizes input/output parameters for EJS::Template

=cut

package EJS::Template::IO;

use IO::Scalar;
use Scalar::Util qw(openhandle);

=head1 Methods

=head2 input

Normalizes input.

   EJS::Template::IO->input('filepath.ejs');
   EJS::Template::IO->input(\$source_text);
   EJS::Template::IO->input($input_handle);
   EJS::Template::IO->input(\*STDIN);

It returns a list in the form C<($input, $should_close)>, where C<$input> is
the normalized input handle and C<$should_close> indicates the file handle has
been opened and your code is responsible for closing it.

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

Normalizes output.

   EJS::Template::IO->output('filepath.out');
   EJS::Template::IO->output(\$result_text);
   EJS::Template::IO->output($output_handle);
   EJS::Template::IO->output(\*STDOUT);

It returns a list in the form C<($output, $should_close)>, where C<$output> is
the normalized output handle and C<$should_close> indicates the file handle has
been opened and your code is responsible for closing it.

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

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
