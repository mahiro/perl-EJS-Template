#!perl -T

use EJS::Template;
use EJS::Template::JSEngine;

use Test::More tests => scalar(@EJS::Template::JSEngine::SupportedEngines);

for my $engine (@EJS::Template::JSEngine::SupportedEngines) {
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
