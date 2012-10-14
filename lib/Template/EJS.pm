use 5.006;
use strict;
use warnings;

package Template::EJS;

use Template::EJS::Executor;
use Template::EJS::Parser;

=head1 NAME

Template::EJS - EJS (Embedded JavaScript) template engine

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # Perl
    use Template::EJS;
    Template::EJS->process('source.ejs', {name => 'World'});
    
    # source.ejs
    <% for (var i = 0; i < 3; i++) { %>
    Hello, <%= name %>!
    <% } %>
    
    # Output
    Hello, World!
    Hello, World!
    Hello, World!

=head1 METHODS

=head2 new

Creates a C<Template::EJS> object with configuration name/value pairs.

Usage:

   my $ejs = Template::EJS->new( [NAME => VALUE, ...] );

=cut

sub new {
	my ($class, %config) = @_;
	
	return bless {
		engine => $config{engine} || 'JavaScript::V8',
	}, $class;
}

=head2 process

Usage:

    # Simple
    Template::EJS->process(INPUT [, VARIABLES [, OUTPUT ] ] );
    
    # Custom
    my $ejs = Template::EJS->new(...);
    $ejs->process(INPUT [, VARIABLES [, OUTPUT ] ] );

Examples:

    # Reads the file 'source.ejs' and prints the result to STDOUT
    Template::EJS->process('source.ejs', {name => 'value'});

    # Reads STDIN as the EJS source and writes the result to the file 'output.txt'
    Template::EJS->process(\*STDIN, {name => 'value'}, 'output.txt');

    # Parses the EJS source text and stores the result to the variable $out
    my $out;
    Template::EJS->process(\'Hello <%=name%>', {name => 'World'}, \$out);

=cut

sub process {
	my ($self, $input, $variables, $output) = @_;
	my $parsed;
	$self->parse($input, \$parsed);
	$self->execute(\$parsed, $variables, $output);
}

=head2 parse

=cut

sub parse {
	my ($self, $input, $parsed_output) = @_;
	my $parser = Template::EJS::Parser->new($self);
	$parser->parse($input, $parsed_output);
}

=head2 execute

=cut

sub execute {
	my ($self, $parsed_input, $variables, $output) = @_;
	my $executor = Template::EJS::Executor->new($self);
	$executor->execute($parsed_input, $variables, $output);
}

=head1 JavaScript Engines

C<Template::EJS> automatically determines the available JavaScript engine from the below:

=over 4

=item * V8 (same engine as Google Chrome):

L<JavaScript::V8> (default for C<Template::EJS>)

=item * SpiderMonkey (same engine as Mozilla Firefox):

L<JavaScript>

L<JavaScript::SpiderMonkey>

=item * Pure Perl implementation

L<JE>

=back

=head1 See Also

=over 4

=item * JavaScript Template engine based on TT2

L<Jemplate>

=item * Browser-side EJS

L<http://embeddedjs.com/>

L<https://github.com/visionmedia/ejs>

=item * EJS for Ruby:

L<https://github.com/sstephenson/ruby-ejs>

=back

=head1 AUTHOR

Mahiro Ando, C<< <mahiro at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-template-ejs at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Template-EJS>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Template::EJS

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Template-EJS>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Template-EJS>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Template-EJS>

=item * Search CPAN

L<http://search.cpan.org/dist/Template-EJS/>

=back

=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mahiro Ando.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of Template::EJS
