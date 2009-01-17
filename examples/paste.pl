#!/usr/bin/env perl

use strict;
use warnings;

die "Usage: perl create.pl <file_to_paste>\n"
    unless @ARGV;

my $File = shift;

use lib qw|../lib lib|;
use WWW::Pastebin::NoPasteCom::Create;

my $paster = WWW::Pastebin::NoPasteCom::Create->new;

$paster->paste( $File, file => 1 )
    or die $paster->error;

print "Your paste is located on $paster\n";

