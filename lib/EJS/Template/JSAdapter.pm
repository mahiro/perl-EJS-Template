use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::JSAdapter - JavaScript engine adapter for EJS::Template

=cut

package EJS::Template::JSAdapter;

=head1 Variables

=head2 @SUPPORTED_ENGINES

Supported JavaScript engine classes

=over 4

=item * L<JavaScript::V8>

=item * L<JavaScript>

=item * L<JavaScript::SpiderMonkey>

=item * L<JE>

=back

=cut

our @SUPPORTED_ENGINES = qw(
    JavaScript::V8
    JavaScript
    JavaScript::SpiderMonkey
    JE
);

my $default_engine;

=head1 Methods

=head2 create

Instantiates a JavaScript engine adapter object.

    my $engine = EJS::Template::JSAdapter->create();

If no argument is passed, an engine is selected from the available ones.

An explicit engine can also be specified. E.g.

    my $je_engine = EJS::Template::JSAdapter->create('JE');
    my $v8_engine = EJS::Template::JSAdapter->create('JavaScript::V8');

=cut

sub create {
    my ($class, $engine) = @_;
    
    if ($engine) {
        my $engine_class = $class.'::'.$engine;
        eval "require $engine_class";
        
        if ($@) {
            $engine_class = $engine;
            eval "require $engine_class";
            die $@ if $@;
        }
        
        return $engine_class->new();
    } elsif ($default_engine) {
        return $default_engine->new();
    } else {
        for my $candidate (@SUPPORTED_ENGINES) {
#            eval "require $candidate";
#            next if $@;
            
            my $engine_class = $class.'::'.$candidate;
            eval "require $engine_class";
            next if $@;
            
            $default_engine = $engine_class;
            return $engine_class->new();
        }
        
        die "No JavaScript engine modules are found. ".
            "Consider to install JavaScript::V8";
    }
}

=head2 new

Creates an adapter object.

This method should be overridden, and a property named 'context' is expected to be set up.

    package Some::Extended::JSAdapter;
    use base 'EJS::Template::JSAdapter';
    
    sub new {
        my ($class) = @_;
        my $context = Some::Underlying::JavaScript::Context->new();
        return bless {context => $context}, $class;
    }

=cut

sub new {
    my ($class) = @_;
    return bless {context => undef}, $class;
}

=head2 context

Retrieves the underlying context object.

=cut

sub context {
    my ($self) = @_;
    return $self->{context};
}

=head2 bind

Binds variable mapping to JavaScript objects.

This method should be overridden in a way that it can be invoked like this:

    $engine->bind({
        varname1 => $object1,
        funcname2 => sub {...},
        ...
    });

=cut

sub bind {
    my ($self, $variables) = @_;
    
    if (my $context = $self->context) {
        if ($context->can('bind')) {
            return $context->bind($variables);
        }
    }
}

=head2 eval

Evaluates a JavaScript code.

This method should be overridden in a way that it can be invoked like this:

    $engine->eval('print("ok\n")');

=cut

sub eval {
    my ($self) = @_;
    
    if (my $context = $self->context) {
        if ($context->can('eval')) {
            return $context->eval($_[1]);
        }
    }
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=back

=cut

1;
