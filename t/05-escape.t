#!perl -T

use Test::More tests => 5;

use Carp qw(croak);
use EJS::Template;
use Test::Builder;

sub ejs_ok {
	my ($source, $escape, $variables, $expected) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $output;
	EJS::Template->new(escape => $escape)->process(\$source, $variables, \$output) or croak $@;
	is($output, $expected, "source: [$source]");
}

ejs_ok(<<EJS, 'html', undef, <<OUT);
<span><%= "x > y" %></span>
EJS
<span>x &gt; y</span>
OUT

ejs_ok(<<EJS, 'html', undef, <<OUT);
<span title='<%= "'x > y'" %>'>test</span>
EJS
<span title='&#39;x &gt; y&#39;'>test</span>
OUT

ejs_ok(<<EJS, 'html', {url => 'http://example.com?test'}, <<OUT);
<a href="?redirect=<%:uri= url %>">Redirect</a>
EJS
<a href="?redirect=http%3A%2F%2Fexample.com%3Ftest">Redirect</a>
OUT

ejs_ok(<<EJS, 'html', {message => '<p>Hello World</p>'}, <<OUT);
<div>
  <%:raw= message %>
</div>
EJS
<div>
  <p>Hello World</p>
</div>
OUT

ejs_ok(<<EJS, 'html', {message => 'Hello "World"'}, <<OUT);
<script>
var message = "<%:quote= message %>";
</script>
EJS
<script>
var message = "Hello \\"World\\"";
</script>
OUT
