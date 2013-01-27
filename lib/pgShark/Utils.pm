package pgShark::Utils;
use strict;
use warnings;

##
# This program is open source, licensed under the simplified BSD license.  For license terms, see the LICENSE file.
##
use Exporter;
our $VERSION = 0.1;
our @ISA = ('Exporter');
our @EXPORT = qw/debug set_debug normalize_query get_debug_lvl dec2dot/;

my $debug_lvl = 0;

sub dec2dot {
    my $addr = shift;
    return sprintf "%s.%s.%s.%s", $addr>>24, $addr>>16 & 255, $addr>>8 & 255, $addr & 255;
}

sub get_debug_lvl {
	return $debug_lvl;
}

sub set_debug {
	my $lvl = shift;
	$debug_lvl = $lvl;

	debug(1, "debug level set to $debug_lvl.\n");
}

sub debug {
	my $lvl = shift;
	return if $debug_lvl < $lvl;
	my $frmt = shift;
	my @from = caller(1);
	my @vars = ( @_ );
	$from[2] = (caller(0))[2];
	if ($lvl == 6) {
		tr/\x00-\x1F\x7F-\xFF/./ foreach (@vars);
	}
	printf(STDERR "[%d] in %s:%d, %s:\n  $frmt\n", $lvl, $from[1], $from[2], $from[3], @vars);
}

#normalize query
# @return the normalized query
sub normalize_query {
	my $query = shift;

	chomp $query;

	#remove bad escaped quotes in text so they are not in our way
	#for other cleaning stuffs. We'll take care of others '' later
	$query =~ s/\\'//g while $query =~ /\\'/;
	#remove multi spaces
	$query =~ s/\s+/ /g;
	#empty text
	$query =~ s/'[^']*'/''/g;
	#remove all remaining '' (that were escaping ')
	#left behind the previous substitution
	$query =~ s/''('')+/''/g;
	#remove numbers
	$query =~ s/([^a-zA-Z0-9_\$-])-?([0-9]+)/${1}0/g;
	#remove hexa numbers
	$query =~ s/([^a-z_\$-])0x[0-9a-f]{1,10}/${1}0x/gi;
	#remove IN (values)
	$query =~ s/(IN\s*)\([^\)]*\)/${1}0x/gi;
	#rewrite params, some of them might have been drop in a IN parameter
	my $pi=1;
	$query =~ s/\$[0-9]+/'$'.$pi++/gie;

	return $query;
}
1
