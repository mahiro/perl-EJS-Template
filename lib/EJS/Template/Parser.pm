use 5.006;
use strict;
use warnings;

package EJS::Template::Parser;

use constant TEXT    => 0;
use constant SCRIPT  => 1;
use constant QUOTE   => 2;
use constant COMMENT => 4;

use EJS::Template::IO;

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
	my ($in, $in_close) = EJS::Template::IO->input($input);
	
	my $state = TEXT;
	my $interpolating = 0;
	my $printing = 0;
	
	my @result;
	
	while (my $line = <$in>) {
		my $right_trimmed = 0;
		
		while ($line =~ m{(.*?)((^\s*)?<%=?|%>(\s*?$)?|["']|/\*|\*/|//|\n|$)}g) {
			my ($text, $mark, $left, $right) = ($1, $2, $3, $4);
			$mark =~ s/\s+(<%=?)/$1/;
			$mark =~ s/(%>)\s+/$1/;
			
			if ($state == TEXT) {
				$text =~ s/\\/\\\\/g;
				
				if ($text ne '') {
					if (!$printing) {
						push @result, qq{print("};
						$printing = 1;
					}
					
					push @result, $text;
				}
				
				if ($mark eq '<%') {
					if ($printing) {
						push @result, qq{");};
						$printing = 0;
					}
					
					push @result, $left if defined $left && $left ne '';
					$state = SCRIPT;
				} elsif ($mark eq '<%=') {
					if ($printing) {
						push @result, $left if defined $left && $left ne '';
						push @result, qq{");};
						$printing = 0;
					} else {
						push @result, qq{print("$left");} if defined $left && $left ne '';
					}
					
					push @result, qq{print(};
					$interpolating = 1;
					
					$state = SCRIPT;
				} elsif ($mark eq '%>') {
					# Syntax error?
					push @result, $mark;
					push @result, $right if defined $right && $right ne '';
				} elsif ($mark eq "\n") {
					if ($printing) {
						push @result, qq{\\n");\n};
						$printing = 0;
					} else {
						if ($right_trimmed) {
							push @result, qq{\n};
						} else {
							push @result, qq{print("\\n");\n};
						}
					}
				} elsif ($mark eq '"') {
					push @result, qq(\\");
				} else {
					push @result, $mark;
				}
			} elsif ($state == SCRIPT) {
				push @result, $text;
				
				if ($mark =~ /<%=?/) {
					push @result, $left if defined $left && $left ne '';
					push @result, $mark;
				} elsif ($mark eq '%>') {
					if ($interpolating) {
						push @result, qq{);};
						$interpolating = 0;
						
						if (defined $right && $right ne '') {
							push @result, qq{print("$right};
							$printing = 1;
						}
					} else {
						push @result, $right if defined $right && $right ne '';
						$right_trimmed = 1 if defined $right;
					}
					
					$state = TEXT;
				} else {
					push @result, $mark;
				}
			}
		}
	}
	
	close $in if $in_close;
	
	push @result, qq{");} if $printing;
	push @result, qq{);} if $interpolating;
	
	my ($out, $out_close) = EJS::Template::IO->output($output);
	print $out $_ foreach @result;
	close $out if $out_close;
	
	return 1;
}

1;