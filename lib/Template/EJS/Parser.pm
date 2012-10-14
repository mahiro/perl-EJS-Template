use 5.006;
use strict;
use warnings;

package Template::EJS::Parser;

use constant TEXT    => 0;
use constant SCRIPT  => 1;
use constant QUOTE   => 2;
use constant COMMENT => 4;

use Template::EJS::IO;

=head2 new

=cut

sub new {
	my ($class, $config) = @_;
	$config = {} unless ref $config;
	return bless {config => $config}, $class;
}

=head2 parse

=cut

sub parse {
	my ($self, $input, $output) = @_;
	my ($in, $in_close) = Template::EJS::IO->input($input);
	
	my $state = TEXT;
	my $printing = 0;
	
	my @result;
	push @result, qq{print("};
	
	while (my $line = <$in>) {
		while ($line =~ m{(.*?)((?:^[ \t]*)?<%=?|%>(?:[ \t]*\n)?|["']|/\*|\*/|//|\n|$)}mg) {
			my ($text, $mark) = ($1, $2);
			my $space = '';
		
			if ($mark =~ /(\s+)(<%=?)$/) {
				($space, $mark) = ($1, $2);
			} elsif ($mark =~ /(%>)(\s+)/) {
				($mark, $space) = ($1, $2);
			}
		
			if ($state == TEXT) {
				$text =~ s/\\/\\\\/g;
				push @result, $text;
		
				if ($mark eq '<%') {
					push @result, qq{"); $space};
					$state = SCRIPT;
					$printing = 0;
				} elsif ($mark eq '<%=') {
					push @result, qq{", $space};
					$state = SCRIPT;
					$printing = 1;
				} elsif ($mark eq '%>') {
					if ($space) {
						if ($space =~ /(\s*)\n/) {
							push @result, qq($1\\n",\n    ");
						} else {
							push @result, $space;
						}
					}
				} elsif ($mark eq "\n") {
					push @result, qq(\\n",\n    ");
				} elsif ($mark eq '"') {
					push @result, qq(\\");
				} else {
					push @result, $mark;
				}
			} elsif ($state == SCRIPT) {
				push @result, $text;
		
				if ($mark =~ /<%=?/) {
					push @result, $space;
				} elsif ($mark eq '%>') {
					if ($printing) {
						push @result, qq(, ");
		
						if ($space) {
							if ($space =~ /(\s*)\n/) {
								push @result, qq($1\\n",\n    ");
							} else {
								push @result, $space;
							}
						}
					} else {
						push @result, $space;
						push @result, qq{print("};
					}
		
					$state = TEXT;
				} else {
					push @result, $mark;
				}
			}
		}
	}
	
	push @result, qq{");\n};
	close $in if $in_close;
	
	my ($out, $out_close) = Template::EJS::IO->output($output);
	print $out $_ foreach @result;
	close $out if $out_close;
	
	return 1;
}

1;
