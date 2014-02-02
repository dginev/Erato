#!/usr/bin/env perl
use ExtUtils::MakeMaker;
 
WriteMakefile(
NAME=>'Erato',
VERSION=>'0.1',
PREREQ_PM => {
  'Mojolicious' => '4.6',
  'DBI' => 0,
  'DBD::SQLite'=>0,
  'JSON::XS'=>0,
  'List::MoreUtils'=>0,
  'Lyrics::Fetcher::LyricWiki'=>0,
  'Lyrics::Fetcher::Cache'=>0,
  'Net::LastFMAPI'=>0,
  'File::Slurp'=>0,
  'File::Spec'=>0
});