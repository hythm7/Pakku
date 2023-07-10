use Pakku::Log;

# This file is borrwoed from
# HTTP::Tiny:ver<0.2.6>:auth<zef:jjatria>
# with minimal modifications.
# it will serve as HTTP client to avoid
# libcurl native dependency

class X::Pakku::HTTP is Exception {
  has     $.response is required;
  has Str $.message  is required;
}

class Pakku::HTTP {
  my class Handle  { ... }
  my subset HTTPMethod of Str where /
    ^
    [ GET
    | CONNECT
    | DELETE
    | HEAD
    | OPTIONS
    | PATCH
    | POST
    | PUT
    | TRACE
    ]$
  /;

  has      %!proxy;
  has      %!no-proxy;
  has Handle $!handle;
  has      %!default-headers   is built;
  has      $!cookie-jar;
  has Int    $!max-redirect    is built = 5;
  has Bool   $!keep-alive      is built = True;
  has Bool   $!throw-exceptions  is built;
  has Str    $!agent         is built
    = self.^name ~ '/' ~ $?DISTRIBUTION.meta<ver> ~ ' Raku';

  submethod TWEAK (
     :$cookie-jar,
       :$no-proxy = %*ENV<   no_proxy>,
        :$proxy = %*ENV<  all_proxy> // %*ENV<  ALL_PROXY>,
     :$http-proxy = %*ENV< http_proxy> // %*ENV< HTTP_PROXY> // $proxy,
    :$https-proxy = %*ENV<https_proxy> // %*ENV<HTTPS_PROXY> // $proxy,
  ) {

    # Cookie Jar validation

    with $cookie-jar {
      my $add    = .can: 'add';
      my $header = .can: 'header';

      my $error;
      $error ||= "it's missing the 'add' and 'header' methods" unless $add || $header;
      $error ||= "it's missing the 'add' method"    unless $add;
      $error ||= "it's missing the 'header' method" unless $header;
      $error ||= "its 'add' method does not support \\( { .^name }, Str, Str )"
        unless $add.any ~~ *.cando: \( $cookie-jar.WHAT, 'GET', 'cookie=string' );
      $error ||= "its 'header' method does not support \\( { .^name }, Str, Str )"
        unless $header.any ~~ *.cando: \( $cookie-jar.WHAT, 'GET', 'cookie=string' );

      die "{ $cookie-jar.^name } is not supported as a cookie jar: $error" if $error;

      $!cookie-jar = $_;
    }

    # Proxy validation

    try $http-proxy.&split-url
      or die "Invalid HTTP proxy: $http-proxy";

    try $https-proxy.&split-url
      or die "Invalid HTTPS proxy: $https-proxy";

    %!proxy<http>  = $_ with $http-proxy;
    %!proxy<https> = $_ with $https-proxy;

    return unless $no-proxy;

    %!no-proxy = $no-proxy ~~ Str
      ?? $no-proxy.split(',')».trim.Set
      !! $no-proxy.Set;
  }

  method get     (|c) { self.request: 'GET',     |c }
  method delete  (|c) { self.request: 'DELETE',  |c }
  method head    (|c) { self.request: 'HEAD',    |c }
  method options (|c) { self.request: 'OPTIONS', |c }
  method patch   (|c) { self.request: 'PATCH',   |c }
  method post    (|c) { self.request: 'POST',    |c }
  method put     (|c) { self.request: 'PUT',     |c }
  method trace   (|c) { self.request: 'TRACE',   |c }

  multi method can-ssl ( --> Bool ) {
    # FIXME: Is there no easier way to do this?
    fail 'IO::Socket::SSL:ver<0.0.2+> must be installed'
      unless $*REPO.repo-chain
        .map( *.?candidates: 'IO::Socket::SSL', :ver<0.0.2+> )
        .flat.first( *.defined );
    return True;
  }

  multi method download ( ::?CLASS:U: |c ) { self.new.download: |c }

  multi method download (
    ::?CLASS:D:
       Str:D $url,
        IO() $file,
          :%headers is copy,
          |rest,
  ) {
    die 'data-callback is not allowed in download method'
      if rest<data-callback>:exists;

    self!normalise-headers: %headers;

    my $tempfile = $file ~ (^2**31).pick;
    my $fh = open $tempfile, :x;

    LEAVE {
      $fh.close;
      $tempfile.IO.unlink;
    }

    my &data-callback = -> $blob { $fh.write: $blob }

    my %res;
    CATCH {
      when X::Pakku::HTTP {
        .rethrow unless .response<status> == 304;
        %res = .response;
      }
    }

    %res = self.request: 'GET', $url, :&data-callback, :%headers, |rest;
    $fh.close;

    $tempfile.IO.rename: $file if %res<success>;

    %res<success> ||= %res<status> == 304;

    return %res;
  }

  proto method request( :%headers, |c ) {
    die "The 'Host' header must not be provided as header option"
      if %headers.keys.first: { .defined && m:i/ ^ host $ / }
    {*}
  }

  # Support requests as class methods
  multi method request ( ::?CLASS:U: |c ) { self.new.request: |c }

  # FIXME: Why do these not work with nextwith?
  multi method request ( ::?CLASS:D: Any:U :$content, |c ) { samewith( |c ) }

  multi method request ( ::?CLASS:D: Numeric:D :$content, |c ) {
    samewith( content => $content.Str, |c );
  }

  multi method request (
    ::?CLASS:D:
       Str:D :content($input-content),
           :%headers is copy,
           |c,
  ) {
    self!normalise-headers: %headers;

    %headers<content-type> ||= 'text/plain;charset=UTF-8';
    my $content = Blob.new: $input-content.Str.encode;

    samewith( :%headers, :$content, |c );
  }

  multi method request (
    ::?CLASS:D:
      Hash:D :content($input-content),
           :%headers is copy,
           |c,
  ) {
    self!normalise-headers: %headers;

    # Default content types
    if $input-content.values.grep: IO::Path {
      my $type = %headers<content-type> ||= 'multipart/form-data';

      die "Cannot send a $type body with a Hash with IO::Path values"
        unless $type.starts-with: 'multipart/form-data';
    }
    else {
      %headers<content-type>
        ||= 'application/x-www-form-urlencoded';
    }

    # Encode form data
    my $content;
    given %headers<content-type> -> $type {
      when $type.starts-with: 'multipart/form-data' {
        my $boundary;
        if $type ~~ / 'boundary=' \"? ( <-["]>+ ) / {
          $boundary = $0;
        }
        else {
          $boundary = ('a'...'z', 'A'...'Z').roll(20).join;
          %headers<content-type> ~= Q:s'; boundary="$boundary"';
        }

        $content = $input-content.&multipart-encode: $boundary;
      }
      when $type eq 'application/x-www-form-urlencoded' {
        $content = Blob.new: $input-content.&url-encode.encode;
      }
      default {
        die "Cannot send a $type body with a Hash";
      }
    }

    samewith( :%headers, :$content, |c );
  }

  multi method request (
    ::?CLASS:D:
      Blob:D :content($input-content),
           :%headers is copy,
           |c,
  ) {
    self!normalise-headers: %headers;

    %headers<content-length> ||= $input-content.bytes
      unless %headers<transfer-encoding>;

    my $source = $input-content;
    my &content = sub ( --> Blob ) {
      LEAVE $source = Blob.new;
      return $source.subbuf: 0, $source.bytes;
    }

    samewith( :%headers, :&content, |c );
  }

  multi method request (
    ::?CLASS:D:
    HTTPMethod $method,       # A valid HTTP verb, in uppercase
    Str      $url,        # The URL to send the request to
          :%headers is copy,  # The set of headers to send as a Hash
          :&data-callback,    # An optional callback for content chunks
          :&trailer-callback, # An optional callback to generate the trailer
          :&content       # A Str, Blob, or Callable for the content
  ) {
    self!normalise-headers: %headers;

    if &content {
      %headers<content-type>    ||= 'application/octet-stream';
      %headers<transfer-encoding> ||= 'chunked'
        unless defined %headers<content-length>;
    }

    my $response = self!request: $method, $url,
      :%headers, :&content, :&data-callback, :&trailer-callback;

    if $!throw-exceptions && ! $response<success> {
      my $message = $response<status> == 599
        ?? $response<content>.decode
        !! $response< status reason >.join: ' ';

      .throw with X::Pakku::HTTP.new: :$response, :$message;
    }

    return $response;
  }

  # END OF PUBLIC A}PI

  sub split-url ( Str:D $url ) {
    $url ~~ /
      ^
      $<scheme>   = <-[ : / ? # ]>+
      '://'
      $<authority>  = <-[   / ? # ]>+
      $<path>     = <-[     # ]>*
    / or die "Cannot parse URL: $url";

    my $scheme = lc $<scheme>;
    my $path   = ~$<path>;
       $path   = "/$path" unless $path.starts-with: '/';

    my ( $host, $auth ) = $<authority>.flip.split( '@', 2 )».flip;
    $auth .= &url-decode with $auth;

    my Int $port = $host ~~ / ':' $<port> = \d+ $ / ?? +$<port>
      !! $scheme eq 'http'            ?? 80
      !! $scheme eq 'https'           ?? 443
      !! Nil;

    s/ ':' \d* $ // given $host;

    return $scheme, $host.lc, $port, $path, $auth;
  }

  sub base64-encode ( Blob $blob --> Str ) {
    my constant %enc = ( 'A'...'Z', 'a'...'z', 0...9, '+', '/' ).pairs;

    my $out = $blob».fmt('%08b').join.comb(6)
      .map({ %enc{ .fmt('%-6s').subst(' ', '0', :g).parse-base(2) } })
      .join;

    $out ~= '=' while $out.chars % 4;

    return $out;
  }

  multi sub url-decode ( Str:D $text --> Str ) {
    return $text.subst: / '%' ( <xdigit> ** 2 ) /,
      { $0.Str.parse-base(16).chr }, :g;
  }

  # Encodes for URL encoded forms
  multi sub url-encode ( Str() $text --> Str ) {
    return $text.subst:
      /<-[
        ! * ' ( ) ; : @ + $ , / ? # \[ \]
        0..9 A..Z a..z \- . ~ _
      ]> /,
      { .Str.encode».fmt('%%%02X').join }, :g;
  }

  multi sub url-encode ( Hash $form --> Str ) {
    return join '&', gather for $form.sort -> ( :$key, :$value ) {
      take "$key={ .&url-encode }" for $value.List;
    }
  }

  sub multipart-encode ( %form, $boundary --> Blob ) {
    my $blob = Blob.new;
    for %form.sort -> ( :key($key), :value($v) ) {
      for $v.List -> $value {
        $blob ~= "--$boundary\r\n".encode;
        $blob ~= "Content-Disposition: form-data; name=\"$key\"".encode;

        if $value.^lookup: 'slurp' {
          if $value ~~ IO::Path {
            $blob ~= qq[; filename="{ $value.basename }"].encode;
          }
          $blob ~= "\r\n".encode;
          $blob ~= "Content-Type: application/octet-stream\r\n\r\n".encode;
          $blob ~= $value.slurp: :bin;
          $blob ~= "\r\n".encode;
          next;
        }

        $blob ~= "\r\n\r\n$value\r\n".encode;
      }
    }
    $blob ~= "--$boundary--\r\n".encode;

    return $blob;
  }

  # Lowercases top-level keys in a Hash and sets default values
  method !normalise-headers ( ::?CLASS:D: %h --> Nil ) {
    %h = %h.pairs.map: { .key.lc => .value }
    %h{ .key.lc } //= .value for %!default-headers;
  }

  # Well-known header capitalisation exceptions. All other headers will be
  # capitalised automatically to match the common standard.
  # Bear in note that header field names are case-insensitive in any case:
  # https://tools.ietf.org/html/rfc7230#section-3.2
  my constant HEADER-CASE =
    < TE Content-MD5 DNT X-XSS-Protection >.map({ .lc => $_ }).Map;

  method !request (
    Str $method,
    Str $url,
       :%headers,
       :&data-callback,
       :&trailer-callback,
       :&content,
       :%state = {},
  ) {
    CATCH {
      when X::Pakku::HTTP { return .response }

      default {
        my $content = Buf[uint8].new: .message.encode;
        return {
          :$content,
          success => False,
          status  => 599,
          reason  => 'Internal Exception',
          headers => {
            content-length => $content.bytes,
            content-type   => 'text/plain',
          },
        }
      }
    }

    my ( $scheme, $host, $port, $path, $auth ) = split-url($url);

    # If we have Basic auth parameters, add them
    my Bool $basic-auth;
    if $auth && !%headers<authorization> {
      $basic-auth = True;
      %headers<authorization> = "Basic { $auth.encode.&base64-encode }";
    }

    with $!cookie-jar {
      my $header = .header: $method, $url;
      %headers<cookie> = $header if $header;
    }

    %headers<host> = $host;
    %headers<host> ~= ":$port"
      if ( $scheme eq 'https' && $port != 443 )
      || ( $scheme eq 'http'  && $port !=  80 );

    %headers<connection> = 'close' unless $!keep-alive;
    %headers<user-agent> ||= $!agent;

    my $handle = $!handle and $!handle = Nil;
    if $handle && not $handle.can-reuse: $scheme, $host, $port {
      # FIXME: When doing multiple HTTPS async requests, the handle
      # might already be closed in this case. Since we're discarding
      # it anyway, we do not care if we cannot close it.
      try { $handle.close }
      $handle = Nil;
    }
    $handle //= Handle.new;

    if !%!no-proxy{$host} && %!proxy{$scheme} {
      my $proxy = %!proxy{$scheme};

      %headers<proxy-authorization> = "Basic { .encode.&base64-encode }"
        with $proxy.&split-url.tail;

      $handle.connect: $proxy;

      if $scheme eq 'https' {
        $handle.upgrade: "$host:$port", %headers;
      }
      else {
        $path = $url;
      }
    }
    else {
      $handle.connect: $url;
    }

    $handle.write-request: $method, $path,
      %headers, &content, &trailer-callback;

    my ( %response, Blob[uint8] $head, Blob[uint8] $body );
    repeat while %response<status>.starts-with: '1' {
      ( $head, $body ) = $handle.get-response-header: $body;
      %response = $handle.read-response-header($head);
    }

    if $!cookie-jar {
      $!cookie-jar.add: $url, $_ for %response<headers><set-cookie>.grep: *.defined;
    }

    %response<url> = $url;

    my Bool $known-length;
    if $method ne 'HEAD' && %response<status> != 204 | 304 {
      # Any time we receive a relevant chunk of content, we'll pass
      # that to &on-content. If the user provided a 'data-callback'
      # then that defined what we call. If not, we'll provide our
      # own.
      # This means the code past this point can always assume there
      # is a callback to use, which makes this easy to extend.
      # What constitutes 'a relevant chunk of content' will depend on
      # the response type. It might be just a blob of data in a
      # fixed-length response, or a chunk in a chunked response, or
      # a part in a multipart response, etc.
      # The cando check is because, when dealing with multipart
      # responses, we need to provide the user with the part's headers
      # (eg. so they can identify the byterange it belongs to), but
      # it would be cumbersome to always require a callback that
      # accepted 3 parameters, some of which will never be used.
      my Buf[uint8] $response-body .= new;
      my &on-content;
      with &data-callback {
        # FIXME: Why does when not work here?
        if .cando: \( Blob, Hash, Hash ) {
          &on-content = &data-callback.assuming( *, %response, * );
        }
        elsif .cando: \( Blob, Hash ) {
          &on-content = &data-callback.assuming( *, %response );
        }
        elsif .cando: \( Blob ) {
          &on-content = &data-callback;
        }
        else {
          die 'Unsupported signature for data callback: ' ~ .signature.raku;
        }
      }
      else {
        &on-content = { $response-body.append: $^blob }
      }

      # read-content will add any trailing headers if parsing
      # a chunked response
      $known-length = $handle.read-content: &on-content, $body, %response;

      %response<content> = $response-body
        if !&data-callback && $response-body.bytes;
    }

    my $see-other = %response<status> == 303;
    my $redirect  = %response<status> ~~ / ^ 30 <[ 1 2 7 8 ]> $ /
      && $method eq 'GET' | 'HEAD'
      && %response<headers><location>;

    if ( $see-other || $redirect )
      && %state<redirects>.elems < $!max-redirect
    {
      %state<redirects>.push: %response;

      %headers<authorization>:delete if $basic-auth;

      my $location = %response<headers><location>;
      $location = sprintf '%s://%s:%s%s',
        $scheme,
        $host,
        $port,
        $location if $location.starts-with: '/';

      # Remove headers specific to resource, connection,
      # and proxy configuration (see RFC 9110 § 15.4)
      %headers<
        connection
        keep-alive
        proxy-authentication-info
        proxy-authorization
        proxy-connection
        referer
        te
        transfer-encoding
        upgrade
      >:delete;

      my $new-method = $see-other ?? 'GET' !! $method;

      # If the request method has been changed to GET or HEAD,
      # remove content-specific header fields (see RFC 9110 § 15.4)
      %headers<
        content-encoding
        content-language
        content-length
        content-location
        content-type
        digest
        last-modified
      >:delete if $new-method eq 'GET'|'HEAD' && $method ne $new-method;

      return self!request:
        $new-method,
        $location,
        :%headers,
        :&data-callback,
        :%state;
    }

    %response<redirects> = $_ with %state<redirects>;

    if $!keep-alive
      && $known-length
      && %response<protocol> eq 'HTTP/1.1'
      && quietly %response<headers><connection> ne 'close'
    {
      $!handle = $handle;
    }
    else {
      $handle.close;
    }

    return %response;
  }

  my class Handle {
    my constant BUFFER-SIZE = 32_768;

    has Str      $!scheme;
    has Str      $!host;
    has Int      $!port;
    has Thread     $!thread;
    has Int      $!timeout      is built = 180;
    has Int      $!max-header-lines is built = 64;
    has IO::Socket $!handle handles 'close';

    my Lock $lock .= new;

    method connect (
      ::?CLASS:D:
         Str:D $url,
    ) {
      my ( $scheme, $host, $port ) = split-url($url);

      die "Unsupported URL host '$host'"
        if $host ~~ / ^ '[' .* ']' $ /;

      given $scheme {
        when 'https' {
          with Pakku::HTTP.can-ssl {
            $lock.lock;
            try require ::('IO::Socket::SSL');
            $lock.unlock;

            die 'Could not load IO::Socket::SSL'
              if ::('IO::Socket::SSL') ~~ Failure;

            $!handle = ::('IO::Socket::SSL').new: :$host, :$port;
          }
          else {
            die "HTTPS requests not supported: { .exception.message }";
          }
        }
        when 'http' {
          $!handle = IO::Socket::INET.new: :$host, :$port;
        }
        default {
          die "Unsupported URL scheme '$scheme'";
        }
      }

      $!host   = $host;
      $!port   = $port;
      $!scheme = $scheme;
      $!thread = $*THREAD;

      return;
    }

    method upgrade ( Str $url, %headers ) {
      die "HTTPS requests not supported: { .exception.message }"
        without Pakku::HTTP.can-ssl;

      my %connect-headers = (
        host => $url,
        user-agent => %headers<user-agent>
      );

      %connect-headers<proxy-authorization>
        = $_ with %headers<proxy-authorization>:delete;

      self.write-request: 'CONNECT', $url, %connect-headers;

      my ( %response, Blob[uint8] $head, Blob[uint8] $body );
      repeat while %response<status>.starts-with: '1' {
        ( $head, $body ) = self.get-response-header: $body;
        %response = self.read-response-header($head);
      }

      # If CONNECT failed, throw the response so it will be
      # returned from the original request() method;
      unless %response<success> {
        my $message = %response<status> == 599
          ?? %response<content>.decode
          !! %response< status reason >.join: ' ';

        X::Pakku::HTTP.new( :%response, :$message ).throw;
      }

      # Upgrade plain socket to SSL now that tunnel is established
      $lock.lock;
      try require ::('IO::Socket::SSL');
      $lock.unlock;

      die 'Could not load IO::Socket::SSL'
        if ::('IO::Socket::SSL') ~~ Failure;

      $!handle = ::('IO::Socket::SSL').new: client-socket => $!handle;

      return;
    }

    submethod DESTROY { try $!handle.close }

    multi method can-reuse ( ::?CLASS:U: |c --> False ) {;}
    multi method can-reuse ( ::?CLASS:D: $scheme, $host, $port --> Bool ) {
      return $!thread ~~ $*THREAD
        && $!scheme eq $scheme
        && $!host eq $host
        && $!port == $port;
    }

    my constant   LINE-END = Blob[uint8].new: 13, 10;
    my constant HEADER-END = Blob[uint8].new: 13, 10, 13, 10;

    my sub blob-search ( Blob[uint8] $haystack, Blob[uint8] $needle --> Int ) {
      my Int $end;
      my $length = $needle.bytes;
      while ++$end < $haystack.bytes {
        return $end if $needle eq $haystack.subbuf: $end, $length;
      }
      return Int;
    }

    method write-request (
      $method,
      $path,
      %headers,
      &content?,
      &trailer-callback?,
    ) {
      self.write-request-header: $method, $path, %headers;
      return unless defined &content;
      return self.write-request-body: $_, &content
        with %headers<content-length>;
      return self.write-chunked-body: &content, &trailer-callback;
    }

    method write-request-header ( $method, $path, %headers ) {
      given "$method $path HTTP/1.1\x0D\x0A" {
        $!handle.print($_);
      }

      self.write-header-lines: %headers;
    }

    method write-header-lines ( %headers ) {
      return unless %headers;

      my @headers = < host cache-control expect max-forwards pragma range te >;
      @headers.push: |%headers.keys.sort;

      my $buf = '';
      my SetHash $seen;
      for @headers -> $key {
        next if $seen{$key}++;
        my $v = %headers{$key};
        next unless defined $v;

        my $field-name = lc $key;
        with HEADER-CASE{$field-name} -> $canonical {
          $field-name = $canonical;
        }
        else {
          s:g/ <|w> (\w) /$0.uc()/ given $field-name;
        }

        for $v.List -> $value {
          $buf ~= "$field-name: $value\x0D\x0A";
        }
      }

      $buf ~= "\x0D\x0A";

      $!handle.print: $buf;
    }

    method write-request-body ( $content-length, &content ) {
      my $length = 0;
      while &content.() -> $blob {
        last unless $blob && $blob.bytes;
        $length += $blob.bytes;
        $!handle.write: $blob;
      }

      die "Content-Length mismatch (got: $length expected: $content-length"
        unless $length == $content-length;

      return;
    }

    method write-chunked-body ( &content, &trailer-callback ) {
      while &content.() -> $blob {
        last unless $blob && $blob.bytes;
        $!handle.write: "{ $blob.bytes.base: 16 }\r\n".encode;
        $!handle.write: $blob;
        $!handle.write: "\r\n".encode;
      }
      $!handle.write: "0\r\n\r\n".encode;

      self.write-header-lines: .() with &trailer-callback;
    }

    method get-response-header ( Blob[uint8] $chunk is rw, Bool :$trailer ) {
      $chunk .= new without $chunk;

      my $msg-body-pos;
      my Blob[uint8] $first-chunk .= new: $chunk;

      # Header can be longer than one chunk
      loop {
        last if $trailer && $first-chunk eq LINE-END;

        # Find the header/body separator in the chunk, which means
        # we can parse the header separately.
        $msg-body-pos = $first-chunk.&blob-search: HEADER-END;
        last if $msg-body-pos;

        my $blob = $!handle.recv: |( 1 if $trailer ), :bin;
        last unless $blob;

        $first-chunk ~= $blob;
      }

      # If the header would indicate that there won't
      # be any content there may not be a \r\n\r\n at
      # the end of the header.
      with $msg-body-pos {
        my $head = $first-chunk.subbuf: 0, $_ + 4;
        my $body = $first-chunk.subbuf:    $_ + 4;
        return $head, $body;
      }

      # Assume we have the whole header because if the server
      # didn't send it we're stuffed anyway
      return $first-chunk, Blob[uint8].new;
    }

    method read-response-header ( Blob[uint8] $header ) {
      my @header-lines = $header.decode('latin1').lines;

      my $status-line = try @header-lines.shift // '';

      $status-line ~~ /
        ^
        $<protocol> = [ 'HTTP/1.' [ 0 | 1 ] ] <[ \x09 \x20 ]>+
        $<status> = [ \d ** 3 ]       <[ \x09 \x20 ]>+
        $<reason> = <-[ \x0D \x0A ]>*
      / or die "Malformed Status-Line: $status-line";

      return {
        protocol => ~$<protocol>,
        status   => +$<status>,
        reason   => ~$<reason>,
        headers  => self.read-header-lines(@header-lines),
        success  => $<status>.starts-with('2'),
      }
    }

    method read-header-lines (@lines) {
      die "Header lines exceed maximum allowed of $!max-header-lines"
        if @lines >= $!max-header-lines;

      my ( $val, %headers );
      for @lines {

        when /
          ^
          $<key>   = <-[ \x00 .. \x1F \x7F : ]>+ ':' <[ \x09 \x20 ]>*
          $<value> = <-[ \x0D \x0A ]>*
        / {
          my $key   = lc $<key>;
          my $value = ~$<value>;

          if %headers{$key}:exists {
            %headers{$key} .= Array;
            %headers{$key}.push: $value;
            $val := %headers{$key}.tail;

          }
          else {
            %headers{$key} = $value;
            $val := %headers{$key};
          }
        }

        when /
          ^
          <[ \x09 \x20 ]>+
          $<cont> = <-[ \x0D \x0A ]>*
        / {
          die "Unexpected header continuation line" unless $val.defined;

          if ~$<cont> -> $cont {
            $val ~= ' ' if $val;
            $val ~= $cont;
          }
        }

        when .not {
           last;
        }

        default {
          die "Malformed header line: $_";
        }
      }

      return %headers;
    }

    method read-content ( &cb, Blob[uint8] $body is rw, %res --> Bool ) {
      my %headers = %res<headers>;

      # Multipart response
      with %headers<content-type>.first: {
        .defined
        && /
          ^
          'multipart/' .*
          'boundary=' '"'? <( <-["]>+ )>
        /
      } {
        self!read-multipart-content( &cb, ~$/, $body );
        return True;
      }

      # Internal callbacks with arity greater than two are meaningless
      # past this point, so we simplify things.
      my &callback = &cb.arity == 1 ?? &cb !! &cb.assuming: *, Nil;

      # With content length
      with %res<headers><content-length> -> Int() $length {
        $body .= subbuf: 0, $length;

        my $bytes-read = $body.bytes;
        callback($body) if $bytes-read;

        while $bytes-read < $length {
          my $read = min $length - $bytes-read, BUFFER-SIZE;
          my $blob = $!handle.read: $read;
          callback($blob);
          $bytes-read += $blob.bytes;
        }

        return True;
      }

      # Chunked content
      my $encoding = %res<headers><transfer-encoding>;
      if $encoding.grep: { .defined && /chunked/ } {
        my $footer = self!read-chunked-content( &cb, $body );

        # Read trailing headers
        %res<headers>.append(
          self.read-header-lines: $footer.decode('latin1').lines
        ) if $footer.bytes;

        return True;
      }

      # Otherwise read until EOF
      $body.&cb;
      while $!handle.read( BUFFER-SIZE ) -> $_ { .&cb }
      return False;
    }

    method !read-chunked-content ( &cb, Blob[uint8] $chunk is rw --> Blob[uint8] ) {
      # We carry on as long as we receive something.
      PARSE_CHUNK: loop {
        with $chunk.&blob-search: LINE-END {
          my $size = $chunk.subbuf( 0, $_ ).decode;

          # remove optional chunk extensions
          $size = $size.subst: / ';' .* $ /, '';

          # www.yahoo.com sends additional spaces (may be invalid)
          $size .= trim-trailing;

          $chunk = $chunk.subbuf: $_ + 2;
          my $chunk-size = :16($size);

          last PARSE_CHUNK if $chunk-size == 0;

          while $chunk-size + 2 > $chunk.bytes {
            $chunk ~= $!handle.recv:
              $chunk-size + 2 - $chunk.bytes, :bin;
          }

          # Callback
          $chunk.subbuf( 0, $chunk-size ).&cb;

          $chunk = $chunk.subbuf: $chunk-size + 2;
        }
        else {
          # XXX Reading 1 byte is inefficient code.
          #
          # But IO::Socket#read/IO::Socket#recv reads from socket
          # until it fills the requested size.
          #
          # It can cause hang-up on socket reading.
          my $byte = $!handle.recv: 1, :bin;
          last PARSE_CHUNK unless $byte.elems;
          $chunk ~= $byte;
        }
      }

      # Return all that is left, to parse possible trailers
      my ($trailer) = self.get-response-header: $chunk, :trailer;
      return $trailer;
    }

    method !read-multipart-content ( &cb, Str:D $boundary, Blob[uint8] $body is copy ) {
      # Callbacks for multipart responses will be called with two
      # arguments, so we need to normalise in case this one only
      # takes one.
      my &callback = &cb.arity == 1 ?? -> $blob, $ { $blob.&cb } !! &cb;
      my $end-of-stream = "--$boundary--".encode( 'ascii', replacement => '?' );

      loop {
        with $body.&blob-search: HEADER-END {
          my $head = $body.subbuf: 0, $_ + 4;

          my ( $marker, @header-lines ) = $head.decode('latin1').lines;
          die "Invalid multipart boundary marker: $marker"
            unless $marker eq "--$boundary";

          my %headers = self.read-header-lines: @header-lines;
          with %headers<content-range> {
            die "Invalid Content-Range header: $_"
              unless /
                ^ 'bytes '
                $<start> = \d+ '-' $<end> = \d*
                '/'
                $<total> = \d+
                $
              /;
          }

          # Start and end are zero-based, but total is one-based
          my $length = ( $<end> // ( $<total> - 1 ) ) - +$<start> + 1;

          # We make a distinction between the bytes in the current
          # part and the bytes in the rest of the response body that
          # belong to possible other parts
          my $part = $body.subbuf: $head.bytes, $length;
          $body .= subbuf: $head.bytes + $part.bytes;

          my $read-bytes = $part.bytes;

          # It's possible for the current part to be greater than
          # the size of the current response chunk we have. If so,
          # we need to continue reading until we have the entire
          # part
          loop {
            callback( $part, %headers );
            last if $read-bytes >= $length;

            my $read = $!handle.read: BUFFER-SIZE;
            die "Did not receive full byte range"
              if !$read && $read-bytes < $length;

            $read-bytes += $read.bytes;

            # Including the bytes we have just read, we have more
            # than the full part, so we save the rest in $body for
            # further processing.
            if $read-bytes > $length {
              my $want = $read-bytes - $length;
              $part = $read.subbuf: 0, *-$want - 1;
              $body = $read.subbuf:  *-$want;
            }
            else {
              $part = $read;
            }
          }

          # Discard the CRLF preceding the next separator
          $body .= subbuf: 2;
        }
        else {
          # We have not read the header yet, need more
          my $read = $!handle.read: BUFFER-SIZE or last;
          $body ~= $read;
        }

        with $end-of-stream {
          last if $body.subbuf( 0, .bytes ) eq $_;
        }
      }

      return;
    }
  }
}

