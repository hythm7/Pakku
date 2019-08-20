unit role Pakku::Fetcher::Curl;

method fetch ( $uri, $dst ) {

  say 'Curl';

  #my $download = $dst.add( $uri.path.basename ).Str;

  #LibCurl::Easy.new( URL => $uri.Str, :$download ).perform;

  #$download;
}
