#!/usr/bin/env perl
use URI::Escape qw( uri_escape );
my $page_name = <>;
chomp($page_name);
$page_name =~ tr/ /_/;
print uri_escape( $page_name );
