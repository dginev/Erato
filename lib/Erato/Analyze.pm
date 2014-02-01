package Erato::Analyze;

use base qw(Exporter);
our @EXPORT_OK = qw(analyze_artist);

sub analyze_artist {
  my ($artist) = @_;
  print STDERR "\n\nArtist $artist submitted for analysis\n";
  return $artist; }

1;