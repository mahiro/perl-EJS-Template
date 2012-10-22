#!perl -T
use strict;
use warnings;

my $tests; BEGIN {$tests = 21}
use EJS::Template::JSEngine;
use Test::More tests => $tests * scalar(@EJS::Template::JSEngine::SupportedEngines);

use EJS::Template::Test;

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
		
		my $config = {engine => $engine};
		
		ejs_test('<%= str %>', 'A', $variables, $config);
		ejs_test('<%= num %>', '1', $variables, $config);
		ejs_test('<%= func() %>', 'I', $variables, $config);
		
		ejs_test('<%= hash.str %>', 'B', $variables, $config);
		ejs_test('<%= hash.num %>', '2', $variables, $config);
		ejs_test('<%= hash.func() %>', 'II', $variables, $config);
		
		ejs_test('<%= array[0] %>', 'C', $variables, $config);
		ejs_test('<%= array[1] %>', '3', $variables, $config);
		ejs_test('<%= array[2]() %>', 'III', $variables, $config);
		
		ejs_test('<%= hash.hash.str %>', 'D', $variables, $config);
		ejs_test('<%= hash.hash.num %>', '4', $variables, $config);
		ejs_test('<%= hash.hash.func() %>', 'IV', $variables, $config);
		
		ejs_test('<%= hash.array[0] %>', 'E', $variables, $config);
		ejs_test('<%= hash.array[1] %>', '5', $variables, $config);
		ejs_test('<%= hash.array[2]() %>', 'V', $variables, $config);
		
		ejs_test('<%= array[3].str %>', 'F', $variables, $config);
		ejs_test('<%= array[3].num %>', '6', $variables, $config);
		ejs_test('<%= array[3].func() %>', 'VI', $variables, $config);
		
		ejs_test('<%= array[4][0] %>', 'G', $variables, $config);
		ejs_test('<%= array[4][1] %>', '7', $variables, $config);
		ejs_test('<%= array[4][2]() %>', 'VII', $variables, $config);
	}
}
