#!perl -T

use Test::More tests => 7;

use EJS::Template;
use Test::Builder;

sub process_is {
	my ($source, $variables, $expected) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $output;
	EJS::Template->process(\$source, $variables, \$output) or die $@;
	is($output, $expected, "source: [$source]");
}

process_is('', undef, '');
process_is('test', undef, 'test');
process_is('<%=name%>', {name => 'test'}, 'test');
process_is('<% print(name); %>', {name => 'test'}, 'test');

process_is('<%= foo() + bar() %>', {
	foo => sub {return 'FOO'},
	bar => sub {return 'BAR'},
}, 'FOOBAR');

process_is(<<__EJS__, undef, <<__OUT__);
Begin
<% for (var i = 0; i < 6; i++) { %>
  <% if (i % 2 == 1) { %>
    * i = <%=i%>
  <% } %>
<% } %>
End
__EJS__
Begin
    * i = 1
    * i = 3
    * i = 5
End
__OUT__

process_is(<<__EJS__, undef, <<__OUT__);
<table>
  <% for (var r = 1; r <= 3; r++) { %>
    <tr>
      <% for (var c = 1; c <= 3; c++) { %>
        <td><%= r, ' x ', c, ' = ', r * c %></td>
      <% } %>
    </tr>
  <% } %>
</table>
__EJS__
<table>
    <tr>
        <td>1 x 1 = 1</td>
        <td>1 x 2 = 2</td>
        <td>1 x 3 = 3</td>
    </tr>
    <tr>
        <td>2 x 1 = 2</td>
        <td>2 x 2 = 4</td>
        <td>2 x 3 = 6</td>
    </tr>
    <tr>
        <td>3 x 1 = 3</td>
        <td>3 x 2 = 6</td>
        <td>3 x 3 = 9</td>
    </tr>
</table>
__OUT__
