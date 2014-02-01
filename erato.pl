#!/usr/bin/env perl
use Mojolicious::Lite;
use Erato::Analyze qw(anaylze_artist);

get '/' => sub {
  my $self = shift;
  $self->render('index');
};

post '/analyze' => sub {
  my $self = shift;
  my $post_params = $self->req->body_params->params || [];
  my $report = map {anaylze_artist($_)} @$post_params;
  $self->render(json => $report);
}

app->start;