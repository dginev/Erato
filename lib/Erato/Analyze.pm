package Erato::Analyze;

use strict;
use warnings;
use Data::Dumper;

use JSON::XS qw(decode_json);
use Net::LastFMAPI;
use Lyrics::Fetcher;
use Mojo::UserAgent;

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
  my $lyrics = Lyrics::Fetcher->fetch($artist,$song,'AZLyrics') ||
               Lyrics::Fetcher->fetch($artist,$song,'LyricWiki');
  return unless length($lyrics);
  # We got the lyrics, now ask Yahoo's API about terms:
  my $ua = Mojo::UserAgent->new;
  $ua->max_redirects(2)->connect_timeout(10)->request_timeout(20);
  $lyrics=~s/[\[\]\'\/]/ /g; # Some non-word characters can be discarded
  my $query = "select * from contentanalysis.analyze where text='".$lyrics."';";
  my $request_string = "http://query.yahooapis.com/v1/public/yql?q=$query\&format=json\&diagnostics=false";
  my $response = $ua->get($request_string);
  if ($response->success) {
     # VERY Awkward naming scheme Yahoo!!! YUCK
    my $json_payload = decode_json($response->res->body);  
    my $query = $json_payload->{query} || return;
    my $results = $query->{results} || return;
    my $entities = $results->{entities} || return;
    my $entity = $entities->{entity} || return;
    if (ref $entity && ((ref $entity) eq 'ARRAY')) {
      my @terms = @$entity;
      # We want to SAVE the text and score (certainty) for future computations
      # And of course return them!
      return [@terms];
    }
    exit; return; }
  else {return;}
  return $lyrics;
}

1;