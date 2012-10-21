use 5.006;
use strict;
use warnings;

package EJS::Template::Parser;
use base 'EJS::Template::Base';

use constant TEXT    => 0;
use constant SCRIPT  => 1;
use constant QUOTE   => 2;
use constant COMMENT => 4;

use EJS::Template::IO;
use EJS::Template::Runtime;

=head2 parse

=cut

sub parse {
	my ($self, $input, $output) = @_;
	my ($in, $in_close) = EJS::Template::IO->input($input);
	
	my $state = TEXT;
	my $interpolating = 0;
	my $escaping = 0;
	my $printing = 0;
	my $left_trimmed = 0;
	my $left_trimmed_index = undef;
	
	my $default_escape = do {
		my $name = $self->config('escape') || '';
		
		if ($name eq '' || $name eq 'raw') {
			'';
		} else {
			$EJS::Template::Runtime::ESCAPES{$name} || '';
		}
	};
	
	my @result;
	
	while (my $line = <$in>) {
		my $right_trimmed = 0;
		
		while ($line =~ m{(.*?)((^\s*)?<%(?:(?:\s*:\s*\w+\s*)?=)?|%>(\s*?$)?|["']|/\*|\*/|//|\n|$)}g) {
			my ($text, $mark, $left, $right) = ($1, $2, $3, $4);
			my $escape;
			
			if ($mark =~ s/<%\s*:\s*(\w+)\s*=/<%=/) {
				my $name = $1;
				$escape = $EJS::Template::Runtime::ESCAPES{$name} || '';
			} elsif ($mark eq '<%=') {
				$escape = $default_escape;
			}
			
			$mark =~ s/\s+(<%=?)/$1/;
			$mark =~ s/(%>)\s+/$1/;
			
			if ($state == TEXT) {
				$text =~ s/\\/\\\\/g;
				
				if ($text ne '' || $mark eq '"' || $mark eq "'") {
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
					
					if (defined $left) {
						$left_trimmed = 1;
						
						if ($left ne '') {
							push @result, $left;
							$left_trimmed_index = $#result;
						} else {
							$left_trimmed_index = undef;
						}
					}
					
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
					
					if ($escape) {
						push @result, qq{EJS.$escape(};
						$escaping = 1;
					}
					
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
						if ($escaping) {
							push @result, qq{));};
						} else {
							push @result, qq{);};
						}
						
						$escaping = 0;
						$interpolating = 0;
						
						if (defined $right && $right ne '') {
							push @result, qq{print("$right};
							$printing = 1;
						}
					} else {
						if (defined $right) {
							if ($left_trimmed) {
								push @result, $right if $right ne '';
								$right_trimmed = 1;
							} elsif ($right ne '') {
								push @result, qq{print("$right};
								$printing = 1;
							}
						} else {
							if ($left_trimmed && defined $left_trimmed_index) {
								my $spaces = $result[$left_trimmed_index];
								$result[$left_trimmed_index] = qq{print("$spaces");};
							}
						}
					}
					
					$left_trimmed = 0;
					$state = TEXT;
				} else {
					push @result, $mark;
				}
			}
		}
	}
	
	close $in if $in_close;
	
	push @result, qq{");} if $printing;
	
	if ($interpolating) {
		if ($escaping) {
			push @result, qq{));};
		} else {
			push @result, qq{);};
		}
	}
	
	my ($out, $out_close) = EJS::Template::IO->output($output);
	print $out $_ foreach @result;
	close $out if $out_close;
	
	return 1;
}

1;
