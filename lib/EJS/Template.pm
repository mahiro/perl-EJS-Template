use 5.006;
use strict;
use warnings;

package EJS::Template;

use EJS::Template::Executor;
use EJS::Template::Parser;

=head1 NAME

EJS::Template - EJS (Embedded JavaScript) template engine

=head1 VERSION

Version 0.03

=cut

our $VERSION = '0.03';

=head1 SYNOPSIS

Anything inside the tag C<< <%...%> >> is executed as JavaScript code,
and anything inside the tag C<< <%=...%> >> is replaced by the evaluated value.

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

A simpler way to apply a template without an external file looks something like this:

    my $text = EJS::Template->apply('Hello, <%= name %>!', {name => 'World'});

Within C<< <%...%> >>, it is also possible to call C<print()> function:

    # EJS
    <%
      for (var i = 0; i < 3; i++) {
        print("i = ", i, "\n");
      }
    %>
    
    # Output
    i = 0
    i = 1
    i = 2

C<EJS::Template> supports auto-escaping that minimizes the risk of forgetting
HTML-escape every individual variable. (See L</Auto-escaping> for more details.)

    # Perl
    my $ejs = EJS::Template->new(escape => 'html'); # Set default escape type
    
    $ejs->process('sample.ejs', {
        address => '"Foo Bar" <foo.bar@example.com>', # to be escaped
        message => '<p>Hello, <i>World</i>!<p>', # not to be escaped
    });
    
    # EJS ('<%=' escapes the value, while '<%:raw=' does *not*)
    <h2><%= address %></h2>
    <div>
      <%:raw= message %>
    </div>
    
    # Output
    <h2>&quot;Foo Bar&quot; &lt;foo.bar@example.com&gt;</h2>
    <div>
      <p>Hello, <i>World</i>!</p>
    </div>

Extra white spaces around C<< <% >> and C<< %> >> are appropriately trimmed
so that the result output will look fairly clean intuitively.
See L</Trimming white spaces> for more details.

    <ul>
    v-- Indent would make unnecessary space in the output.
      <% for (...) { %>
        <li>...</li>   ^-- This line break would make an extra empty line where <%...%> is gone.
      <% } %>
    </ul>

=head1 DESCRIPTION

EJS is a template engine with JavaScript code embedded.

It can be used as a general-purpose template engine to generate text documents,
configurations, source code, etc.
For web applications, EJS can be used as a template of HTML.

EJS is suitable when template authors should not embed potentially dangerous
code such as file system manipulations, command executions, and database
connections, while at the same time, they can still utilize JavaScript as a
well-established programming language.

Especially for web applications, there are several different approaches to
implement similar EJS functionality, such as parsing EJS and/or executing
JavaScript on the server side or the browser side.
This module implements both parsing and executing on the server side from that
perspective.

=head1 METHODS

=head2 new

Creates an C<EJS::Template> object with configuration name/value pairs.

Usage:

   my $ejs = EJS::Template->new( [NAME => VALUE, ...] );

Available configurations are as below:

=over 4

=item * escape => ESCAPE_TYPE

Sets the default escape type for all the interpolation tags (C<< <%=...%> >>).

Possible values are: C<'raw'> (default), C<'html'>, C<'xml'>, C<'uri'>, and
C<'quote'>. See L</Auto-escaping> for more details.

=item * engine => ENGINE_CLASS

Sets the JavaScript engine class.
See L</JavaScript engines> for more details.

=back

=cut

sub new {
    my ($class, %config) = @_;
    my $self = {map {$_ => $config{$_}} qw(engine escape)};
    return bless $self, $class;
}

=head2 process

Usage:

    # Simple
    EJS::Template->process([INPUT [, VARIABLES [, OUTPUT ] ] ]);
    
    # Custom
    my $ejs = EJS::Template->new(...);
    $ejs->process([INPUT [, VARIABLES [, OUTPUT ] ] ]);

INPUT is the EJS source (default: STDIN).
It can be either a string (as a file path), a string ref (as a source text), or
an open file handle.

VARIABLES is a hash ref that maps variable names to values, which are made
available in the JavaScript code (default: an empty hash).
The values of VARIABLES can be a nested structure of hashes, arrays, strings,
numbers, and/or subroutine refs.
A function (subroutine) named C<print> is automatically defined, unless
overwritten in VARIABLES.

OUTPUT is where the final result is written out (default: STDOUT).
It can be either a string (as a file path), a string ref (as a source text), or
an open file handle.

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
    
    eval {
        my $parsed;
        $self->parse($input, \$parsed);
        $self->execute(\$parsed, $variables, $output);
    };
    
    die $@ if $@;
    return 1;
}

=head2 apply

Usage:

    EJS::Template->apply(INPUT_TEXT [, VARIABLES])

Example:

    my $text = EJS::Template->apply('Hello <%= name %>', {name => 'World'});
    print $text;

This method serves as a syntax sugar for the C<process()> method, focused on
text-to-text conversion.

=cut

sub apply {
    my ($self, $input, $variables) = @_;
    my $output;
    
    eval {
        $self->process(\$input, $variables, \$output);
    };
    
    die $@ if $@;
    return $output;
}

=head2 parse

Usage:

    EJS::Template->parse([INPUT [, OUTPUT ] ]);

INPUT is the EJS source, and OUTPUT is a JavaScript code,
which can then be executed to generate the final output.
(See C<execute()> method.)

The parsed code can be stored in a file as an intermediate code,
and can be executed at a later time.

The semantics of INPUT and OUTPUT types are similar to C<process()>.

=cut

sub parse {
    my ($self, $input, $parsed_output) = @_;
    
    eval {
        my $parser = EJS::Template::Parser->new($self);
        $parser->parse($input, $parsed_output);
    };
    
    die $@ if $@;
    return 1;
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
    
    eval {
        my $executor = EJS::Template::Executor->new($self);
        $executor->execute($parsed_input, $variables, $output);
    };
    
    die $@ if $@;
    return 1;
}


=head1 DETAILS

=head2 Auto-escaping

C<EJS::Template> supports auto-escaping if it is configured via the C<new()>
method.

    EJS::Template->new(escape => 'html')->process(...);

If the C<escape> is set to 'html', all the texts inside C<< <%=...%> >> are
HTML-escaped automatically.

    # Input
    <% var text = "x < y < z"; %>
    <span><%= text %></span>
    
    # Output
    <span>x &lt; y &lt; z</span>

In case a raw HTML needs to be embedded without escaping, it can be annotated like this:

    <%:raw= text %>

In addition, the following escape types are available in a similar manner
(both for the C<< escape => >> config or in each individual tag C<< <%=...%> >>):

=over 4

=item * html

    <span><%:html= plainText %></span>

=item * xml

    <xml><%:xml= plainText %></xml>

=item * uri

    <a href="http://example.com?name=<%:uri= value %>">Link</a>

=item * quote

    <script type="text/javascript">
      var text = "<%:quote= value %>";
    </script>

=item * raw

    <div><%:raw= htmlText %></div>

=back

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

The trimming occurs only when C<< <% >> is at the beginning of a line with any indent
spaces, and its corresponding C<< %> >> is at the end of the same or another line
with any trailing spaces.

When the above trimming condition is met,
any white spaces to the left of C<< <% >> (not including any line breaks) and
any white spaces to the right of C<< %> >> (including the line break) are trimmed.

=head2 Data conversion between Perl and EJS

In the current version, the data conversion is limited to basic types
(strings, numbers, hashes, arrays, and functions), although arbitrarily nested
structures are allowed.

    EJS::Template->process('sample.ejs', {
        name => 'World',
        hash => {foo => 123, bar => 456, baz => [7, 8, 9]},
        array => ['a'..'z'],
        square => sub {
            my $value = shift;
            return $value * $value;
        }
    });

If a blessed reference in Perl is passed to EJS, it is converted into a basic type.

If a Perl subroutine is invoked from inside EJS, the types of the arguments depend
on the JavaScript engine that is in use internally (See L</JavaScript engines>).

    # Perl
    sub printRefs {
        print(ref($_) || '(scalar)', "\n") foreach @_;
    }
    
    EJS::Template->process(\<<END, {printRefs => \&printRefs});
    <%
      printRefs(
        'str',
        123,
        [4, 5, 6],
        {x: 7, y: 8},
        function () {return 90}
      );
    %>
    END
    
    # Output with JavaScript::V8
    (scalar)
    (scalar)
    ARRAY
    HASH
    CODE
    
    # Output with JE
    JE::String
    JE::Number
    JE::Object::Array
    JE::Object
    JE::Object::Function

For portability, it is recommended to keep data types as simple as possible
when data is passed between Perl and EJS.

=head2 JavaScript engines

C<EJS::Template> automatically determines the available JavaScript engine from
the below:

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

=item * Template Toolkit (a.k.a. TT)

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
