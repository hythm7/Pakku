use File::Temp;
use LibCurl::Easy;
use Cro::Uri;

use Pakku::Fetcher::Git;
use Pakku::Fetcher::Curl;
use Pakku::Fetcher::Local;

unit class Pakku::Fetcher;


multi method fetch ( :$src!, :$dst = tempdir ) {

  my Cro::Uri $uri .= parse-ref: $src;

  given $uri {

    when .scheme.so and .path.IO.extension ~~ any('git', '') {

      Pakku::Fetcher::Git.fetch( ~$uri, $dst );
    } 

    Pakku::Fetcher::Curl.fetch( ~$uri, $dst )  when .scheme.so;

    Pakku::Fetcher::Local.fetch( ~$uri, $dst ) when not .scheme.so;

  }

}
