#!perl -T

use Test::More tests => 3;

use EJS::Template;
use EJS::Template::JSEngine;

for my $engine (qw(JavaScript::V8 JavaScript::SpiderMonkey JE)) {
	eval {EJS::Template::JSEngine->create($engine)};
	
	SKIP: {
		skip "$engine is not installed", 1 if $@;
		my $source = '<%= a.b.c.d %> <%= a.b.e() %>';
		my $variables = {a => {b => {c => {d => 'Hello'}, e => sub {'World'}}}};
		my $output;
		EJS::Template->new(engine => $engine)->process(\$source, $variables, \$output);
		is($output, 'Hello World');
	}
}
