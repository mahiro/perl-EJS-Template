use 5.006;
use strict;
use warnings;

package EJS::Template;

use EJS::Template::Executor;
use EJS::Template::Parser;

=head1 NAME

EJS::Template - EJS (Embedded JavaScript) template engine

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    # Perl
    use EJS::Template;
    EJS::Template->process('source.ejs', {name => 'World'});
    
    # EJS ('source.ejs')
    <% for (var i = 0; i < 3; i++) { %>
    Hello, <%= name %>!
    <% } %>
    
    # Output
    Hello, World!
    Hello, World!
    Hello, World!

=head1 DESCRIPTION

EJS is a template engine with JavaScript code embedded.

It can be used as a general-purpose template engine to generate text documents,
configurations, source code, etc.
For web applications, EJS can be used as a template of HTML.

EJS is suitable when template authors should not embed potentially dangerous
code such as file system manipulations, command executions, and database connections,
while at the same time, they can still utilize JavaScript as a well-established
programming language.

=head1 METHODS

=head2 new

Creates a C<EJS::Template> object with configuration name/value pairs.

Usage:

   my $ejs = EJS::Template->new( [NAME => VALUE, ...] );

=cut

sub new {
	my ($class, %config) = @_;
	
	return bless {
		engine => $config{engine} || 'JavaScript::V8',
		escape => $config{escape} || '',
	}, $class;
}

=head2 process

Usage:

    # Simple
    EJS::Template->process([INPUT [, VARIABLES [, OUTPUT ] ] ]);
    
    # Custom
    my $ejs = EJS::Template->new(...);
    $ejs->process([INPUT [, VARIABLES [, OUTPUT ] ] ]);

INPUT is the EJS source (default: STDIN).

VARIABLES is a hash ref that maps variable names to values bound to JavaScript
(default: an empty hash).
The values of VARIABLES can be a nested structure of hashes, arrays, strings,
numbers, and/or subroutine refs.

OUTPUT is where the final result is written out (default: STDOUT).

See the examples below for possible types of INPUT and OUTPUT.

Examples:

    # Reads the file 'source.ejs' and prints the result to STDOUT
    EJS::Template->process('source.ejs', {name => 'World'});

    # Reads STDIN as the EJS source and writes the result to the file 'output.txt'
    EJS::Template->process(\*STDIN, {name => 'World'}, 'output.txt');

    # Parses the EJS source text and stores the result to the variable $out
    my $out;
    EJS::Template->process(\'Hello <%=name%>', {name => 'World'}, \$out);

=cut

sub process {
	my ($self, $input, $variables, $output) = @_;
	my $parsed;
	$self->parse($input, \$parsed);
	$self->execute(\$parsed, $variables, $output);
}

=head2 apply

Usage:

    EJS::Template->apply(INPUT_TEXT [, VARIABLES]) => OUTPUT_TEXT

Example:

    my $text = EJS::Template->apply('Hello <%= name %>', {name => 'World'});
    print $text;

This method serves as a syntax sugar for the C<process()> method, focused on
text-to-text conversion.

=cut

sub apply {
	my ($self, $input, $variables) = @_;
	my $output;
	$self->process(\$input, $variables, \$output);
	return $output;
}

=head2 parse

Usage:

    EJS::Template->parse([INPUT [, OUTPUT ] ]);

INPUT is the EJS source, and OUTPUT is a JavaScript code,
which can then be executed to generate the final output (see C<execute()> method).

The parsed code can be stored in a file as an intermediate code,
and can be executed at a later time.

The semantics of INPUT and OUTPUT types are similar to C<process()>.

=cut

sub parse {
	my ($self, $input, $parsed_output) = @_;
	my $parser = EJS::Template::Parser->new($self);
	$parser->parse($input, $parsed_output);
}

=head2 execute

Usage:

    EJS::Template->execute([INPUT [, VARIABLES [, OUTPUT ] ] ]);

INPUT is a JavaScript code generated by C<parse()> method,
and OUTPUT is the final result.

The semantics of INPUT and OUTPUT types are similar to C<process()>.

=cut

sub execute {
	my ($self, $parsed_input, $variables, $output) = @_;
	my $executor = EJS::Template::Executor->new($self);
	$executor->execute($parsed_input, $variables, $output);
}

=head1 DETAILS

=head2 JavaScript Engines

C<EJS::Template> automatically determines the available JavaScript engine from the below:

=over 4

=item * V8 (same engine as Google Chrome):

L<JavaScript::V8> (default for C<EJS::Template>)

=item * SpiderMonkey (same engine as Mozilla Firefox):

L<JavaScript>

L<JavaScript::SpiderMonkey>

=item * Pure Perl implementation

L<JE>

=back

It is also possible to specify a particular engine:

   EJS::Template->new(engine => 'JE')->process(...);

=head2 Trimming white spaces

C<EJS::Template> trims appropriate white spaces around C<< <%...%> >>
(but not around C<< <%=...%> >>).

It helps the template author generate a fairly well-formatted output:

EJS:

    <ul>
      <% for (var i = 1; i <= 5; i++) { %>
        <li>
          <% if (i % 2 == 1) { %>
            <%=i%> x <%=i%> = <%=i * i%>
          <% } %>
        </li>
      <% } %>
    </ul>

Output:

    <ul>
        <li>
            1 x 1 = 1
        </li>
        <li>
            3 x 3 = 9
        </li>
        <li>
            5 x 5 = 25
        </li>
    </ul>

Note: If no white spaces were trimmed, the result output would look much more ugly,
because of extra indent spaces and line breaks around C<< <% for (...) %> >>,
C<< <% if (...) %> >>, etc.

=head1 AUTHOR

Mahiro Ando, C<< <mahiro at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ejs-template at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=EJS-Template>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc EJS::Template

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=EJS-Template>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/EJS-Template>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/EJS-Template>

=item * Search CPAN

L<http://search.cpan.org/dist/EJS-Template/>

=back

=head1 ACKNOWLEDGEMENTS

Many thanks to authors of JavaScript engines for making them available,
and to authors of those in the SEE ALSO section for giving me
ideas and inspirations.

=head1 SEE ALSO

=over 4

=item * Template::Toolkit (a.k.a. TT)

L<Template::Toolkit>

=item * JavaScript Template engine based on TT2

L<Jemplate>

=item * Browser-side EJS

L<http://embeddedjs.com/>

L<https://github.com/visionmedia/ejs>

=item * EJS for Ruby:

L<https://github.com/sstephenson/ruby-ejs>

=back

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mahiro Ando.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1; # End of EJS::Template
