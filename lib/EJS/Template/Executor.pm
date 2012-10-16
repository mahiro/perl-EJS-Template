use 5.006;
use strict;
use warnings;

package EJS::Template::Executor;

use EJS::Template::IO;
use Scalar::Util qw(reftype);

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
	
	my $engine = $self->_get_engine();
	my ($out, $out_close) = EJS::Template::IO->output($output);
	my $ret;
	
	eval {
		my $context = $self->_create_context($engine, $variables, $out);
		my ($in, $in_close) = EJS::Template::IO->input($input);
		
		$ret = eval {
			local $/;
			$context->eval(<$in>) or die $@;
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

my $default_engine;

sub _get_engine {
	my ($self) = @_;
	
	if (my $engine = $self->{config}{engine}) {
		eval "use $engine";
		die $@ if $@;
		return $engine;
	} elsif (defined $default_engine) {
		return $default_engine if $default_engine ne '';
	} else {
		my $engines = [qw(JavaScript::V8 JE)];
		
		for my $engine (@$engines) {
			eval "use $engine";
			next if $@;
			return $default_engine = $engine;
		}
		
		$default_engine = '';
	}
	
	die "No JavaScript engine modules are found. Consider to install JavaScript::V8";
}

sub _create_context {
	my ($self, $engine, $variables, $out) = @_;
	$variables ||= {};
	
	my $context;
	
	if ($engine eq 'JavaScript::V8') {
		$context = JavaScript::V8::Context->new();
		$context->bind(print => sub { print $out @_ });
		
		for my $name (keys %$variables) {
			$context->bind($name, $variables->{$name});
		}
	} elsif ($engine eq 'JE') {
		$context = JE->new;
		$context->new_function(print => sub { print $out @_ });
		
		my $assign;
		
		$assign = sub {
			my ($target, $source) = @_;
			
			for my $name (keys %$source) {
				my $ref = reftype $source->{$name};
				
				if ($ref && $ref eq 'HASH') {
					$assign->($target->{$name} = {}, $source->{$name});
				} else {
					$target->{$name} = $source->{$name};
				}
			}
		};
		
		$assign->($context, $variables);
	}
	
	$context or die "JavaScript engine '$engine' is not supported";
	return $context;
}

1;
