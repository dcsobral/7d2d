#!/usr/bin/perl

use v5.14;  # optimal for unicode string feature
use warnings;
use warnings qw( FATAL utf8 );
use utf8;
use open qw( :encoding(UTF-8) :std );
use charnames qw( :full :short );

use autodie;

use XML::CSV;
our $csv_obj = XML::CSV->new();
$csv_obj->parse_doc("-", {headings => 1});
$csv_obj->print_xml("-");
