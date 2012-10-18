#!perl -T

use Test::More tests => 20;

use EJS::Template;
use Test::Builder;

sub parse_is {
	my ($source, $expected) = @_;
	local $Test::Builder::Level = $Test::Builder::Level + 1;
	my $output;
	EJS::Template->parse(\$source, \$output) or die $@;
	is($output, $expected, "source: [$source]");
}

parse_is('', '');
parse_is('  ', 'print("  ");');

parse_is('<%'       , ''     );
parse_is('<%  '     , '  '   );
parse_is('<% %>'    , ' '    );
parse_is('<% %>  '  , '   '  );
parse_is('  <%'     , '  '   );
parse_is('  <%  '   , '    ' );
parse_is('  <% %>'  , '   '  );
parse_is('  <% %>  ', '     ');

parse_is('<%='       , 'print();'                         );
parse_is('<%=  '     , 'print(  );'                       );
parse_is('<%= %>'    , 'print( );'                        );
parse_is('<%= %>  '  , 'print( );print("  ");'            );
parse_is('  <%='     , 'print("  ");print();'             );
parse_is('  <%=  '   , 'print("  ");print(  );'           );
parse_is('  <%= %>'  , 'print("  ");print( );'            );
parse_is('  <%= %>  ', 'print("  ");print( );print("  ");');

parse_is(<<__EJS__, <<__OUT__);
Line 1
  <% var x %>\t
Line 2
__EJS__
print("Line 1\\n");
   var x \t
print("Line 2\\n");
__OUT__

parse_is(<<__EJS__, <<__OUT__);
Line 1
  <%= x %>\t
Line 2
__EJS__
print("Line 1\\n");
print("  ");print( x );print("\t\\n");
print("Line 2\\n");
__OUT__
