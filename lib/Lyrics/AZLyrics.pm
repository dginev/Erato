package Lyrics::Fetcher::AZLyrics;

# $Id$

use 5.008000;
use strict;
use warnings;
use Mojo::UserAgent;
use Mojo::UserAgent::CookieJar;
use HTML::Strip;
use Carp;

our $VERSION = '0.05';

# the HTTP User-Agent we'll send:
our $AGENT = "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:24.0) Gecko/20100101 Firefox/24.0";

    

sub fetch {
    
    my $self = shift;
    my ( $artist, $song ) = @_;
    
    # reset the error var, change it if an error occurs.
    $Lyrics::Fetcher::Error = 'OK';
    
    unless ($artist && $song) {
        carp($Lyrics::Fetcher::Error = 
            'fetch() called without artist and song');
        return;
    }
    
    $artist =~ s/[^a-z0-9]//gi;
    $song   =~ s/[^a-z0-9]//gi;
    
    my $url = 'http://www.azlyrics.com/lyrics/';

    $url .= join('/', lc $artist, lc $song) . '.html';
    my $ua = Mojo::UserAgent->new;
    $ua->max_redirects(2)->connect_timeout(10)->request_timeout(20);
    $ua->cookie_jar(Mojo::UserAgent::CookieJar->new);
    #$ua->agent($AGENT);
    my $res = $ua->get($url);
    if ( $res->success ) {
        my $lyrics = _parse($res->res->body);
        return $lyrics;
    } else {
         my ($err, $code) = $res->error;
         if ($code && ($code eq "404")) {
            $Lyrics::Fetcher::Error = 
                'Lyrics not found';
            return;
        } else {
            carp($Lyrics::Fetcher::Error = 
                "Failed to retrieve $url (".$err.')');
            return;
        }
    }
}


sub _parse {
    my $html = shift;
    my $hs = HTML::Strip->new();
    # Nasty - look for everything in between the two ringtones links:
    if (my ($goodbit) = $html =~
        m{<\!-- start of lyrics -->(.+)<\!-- end of lyrics -->}msi)
    {
      return $hs->parse($goodbit);
    } else {
      carp "Failed to identify lyrics on result page";
      return;
    }
} # end of sub parse

1;
__END__

=head1 NAME

Lyrics::Fetcher::AZLyrics - Get song lyrics from www.azlyrics.com

=head1 SYNOPSIS

  use Lyrics::Fetcher;
  print Lyrics::Fetcher->fetch("<artist>","<song>","AZLyrics");

  # or, if you want to use this module directly without Lyrics::Fetcher's
  # involvement:
  use Lyrics::Fetcher::AZLyrics;
  print Lyrics::Fetcher::AZLyrics->fetch('<artist>', '<song>');


=head1 DESCRIPTION

This module tries to get song lyrics from www.azlyrics.com.  It's designed to
be called by Lyrics::Fetcher, but can be used directly if you'd prefer.

=head1 INTERFACE

=over 4

=item fetch($artist, $title)

Attempts to fetch lyrics.

=back


=head1 BUGS

Probably.  If you find any, please let me know.  If azlyrics.com change their
site much, this module may well stop working.  If you find any songs which
have lyrics listed on the www.azlyrics.com site, but for which this module is
unable to fetch lyrics, please let me know also.  It seems that the HTML on
the lyrics pages isn't consistent, so it's entirely possible (likely, in fact)
that there are some pages which this script will not be able to parse.


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under 
the same terms as Perl itself.


=head1 AUTHOR

David Precious E<lt>davidp@preshweb.co.ukE<gt>



=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007-08 by David Precious

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.7 or,
at your option, any later version of Perl 5 you may have available.

Legal disclaimer: I have no connection with the owners of www.azlyrics.com.
Lyrics fetched by this script may be copyrighted by the authors, it's up to 
you to determine whether this is the case, and if so, whether you are entitled 
to request/use those lyrics.  You will almost certainly not be allowed to use
the lyrics obtained for any commercial purposes.

=cut
