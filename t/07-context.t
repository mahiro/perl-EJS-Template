#!perl -T
use strict;
use warnings;

use Test::More tests => 3;

use EJS::Template;
use IO::Scalar;

my $v1 = {
    customFunc => sub {
        my $context = EJS::Template->context;
        $context->bind({
            y => 4,
            z => 5,
        });
        my $result = $context->eval("(function (i, j, k) {return i * j * k})(x, y, z)");
        $context->print("x * y * z = ", $result, "\n");
    }
};

my $output = EJS::Template->apply(<<EJS, $v1);
<%
var x = 2;
var y = 3;
customFunc();
%>
x = <%=x%>
y = <%=y%>
z = <%=z%>
EJS

is $output, <<OUT;
x * y * z = 40
x = 2
y = 4
z = 5
OUT

my $t1 = EJS::Template->new();
my $t2 = EJS::Template->new();

my $v2 = {
    set_t1 => sub {
        my ($name, $value) = @_;
        $t1->bind({$name => $value});
        my $t = EJS::Template->context;
        $t->print("set_t1: $name = $value\n");
    },
    set_t2 => sub {
        my ($name, $value) = @_;
        $t2->bind({$name => $value});
        my $t = EJS::Template->context;
        $t->print("set_t2: $name = $value\n");
    },
};

my $result1;
my $output1 = IO::Scalar->new(\$result1);
my $result2;
my $output2 = IO::Scalar->new(\$result2);

$t1->process(\'<% var foo %>', $v2, $output1);
$t2->process(\'<% var bar %>', $v2, $output2);
$t1->process(\'<% set_t2("bar", 2) %>', undef, $output1);
$t2->process(\'<% set_t1("foo", bar * 3) %>', undef, $output2);
$t1->process(\'<% set_t2("bar", foo * 4) %>', undef, $output1);
$t2->process(\'<% set_t1("foo", bar * 5) %>', undef, $output2);
$t1->process(\"result: foo = <%=foo%>\n", undef, $output1);
$t2->process(\"result: bar = <%=bar%>\n", undef, $output2);

is $result1, <<OUT;
set_t2: bar = 2
set_t2: bar = 24
result: foo = 120
OUT

is $result2, <<OUT;
set_t1: foo = 6
set_t1: foo = 120
result: bar = 24
OUT
