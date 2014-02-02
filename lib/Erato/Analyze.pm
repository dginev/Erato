package Erato::Analyze;

use strict;
use warnings;
use Data::Dumper;

use JSON::XS qw(decode_json);
use List::MoreUtils qw(uniq);
use Net::LastFMAPI;
use Lyrics::Fetcher;
use Mojo::UserAgent;
use Erato::WordFrequency;

use base qw(Exporter);
our @EXPORT_OK = qw(get_top_tracks compute_score);

my $lastfm_key = "a6434302f79586127abd3b2547422045";
lastfm_config(
  session_key => $lastfm_key,
);

sub get_top_tracks {
  my ($artist) = @_;
  $artist =~ s/Official Fan Page$//;
  # Grab all songs of this artist via LastFM's API:
  my $top_tracks = lastfm("artist.getTopTracks", artist => $artist);
  return unless ref $top_tracks;
  my @top_track_names = map {$_->{name}} @{$top_tracks->{toptracks}->{track}};
  return \@top_track_names; }

sub compute_score {
  my ($artist,$song) = @_;
  $artist =~ s/Official Fan Page$//;
  my $lyrics = Lyrics::Fetcher->fetch($artist,$song,'LyricWiki') ||
               Lyrics::Fetcher->fetch($artist,$song,'AZLyrics');
  return unless length($lyrics);
  # We got the lyrics compute the scores:
  my $scores={};
  my @all_words = grep {length($_)>1} split(/\W+/,$lyrics); # This is very basic tokenization here, throw away single-letter words
  my $all_count = scalar(@all_words);
  # Literacy - unique words ratio
  my @unique_words = uniq(@all_words);
  my $literacy_score = scalar(@unique_words) / $all_count;
  # Hipsterness - rare words ratio
  my @hipster_words = grep {($Erato::WordFrequency::List->{$_}||0) < $Erato::WordFrequency::hipsterness_cutoff} @all_words;
  my $hipsterness_score =  scalar(@hipster_words) / $all_count;
  # Coolness - trending words ratio
  # TODO: Maybe later, too hard to do right for now
  # my $cool_score ;
  
  $scores = {song=>$song,artist=>$artist,hipsterness=>$hipsterness_score,literacy=>$literacy_score}; # coolness=>$cool_score,
  # Now ask Yahoo's API about terms:
  my $ua = Mojo::UserAgent->new;
  $ua->max_redirects(2)->connect_timeout(10)->request_timeout(20);
  $lyrics=~s/[\[\]\'\/]/ /g; # Some non-word characters can be discarded
  my $query = "select * from contentanalysis.analyze where text='".$lyrics."';";
  my $request_string = "http://query.yahooapis.com/v1/public/yql?q=$query\&format=json\&diagnostics=false";
  my $response = $ua->get($request_string);
  if ($response->success) {
     # VERY Awkward naming scheme Yahoo!!! YUCK
    my $json_payload = decode_json($response->res->body);  
    my $query = $json_payload->{query} || return $scores;
    my $results = $query->{results} || return $scores;
    my $entities = $results->{entities} || return $scores;
    my $entity = $entities->{entity} || return $scores;
    if (ref $entity && ((ref $entity) eq 'ARRAY')) {
      my @terms = @$entity;
      # @terms = map { {term=>$_->{text}->{content}, score=>$_->{score}} } @terms;
      # TODO: For now, ease storage and lookup by just recording the terms as a ,, separated
      # $scores->{terms}=\@terms; }
      $scores->{terms}=join(",,",(map {$_->{text}->{content}} @terms)); }
    elsif (ref $entity && (ref $entity eq 'HASH')) {
      my @terms = $entity;      
      #@terms = map { {term=>$_->{text}->{content}, score=>$_->{score}} } @terms;
      # TODO: For now, ease storage and lookup by just recording the terms as a ,, separated
      #$scores->{terms}=$terms; } }
      $scores->{terms}=join(",,",(map {$_->{text}->{content}} @terms)); } }
  #TODO: We want to SAVE the text and score (certainty) for future computations
  # And of course return them!
  return $scores;
}

1;