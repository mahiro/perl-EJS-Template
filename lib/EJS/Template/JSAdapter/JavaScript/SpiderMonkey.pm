use 5.006;
use strict;
use warnings;

=head1 NAME

EJS::Template::JSAdapter::JavaScript::SpiderMonkey

=cut

package EJS::Template::JSAdapter::JavaScript::SpiderMonkey;
use base 'EJS::Template::JSAdapter';

use EJS::Template::Util qw(clean_text_ref);
use Scalar::Util qw(reftype);

our $ENCODE_UTF8   = 0;
our $SANITIZE_UTF8 = 0;
our $FORCE_UNTAINT = 0;

=head1 Methods

=head2 new

Creates an adapter object.

=cut

sub new {
    my ($class) = @_;
    eval 'use JavaScript::SpiderMonkey';
    my $context = JavaScript::SpiderMonkey->new;
    $context->init();
    return bless {context => $context}, $class;
}

=head2 bind

Implements the bind method.

=cut

sub bind {
    my ($self, $variables) = @_;
    my $context = $self->context;
    
    my $assign_value;
    my $assign_hash;
    my $assign_array;
    
    $assign_value = sub {
        my ($obj, $parent_path, $name, $source_ref, $in_array) = @_;
        
        my $reftype = reftype $$source_ref;
        my $path = $parent_path ne '' ? "$parent_path.$name" : $name;
        
        if ($reftype) {
            if ($reftype eq 'HASH') {
                my $new_obj = $context->object_by_path($path);
                $assign_hash->($new_obj, $$source_ref, $path);
            } elsif ($reftype eq 'ARRAY') {
                my $new_obj = $context->array_by_path($path);
                $assign_array->($new_obj, $$source_ref, $path);
            } elsif ($reftype eq 'CODE') {
                $context->function_set($name, $$source_ref, $obj);
            } elsif ($reftype eq 'SCALAR') {
                $assign_array->($obj, $parent_path, $name, $$source_ref, $in_array);
            } else {
                # ignore?
            }
        } else {
            my $text_ref = clean_text_ref($source_ref, $ENCODE_UTF8, $SANITIZE_UTF8, $FORCE_UNTAINT);
            
            if ($in_array) {
                $context->array_set_element($obj, $name, $$text_ref);
            } else {
                if ($parent_path) {
                    $context->property_by_path($path, $$text_ref);
                } else {
                    JavaScript::SpiderMonkey::JS_DefineProperty(
                        $context->{context}, $obj, $name, $$text_ref);
                }
            }
        }
    };
    
    $assign_hash = sub {
        my ($obj, $source, $parent_path) = @_;
        
        for my $name (keys %$source) {
            $assign_value->($obj, $parent_path, $name, \$source->{$name});
        }
    };
    
    $assign_array = sub {
        my ($obj, $source, $parent_path) = @_;
        my $len = scalar(@$source);
        
        for (my $i = 0; $i < $len; $i++) {
            $assign_value->($obj, $parent_path, $i, \$source->[$i], 1);
        }
    };
    
    $assign_hash->($context->{global_object}, $variables, '');
    return $context;
}

sub DESTROY {
    my ($self) = @_;
    $self->{context}->destroy();
    delete $self->{context};
}

=head1 SEE ALSO

=over 4

=item * L<EJS::Template>

=item * L<EJS::Template::JSAdapter>

=item * L<JavaScript::SpiderMonkey>

=back

=cut

1;
