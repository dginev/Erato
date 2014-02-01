package Erato::Analyze;

use strict;
use warnings;
use Net::LastFMAPI;
use Lyrics::Fetcher;
use Data::Dumper;

use base qw(Exporter);
our @EXPORT_OK = qw(get_top_tracks compute_score);

my $lastfm_key = "a6434302f79586127abd3b2547422045";
lastfm_config(
  session_key => $lastfm_key,
);

sub get_top_tracks {
  my ($artist) = @_;
  # Grab all songs of this artist via LastFM's API:
  my $top_tracks = lastfm("artist.getTopTracks", artist => $artist);
  my @top_track_names = map {$_->{name}} @{$top_tracks->{toptracks}->{track}};
  return \@top_track_names; }

sub compute_score {
  my ($artist,$song) = @_;
  print STDERR "\n Received tuple: <'$artist','$song'>\n";
  my $lyrics = Lyrics::Fetcher->fetch($artist,$song,'LyricWiki') ||
               Lyrics::Fetcher->fetch($artist,$song,'AZLyrics') ||
               Lyrics::Fetcher->fetch($artist,$song,'LyrDB') ||
               Lyrics::Fetcher->fetch($artist,$song,'AstraWeb');
  print STDERR $lyrics||'Not found!',"\n\n";
  exit;
  return $lyrics;
}

1;