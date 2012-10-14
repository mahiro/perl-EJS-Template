#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Template::EJS' ) || print "Bail out!\n";
}

diag( "Testing Template::EJS $Template::EJS::VERSION, Perl $], $^X" );
