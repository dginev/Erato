package Erato::Backend;

use warnings;
use strict;
use DBI;
# A simple SQLite backend for Erato.
our ($db_dir) = grep { -d $_ } map {"$_/Erato" } @INC;
our $db_file = "$db_dir/Erato.db"; # Singleton DB for now

sub new {
  my ($class,%options) = @_;
  my $self = bless (\%options, $class);

  # Auto-vivify a new SQLite database, if not already created
  if (! -f $db_file) {
    # Touch a file if it doesn't exist
    my $now = time;
    utime $now, $now, $db_file; }

  my $dbh = DBI->connect("DBI:SQLite:$db_file", "erato", "erato",
   {
    RaiseError => 1,
    AutoCommit => 1
   }) || die "Could not connect to database: $DBI::errstr";
  $dbh->do('PRAGMA cache_size=50000;');
  $self->{handle}=$dbh;

  if (-z $db_file) {
    $self->reset_db; }

  return $self; }

sub reset_db {
  my ($self) = @_;
  my $dbh = $self->{handle};
  # Request a 20 MB cache size, reasonable on all modern systems:
  $dbh->do("PRAGMA cache_size = 20000; ");
  # Table structure for table object
  $dbh->do("DROP TABLE IF EXISTS scores;");
  $dbh->do("CREATE TABLE scores (
    songid integer primary key AUTOINCREMENT,
    artist varchar(500) NOT NULL,
    song  varchar(500),
    hipsterness REAL,
    literacy REAL,
    terms varchar(5000)
  );"); }

sub save_score {
  my ($self,$score) = @_;
  my $dbh = $self->{handle};
  my $sth = $dbh->prepare('INSERT INTO scores (artist,song,hipsterness,literacy,terms) values (?,?,?,?,?)');
  $sth->execute(map {$score->{$_}||''} qw(artist song hipsterness literacy terms)); }

sub fetch_score {
  my ($self,$artist,$song) = @_;
  my $dbh = $self->{handle};
  my $sth = $dbh->prepare('SELECT * FROM scores WHERE artist=? AND song=?');
  $sth->execute($artist,$song);
  my $score = $sth->fetchrow_hashref();
  $sth->finish();
  return $score; }

  1;