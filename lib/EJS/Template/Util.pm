use 5.006;
use strict;
use warnings;

package EJS::Template::Util;
use base 'Exporter';

our @EXPORT_OK = qw(clean_text_ref);

use Encode;
use Scalar::Util qw(tainted);

=head2 clean_text_ref

=cut

sub clean_text_ref {
	my ($value_ref, $encode_utf8, $sanitize_utf8, $force_untaint) = @_;
	
	if (Encode::is_utf8($$value_ref)) {
		if ($encode_utf8) {
			# UTF8 flag must be turned off. (Otherwise, segmentation fault occurs)
			$value_ref = \Encode::encode_utf8($$value_ref);
		}
	} elsif ($sanitize_utf8 && $$value_ref =~ /[\x80-\xFF]/) {
		# All characters must be valid UTF8. (Otherwise, segmentation fault occurs)
		$value_ref = \Encode::encode_utf8(Encode::decode_utf8($$value_ref));
	}
	
	if ($force_untaint && tainted($$value_ref)) {
		$$value_ref =~ /(.*)/s;
		$value_ref = \qq($1);
	}
	
	return $value_ref;
}

1;
