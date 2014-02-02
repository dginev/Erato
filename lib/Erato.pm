package Erato;
use strict;
use warnings;

use Mojo::Base 'Mojolicious';
use Erato::Analyze qw(get_top_tracks compute_score);
use Erato::Backend;
use File::Basename 'dirname';
use File::Spec::Functions qw(catdir catfile);

# This method will run once at server start
sub startup {
  my $app = shift;
  # Listen at the hot deployment port
  $app->config(hypnotoad => {listen => ['http://*:3000']});
  # Switch to installable home directory
  $app->home->parse(catdir(dirname(__FILE__), 'Erato'));
  # Switch to installable "public" directory
  $app->static->paths->[0] = $app->home->rel_dir('public');
  # Switch to installable "templates" directory
  $app->renderer->paths->[0] = $app->home->rel_dir('templates');

  $ENV{MOJO_REQUEST_TIMEOUT} = 600;# 10 minutes;
  $ENV{MOJO_CONNECT_TIMEOUT} = 600; # 10 minutes
  $ENV{MOJO_INACTIVITY_TIMEOUT} = 600; # 10 minutes;

  my $r = $app->routes;
  $r->get('/' => sub {
    my $self = shift;
    $self->render('index');
  });

  $r->post('/analyze' => sub {
    my $self = shift;
    my $post_params = $self->req->body_params->params || [];
    my %parameters;
    while (my ($key,$value) = splice(@$post_params,0,2)) {
      $parameters{$key} //= [];
      push $parameters{$key},$value; }
    # We can begin building our report
    # Since we're doing a whole bunch of authors and songs, let's go async using the Mojolicious event loop magic:
    # my $delay = Mojo::IOLoop->delay(sub{
    #   my $delay = shift;
    #   $self->render_dumper(@_);
    # });
    # $self->analyze_artist($_ => $delay->begin) for @{$parameters{'names[]'}||[]};
    my $score = $self->analyze_artist(@{$parameters{name}}) if ref $parameters{name};
    $self->render(json=>$score);
  });

  $app->helper(analyze_artist => sub {
    my ($self,$artist) = @_;
    my $songs = get_top_tracks($artist);
    my $backend = Erato::Backend->new();
    # Ok, now that we have the tracks, we need to analyze each piece individually and then aggregate them together.
    # Hence, let's use a nested event loop:
    # Async processing for each <artist,song> tuple:
    my @scores;
    my $limit = 10; # Top 10 only
    for my $song(@$songs) {
      my $score = $backend->fetch_score($artist, $song);
      if (! ref $score) {
        $score = compute_score($artist, $song);
        $backend->save_score($score) if ref $score; }

      # We want to return an array of terms, if applicable
      if ($score->{terms}) {
        $score->{terms} = [split(',,',$score->{terms})]; }
      push @scores, $score if ref $score;
      last unless --$limit; }
    return \@scores;
  });
}


1;