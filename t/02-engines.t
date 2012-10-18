#!perl -T

use EJS::Template;
use EJS::Template::JSEngine;

my $tests; BEGIN {$tests = 21}

use Test::Builder;
use Test::More tests => $tests * scalar(@EJS::Template::JSEngine::SupportedEngines);

sub ejs_is {
	my ($source, $expected, $variables, $engine) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	
	my $output;
	
	eval {
		EJS::Template->new(engine => $engine)->process(\$source, $variables, \$output)
	};
	
	if ($@) {
		fail "$engine: $source: $@";
	} else {
		is($output, $expected, "$engine: $source");
	}
}

for my $engine (@EJS::Template::JSEngine::SupportedEngines) {
	eval {EJS::Template::JSEngine->create($engine)};
	
	SKIP: {
		skip "$engine is not installed", $tests if $@;
		
		my $variables = {
			str => 'A',
			num => 1,
			func => sub {'I'},
			hash => {
				str => 'B',
				num => 2,
				func => sub {'II'},
				hash => {
					str => 'D',
					num => 4,
					func => sub {'IV'},
				},
				array => [
					'E',
					5,
					sub {'V'},
				],
			},
			array => [
				'C',
				3,
				sub {'III'},
				{
					str => 'F',
					num => 6,
					func => sub {'VI'},
				},
				[
					'G',
					7,
					sub {'VII'},
				],
			],
		};
		
		ejs_is('<%= str %>', 'A', $variables, $engine);
		ejs_is('<%= num %>', '1', $variables, $engine);
		ejs_is('<%= func() %>', 'I', $variables, $engine);
		
		ejs_is('<%= hash.str %>', 'B', $variables, $engine);
		ejs_is('<%= hash.num %>', '2', $variables, $engine);
		ejs_is('<%= hash.func() %>', 'II', $variables, $engine);
		
		ejs_is('<%= array[0] %>', 'C', $variables, $engine);
		ejs_is('<%= array[1] %>', '3', $variables, $engine);
		ejs_is('<%= array[2]() %>', 'III', $variables, $engine);
		
		ejs_is('<%= hash.hash.str %>', 'D', $variables, $engine);
		ejs_is('<%= hash.hash.num %>', '4', $variables, $engine);
		ejs_is('<%= hash.hash.func() %>', 'IV', $variables, $engine);
		
		ejs_is('<%= hash.array[0] %>', 'E', $variables, $engine);
		ejs_is('<%= hash.array[1] %>', '5', $variables, $engine);
		ejs_is('<%= hash.array[2]() %>', 'V', $variables, $engine);
		
		ejs_is('<%= array[3].str %>', 'F', $variables, $engine);
		ejs_is('<%= array[3].num %>', '6', $variables, $engine);
		ejs_is('<%= array[3].func() %>', 'VI', $variables, $engine);
		
		ejs_is('<%= array[4][0] %>', 'G', $variables, $engine);
		ejs_is('<%= array[4][1] %>', '7', $variables, $engine);
		ejs_is('<%= array[4][2]() %>', 'VII', $variables, $engine);
	}
}
