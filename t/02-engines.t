#!perl -T
use strict;
use warnings;

my $tests; BEGIN {$tests = 25}
use EJS::Template::JSAdapter;
use Test::More tests => 4 + $tests * scalar(@EJS::Template::JSAdapter::SUPPORTED_ENGINES);

use EJS::Template::Test;
use EJS::Template::Util qw(clean_text_ref);
use Encode;
use File::Basename;
use Scalar::Util qw(tainted);

my $encoded_text = "\xE3\x83\x86\xE3\x82\xB9\xE3\x83\x88";
my $decoded_text = decode_utf8($encoded_text);
my $invalid_text = "Invalid: \xFF";
my $sanitized_text = "Invalid: \xEF\xBF\xBD";
my $tainted_text = do {
	open(my $in, dirname(__FILE__).'/data/tainted.txt') or die "$!: tainted.txt";
	local $/;
	my $tmp = <$in>;
	close $in;
	$tmp;
};

ok !Encode::is_utf8($encoded_text);
ok Encode::is_utf8($decoded_text);
isnt Encode::decode_utf8($invalid_text), $invalid_text;
ok tainted($tainted_text);

for my $engine (@EJS::Template::JSAdapter::SUPPORTED_ENGINES) {
	eval {EJS::Template::JSAdapter->create($engine)};
	my $not_installed = $@;
	
	SKIP: {
		skip "$engine is not installed", $tests if $not_installed;
		
		my $variables = {
			str => 'A', num => 1, func => sub {'I'},
			hash => {
				str => 'B', num => 2, func => sub {'II'},
				hash => {str => 'D', num => 4, func => sub {'IV'}},
				array => ['E', 5, sub {'V'}],
			},
			array => [
				'C', 3, sub {'III'},
				{str => 'F', num => 6, func => sub {'VI'}},
				['G', 7, sub {'VII'}],
			],
			encoded => $encoded_text,
			decoded => $decoded_text,
			invalid => $invalid_text,
			tainted => $tainted_text,
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
		
		my $invalid_text_expected = do {
			no strict 'refs';
			(${"EJS::Template::JSAdapter::".$engine."::SANITIZE_UTF8"} ?
					$sanitized_text : $invalid_text);
		};
		
		ejs_test('<%= encoded %>', $encoded_text, $variables, $config);
		ejs_test('<%= decoded %>', $encoded_text, $variables, $config);
		ejs_test('<%= invalid %>', $invalid_text_expected, $variables, $config);
		ejs_test('<%= tainted %>', $tainted_text, $variables, $config);
	}
}
