#!perl -T

use Test::More tests => 2;

use Template::EJS;

for my $engine (qw(JavaScript::V8 JE)) {
	my $source = '<%= a.b.c.d %> <%= a.b.e() %>';
	my $variables = {a => {b => {c => {d => 'Hello'}, e => sub {'World'}}}};
	my $output;
	Template::EJS->new(engine => 'JE')->process(\$source, $variables, \$output);
	is($output, 'Hello World');
	# TODO: Skip test if the particular engine is not installed.
}
