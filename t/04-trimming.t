#!perl -T

use Test::More tests => 7;

use Carp qw(croak);
use EJS::Template;
use Test::Builder;

sub ejs_ok {
	my ($source, $variables, $expected) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $output;
	EJS::Template->process(\$source, $variables, \$output) or croak $@;
	is($output, $expected, "source: [$source]");
}

ejs_ok(<<EJS, undef, <<OUT);
--begin--
  <% var x; %>\t
--end--
EJS
--begin--
--end--
OUT

ejs_ok(<<EJS, undef, <<OUT);
--begin--
  <%
    var x;
    var y;
  %>\t
--end--
EJS
--begin--
--end--
OUT

ejs_ok(<<EJS, undef, <<OUT);
--begin--
  <% if (true) { %>text<% } %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT

ejs_ok(<<EJS, undef, <<OUT);
--begin--
  <%
    var x = 0;
    if (x != 1 && x != 2) {
      %>text<% } %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT

ejs_ok(<<EJS, undef, <<OUT);
--begin--
  <% print("   text\\t\\t\\n"); %>\t
--end--
EJS
--begin--
   text\t\t
--end--
OUT

ejs_ok(<<EJS, undef, <<OUT);
--begin--
  <%= "text" %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT

ejs_ok(<<EJS, undef, <<OUT);
--begin--
  <%=
    "text"
  %>\t
--end--
EJS
--begin--
  text\t
--end--
OUT
