use X::Pakku;
use Pakku::Log;
use Pakku::Util;
use Pakku::Curl;

# The single network seam: download a URL (or copy a local path) to a file.
# Backends, probed once: libcurl (NativeCall), then the curl binary, then wget.
unit class Pakku::Fetch;

constant IS-WIN = Rakudo::Internals.IS-WIN();

has Int:D $.timeout         = 300;
has Int:D $.connect-timeout = 30;
has Str   $.backend;                     # libcurl | curl | wget ; probed lazily unless given

my $agent = 'Pakku/' ~ ( $?DISTRIBUTION.meta<ver> // $?DISTRIBUTION.meta<version> // 'dev' );

method backend ( ::?CLASS:D: --> Str:D ) {

  $!backend //= do {

    if Pakku::Curl.available { 'libcurl' }
    else {
      ( IS-WIN ?? <curl.exe curl wget.exe wget> !! <curl wget> ).first( -> $bin { find-bin $bin } )
        // die X::Pakku::Fetch.new: msg => 'curl', comment => 'no libcurl, curl or wget found!';
    }
  }

}

method download (
  ::?CLASS:D:
  Str:D      :$url!,
  IO::Path:D :$dst!,
  Int:D      :$timeout  = $!timeout,
  Bool:D     :$progress = False,
  --> IO::Path:D
) {

  $dst.parent.mkdir;

  given $url {

    when / ^ 'http' 's'? '://' / { self!remote: :$url :$dst :$timeout :$progress }

    when / ^ 'file://' /         { self!local: src => .subst( / ^ 'file://' /, '' ).IO, :$dst }

    default                      { self!local: src => .IO, :$dst }

  }

}

# a git repository into a directory: url, url#tag, url#branch or url#sha (needs the git binary)
method clone ( ::?CLASS:D: Str:D :$url!, IO::Path:D :$dst! --> IO::Path:D ) {

  my $git = ( IS-WIN ?? <git.exe git> !! <git> ).first( -> $bin { find-bin $bin } )
    // die X::Pakku::Fetch.new: msg => redact( $url ), comment => 'git not found!';

  my ( $repo, $ref ) = $url.split( '#', 2 );

  my $sha = so $ref and $ref ~~ / ^ <xdigit> ** 7..40 $ /;

  $dst.parent.mkdir;

  log '🐛', header => 'FTC', msg => redact( $repo ), comment => $ref ?? "git $ref" !! 'git';

  self!git: $git, 'clone', '--quiet', |( '--depth', '1' unless $sha ), |( '--branch', $ref if $ref and not $sha ), '--', $repo, ~$dst;
  self!git: $git, '-C', ~$dst, 'checkout', '--quiet', $ref if $sha;

  try remove-dir $dst.add( '.git' );   # the dist, not its history

  $dst;

}

method !git ( *@cmd --> Nil ) {

  log '🐛', header => 'FTC', msg => ~@cmd;

  my $proc = run |@cmd, :out, :err;

  my $err = $proc.err.slurp( :close );

  $proc.out.slurp( :close );

  die X::Pakku::Fetch.new: msg => 'git', comment => ( $err.trim.lines.tail // "exit { $proc.exitcode }" ) if $proc.exitcode;

}

method !local ( IO::Path:D :$src!, IO::Path:D :$dst! --> IO::Path:D ) {

  die X::Pakku::Fetch.new: msg => ~$src, comment => 'no such file!' unless $src.f;

  $src.copy: $dst;

  $dst;

}

method !remote ( Str:D :$url!, IO::Path:D :$dst!, Int:D :$timeout!, Bool:D :$progress! --> IO::Path:D ) {

  my $part = $dst.sibling( $dst.basename ~ ".$*PID.part" );

  log '🐛', header => 'FTC', msg => redact( $url ), comment => self.backend;

  {
    CATCH { default { try unlink $part; .rethrow } }

    given self.backend {

      when 'libcurl' { Pakku::Curl.download: :$url, dst => $part, :$timeout, :$!connect-timeout, :$agent, :$progress }

      default        { self!shell: $_, :$url, dst => $part, :$timeout }

    }
  }

  try unlink $dst if IS-WIN;   # rename over an existing file is not atomic there

  $part.rename: $dst;

  $dst;

}

method !shell ( Str:D $tool, Str:D :$url!, IO::Path:D :$dst!, Int:D :$timeout! --> Nil ) {

  my @cmd = $tool.starts-with( 'curl' )
    ?? ( $tool, '--silent', '--show-error', '--fail', '--location',
         '--max-time', $timeout, '--connect-timeout', $!connect-timeout,
         '--user-agent', $agent, '--output', ~$dst, $url )
    !! ( $tool, '--quiet', "--timeout=$timeout", '--tries=1',
         "--user-agent=$agent", '-O', ~$dst, $url );

  log '🐛', header => 'FTC', msg => ~@cmd;

  my $proc = run |@cmd, :err;

  my $err  = $proc.err.slurp( :close );

  die X::Pakku::Fetch.new: msg => redact( $url ), comment => ( $err.trim || "exit { $proc.exitcode }" ) if $proc.exitcode;

}
