package Erato;
use Mojo::Base 'Mojolicious';
use Erato::Analyze qw(analyze_artist);
use File::Basename 'dirname';
use File::Spec::Functions qw(catdir catfile);

# This method will run once at server start
sub startup {
  my $app = shift;
  # Switch to installable home directory
  $app->home->parse(catdir(dirname(__FILE__), 'Erato'));
  print STDERR "HOME: ",$app->home,"\n\n";
  # Switch to installable "public" directory
  $app->static->paths->[0] = $app->home->rel_dir('public');
  # Switch to installable "templates" directory
  $app->renderer->paths->[0] = $app->home->rel_dir('templates');

  $ENV{MOJO_REQUEST_TIMEOUT} = 600;# 10 minutes;
  $ENV{MOJO_CONNECT_TIMEOUT} = 120; # 2 minutes
  $ENV{MOJO_INACTIVITY_TIMEOUT} = 600; # 10 minutes;

  my $r = $app->routes;
  $r->get('/' => sub {
    my $self = shift;
    $self->render('index');
  });

  $r->post('/analyze' => sub {
    my $self = shift;
    my $post_params = $self->req->body_params->params || [];
    my $report = map {analyze_artist($_)} @$post_params;
    $self->render(json => $report);
  });
}

1;