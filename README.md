[![Linux](https://github.com/hythm7/Pakku/actions/workflows/linux.yml/badge.svg)](https://github.com/hythm7/Pakku/actions/workflows/linux.yml)
[![macOS](https://github.com/hythm7/Pakku/actions/workflows/mac.yml/badge.svg)](https://github.com/hythm7/Pakku/actions/workflows/mac.yml)
[![Windows](https://github.com/hythm7/Pakku/actions/workflows/windows.yml/badge.svg)](https://github.com/hythm7/Pakku/actions/workflows/windows.yml)

![Sparky](https://sparky.sparrowhub.io/badge/hythm7-Pakku?foo=bar)

Pakku
=====
Package Manager for the Raku Programming Language.

Installation
============
Pakku needs Rakudo, `libarchive`, and something that speaks HTTPS: `libcurl` (loaded directly),
or the `curl` or `wget` binary (`curl.exe` ships with Windows, nothing to install there).

<pre>
# <b>Install</b>
git clone https://github.com/hythm7/Pakku.git
cd Pakku
raku -I. bin/pakku add .

# <b>Install using Zef</b>
zef install Pakku

# <b>Upgrade</b>
pakku add Pakku
</pre>

Usage
=====
Pakku manages Raku distributions with commands like `add`, `remove`, `update` etc.

Full command consists of:

`pakku [general-options] <command> [command-options] <dists>`

There are two types of options:

**General options:**

These are the options that control the general behavior of Pakku, eg. specify the configuration file, run asynchronously or disable colors. The general options are valid for all commands, and must be placed before the command.

**Command options:**

These are the options that control the specified command, for example when installing a distributions one can add `notest` option to disable testing. these options must be placed after the command.


Ecosystems
==========
Pakku gets its dists from where the dists live: the **fez** ecosystem (https://360.zef.pm).
Dists that never moved to fez are served from the **Raku Ecosystem Archive** (REA), which Pakku
only asks when fez has nothing to offer, and only loads then.

A recommendation manager (`recman` in Pakku speak) is either an **ecosystem** (mirrors serving an
index and tarballs) or a **local** directory of extracted dists. Each ecosystem publishes an index,
one JSON file with every META. Pakku keeps a copy under `~/.pakku/.index/<name>/` and resolves
names, versions and dependencies locally: `search`, `info` and dependency resolution never wait
for a server.

**Index freshness:**

<pre>
<b>pakku add dist</b>              # the index is refreshed when older than its refresh hours (fez 1, rea 24)
<b>pakku refresh</b>               # refresh every index now
<b>pakku refresh rea</b>           # just that one
<b>pakku refresh add dist</b>      # refresh first, then add
<b>pakku norefresh add dist</b>    # never touch the network for the index (offline, with the cache)
<b>pakku nuke index</b>            # forget every index, the next command fetches fresh ones
</pre>

A dist missing from an index older than ten minutes makes Pakku refresh once and look again, so a
dist uploaded a minute ago is not left waiting for the hour to pass.

**Being careful:**

🦋 A fez tarball is named after its SHA-1, Pakku checks the download when `sha1sum`, `shasum` or `certutil` is around.

🦋 Archives are unpacked with suspicion: entries that try to escape the dist directory, links, device
files and lies about sizes are refused, and a half extracted dist is removed.

**Recman config:**

<pre>
<b>pakku config recman</b>                                                             # view the recmans
<b>pakku config recman rea disable</b>                                                 # fez only
<b>pakku config recman fez set refresh 24</b>                                          # refresh fez once a day (true: always, false: never)
<b>pakku config recman fez set mirrors https://mirror.example/,https://360.zef.pm/</b> # mirrors are tried in order
<b>pakku config recman darkpan set mirrors /srv/darkpan/ priority 0</b>                # a directory with an index.json and tarballs, asked first
<b>pakku config recman mydists set location /home/me/dists</b>                        # a local directory of extracted dists
<b>pakku config recman mydists unset</b>                                              # bye
<b>pakku config recman reset</b>                                                      # back to fez and rea
</pre>

An entry has a `name`, a `type` (`ecosystem` or `local`, guessed from `mirrors` or `location` when
not set), `mirrors` and an `index` file name (`index.json`) with a `source` (`path`, as fez does
it, or `source-url`, as REA does it) for ecosystems, a `location` for local ones, `refresh` hours,
a `priority` (lower first) and `active`.

> [!NOTE]
> A config file that still lists the retired `recman.pakku.org` works: Pakku ignores the entry,
> uses the built-in ecosystems, and asks for a `pakku config recman reset`.


## Pakku Commands

### add
Install distributions

**options:**

<pre>
deps                → all dependencies
deps    < build >   → build dependencies only
deps    < test >    → test dependencies only
deps    < runtime > → runtime dependencies only
deps    < only >    → install dependencies but not the dist
exclude < Spec >    → exclude Spec
test                → test distribution
xtest               → xTest distribution
build               → build distribution
serial              → add distributions in serial order
contained           → add distributions and all transitive deps (regardless if they are installed)
precomp             → precompile distribution 
to < repo >         → add distribution to repo < home site vendor core /path/to/MyApp >
nodeps              → no dependencies
nobuild             → bypass build
notest              → bypass test
noxtest             → bypass xtest
noserial            → no serial
noprecomp           → no precompile
</pre>

<b>Examples:</b>
<pre>
<b>pakku add dist</b>                                  # add dist
<b>pakku add notest  dist</b>                          # add dist without testing
<b>pakku add nodeps  dist</b>                          # add dist but dont add dependencies
<b>pakku add serial  dist</b>                          # add dists in serial order
<b>pakku add deps only dist</b>                        # add dist dependencies but dont add dist
<b>pakku add exclude Dep1 dist</b>                     # add dist and exclude Dep1 from dependencies
<b>pakku add noprecomp notest  dist</b>                # add dist without testing and no precompilation
<b>pakku add contained to   /opt/MyApp dist</b>        # add dist and all transitive deps to custom repo
<b>pakku add to   vendor     dist1 dist2</b>           # add dist1 and dist2 to vendor repo even if they are installed
<b>pakku add ./dist</b>                                # a directory with a META6.json
<b>pakku add ./dist-1.0.tar.gz</b>                     # a tarball
<b>pakku add https://host/dist-1.0.tar.gz</b>          # a tarball by URL
<b>pakku add https://github.com/user/dist.git#v1.0</b> # a git repository (#tag, #branch or #sha, needs git)
<b>pakku add 'dist:ver(* > 1.2):auth<zef:user>'</b>    # a spec with a selector, see Specs below
</pre>

`dist` is a name in the ecosystem, `./dist` is a directory: paths start with `./` or `/` (your shell expands `~`).


### remove
Remove distributions

**options:**

<pre>
from < repo > → remove distribution from provided repo only
</pre>

<b>Examples:</b>
<pre>
<b>pakku remove dist</b>            # remove dist from all repos
<b>pakku remove from site dist</b>  # remove dist from site repo only
</pre>



### list
List installed distributions

**options:**

<pre>
details               → details
repo < name-or-path > → list specific repo
</pre>

<b>Examples:</b>
<pre>
<b>pakku list</b>                         # list all installed dists
<b>pakku list dist</b>                    # list installed dist
<b>pakku list details dist</b>            # list installed dist details
<b>pakku list repo home</b>               # list all dists installed to home repo
<b>pakku list repo /opt/MyApp</b>         # list everything installed in custom repo
</pre>



### search
Search the ecosystems, locally and instantly

**options:**

<pre>
latest           → the newest release of each dist and author (default)
nolatest         → every release
relaxed          → dist is anywhere in the name, case ignored (default)
norelaxed        → the exact name
details          → dependencies, provides, source and recman of each hit
count < number > → number of dists to be returned
</pre>

<b>Examples:</b>
<pre>
<b>pakku search dist</b>               # dists whose name contains dist, newest release per author
<b>pakku search nolatest dist</b>      # every release ever published
<b>pakku search norelaxed dist</b>     # the exact name only
<b>pakku search count 4 dist</b>       # at most 4
<b>pakku search details dist</b>       # with details
<b>pakku search 'dist:ver(* > 2)'</b>  # a spec narrows the releases
</pre>



### info
Everything about a dist: the newest release with its dependencies, provides and source, every
release by author, what is installed in which repo, and who depends on it

<b>Examples:</b>
<pre>
<b>pakku info dist</b>
<b>pakku info dist:auth<zef:user></b>
<b>pakku i dist1 dist2</b>
</pre>



### build
Build distributions

**options:**

<pre>
timeout < seconds > → kill a build quiet for that long (default 420, 0 never)
</pre>

<b>Examples:</b>
<pre>
<b>pakku build dist</b>
<b>pakku build .</b>
<b>pakku build ./dist-1.0.tar.gz</b>
</pre>


### test
Test distributions

**options:**

<pre>
xtest               → XTest distribution
build               → Build distribution
noxtest             → Bypass xtest
nobuild             → Bypass build
timeout < seconds > → kill a test quiet for that long (default 420, 0 never)
</pre>

<b>Examples:</b>
<pre>
<b>pakku test dist</b>
<b>pakku test ./dist</b>
<b>pakku test xtest ./dist</b>
<b>pakku test nobuild ./dist</b>
<b>pakku test timeout 1200 ./dist</b>
<b>pakku test https://github.com/user/dist.git</b>
</pre>


### update
Update distributions to latest version

**options:**

<pre>
clean        → clean not needed dists after update 
deps         → update dependencies
nodeps       → no dependencies
exclude Dep1 → exclude Dep1
deps only    → dependencies only
build        → build distribution
nobuild      → bypass build
test         → test distribution
notest       → bypass test
xtest        → xTest distribution
noxtest      → bypass xtest
precomp      → precompile distribution 
noprecomp    → no precompile
noclean      → dont clean unneeded dists 
in < repo >  → update distribution and install in repo < home site vendor core /path/to/MyApp >
</pre>

<b>Examples:</b>
<pre>
<b>pakku update</b>       # update all installed distribution
<b>pakku update dist</b>
<b>pakku update nodeps dist</b>
<b>pakku update notest dist1 dist2</b>
</pre>


### state
Check the state of installed distributions

**options:**

<pre>
updates   → check updates for dists
clean     → clean older versions of dists
noupdates → dont check updates for dists
noclean   → dont clean older versions
</pre>

<b>Examples:</b>
<pre>
<b>pakku state</b>
<b>pakku state dist</b>
<b>pakku state clean  dist</b>
<b>pakku state noupdates  dist</b>
</pre>


### download
Download distribution source

<b>Examples:</b>
<pre>
<b>pakku download dist</b>     # download dist and extract to temp directory
</pre>


### refresh
Refresh the ecosystem indexes without waiting for them to go stale

<b>Examples:</b>
<pre>
<b>pakku refresh</b>           # every active ecosystem
<b>pakku refresh rea</b>       # one of them
<b>pakku refresh add dist</b>  # the general option: refresh, then add
</pre>


### nuke
Nuke directories

<b>Examples:</b>
<pre>
<b>pakku nuke cache</b>       # nuke cache 
<b>pakku nuke index</b>       # nuke the ecosystem indexes (refreshed on next use)
<b>pakku nuke pakku</b>       # nuke pakku home directory (cache, indexes, config)
<b>pakku nuke home</b>        # nuke home repo
<b>pakku nuke site</b>        # nuke site repo
<b>pakku nuke vendor</b>      # nuke vendor repo
<b>pakku force nuke core</b>  # nuke the core repo, Rakudo's own modules (you have been warned)
</pre>


### config
Each Pakku command like `add`, `remove`, `search` etc. corresponds to a config module with the same name in the config file.
one can use config command to `enable`, `disable`, `set`, `unset` an option in the config file.
Values keep their type: `set count 42` stores a number, `set mirrors a/,b/` a list.


**options:**

<pre>
enable        → enable option
disable       → disable option
set < value > → set option to value 
unset         → unset option
reset         → back to the default
</pre>


<b>Examples:</b>
<pre>
<b>pakku config</b>                                   # view all config modules
<b>pakku config new</b>                               # create a new config file
<b>pakku config add</b>                               # view add config module
<b>pakku config add precompile</b>                    # view <b>precompile</b> option in <b>add</b> config module
<b>pakku config add enable xtest</b>                  # enable option <b>xtest</b> in <b>add</b> module 
<b>pakku config add set to home</b>                   # set option <b>to</b> to <b>home</b> (change default repo to home) in <b>add</b> module 
<b>pakku config test set timeout 1200</b>             # patience for slow test suites
<b>pakku config pakku enable async</b>                # enable  option <b>async</b> in <b>pakku</b> module (general options) 
<b>pakku config pakku unset verbose</b>               # unset option <b>verbose</b> in <b>pakku</b> module 
<b>pakku config recman rea disable</b>                # disable recman named <b>rea</b> in <b>recman</b> module
<b>pakku config recman fez set refresh 24</b>         # set recman <b>fez</b>'s refresh hours
<b>pakku config recman mine set mirrors https://a/</b> # a new ecosystem recman named <b>mine</b>
<b>pakku config add reset</b>                         # reset <b>add</b> config module to default
<b>pakku config reset</b>                             # reset all config modules to default
</pre>


### help
Get help on a specific command

<b>Examples:</b>
<pre>
<b>pakku</b>
<b>pakku help add</b>
<b>pakku help list</b>
<b>pakku help remove</b>
<b>pakku add</b>
<b>pakku help</b>
<b>pakku help help</b>
</pre>


## Pakku General Options

<b>Options:</b>

<pre>
pretty              → use colors
force               → use force
async               → run asynchronously (disabled by default because some dists tests are not async safe) 
dont                → do everything but dont do it (dry run)
bar                 → use progress bar
spinner             → use spinner
verbose  < level >  → verbosity < nothing error warn info now debug all >
cores    < number > → number of cores used when run in async mode
config   < path >   → specify config file
cache    < path >   → cache downloaded dists there
recman              → enable all recommendation managers
recman   < MyRec >  → use MyRec recommendation manager only
norecman            → disable all recommendation managers (the cache still answers)
norecman < MyRec >  → use all recommendation managers except MyRec
refresh             → refresh the ecosystem indexes first
norefresh           → never refresh the ecosystem indexes (offline)
nopretty            → no colors
noforce             → no force
nobar               → no progress bar
nospinner           → no spinner
noasync             → dont run asynchronously
nocache             → disable cache
yolo                → proceed if error occured (eg. test failure)
please              → be nice to butterflies
</pre>

<b>Examples:</b>
<pre>
<b>pakku async   add dist</b>                # run in async mode while adding dist
<b>pakku nocache add dist</b>                # dont use cache
<b>pakku dont    add dist</b>                # dont add dist (dry run)
<b>pakku norefresh add dist</b>              # offline, what the index and the cache already know
<b>pakku pretty  please remove dist</b>
</pre>


Specs
=====
A dist is asked for by name, with Raku's own adverbs. Inside `<>` is a string, inside `()` is a
selector, exactly as in a `use` statement:

<pre>
dist                        # whatever is newest
dist:ver<1.2>               # 1.2, 1.2.3, 1.2.anything: a version string is a prefix (Raku's rule)
dist:ver<1.2+>              # 1.2 or newer
dist:ver<1.*>               # any 1.x
dist:auth<zef:user>         # by that author, auth<zef:*> for any author on zef
dist:api<2>
dist:ver(* > 1.2)           # a selector: anything Raku can smartmatch a version against
dist:ver(1.2 .. 2)          # a range, numbers inside ver( ) and api( ) are versions
dist:ver(v1.2 | v1.4)       # a junction
dist:ver((* >= 1.2) & (* < 2))
dist:auth(/^ zef /)         # a regex
dist:ver(Any)               # anything, really
</pre>

Selectors are parsed and evaluated by Raku itself, with one rule: they are data, not code.
Literals, versions, ranges, junctions, regexes, `*` and the comparison and junction operators
are welcome; blocks, calls and variables are refused, because a spec also comes from other
people's META files and from the ecosystem index, and nobody wants `pakku search` running
somebody else's code. Quote the spec in a shell: `pakku add 'dist:ver(* > 1.2)'`. One `*` per
selector: `* > 1 & * < 2` is a single piece of code with two stars, write `(* > 1) & (* < 2)`.

The same specs work in `META6.json` `depends`, in every form S22 describes: plain strings, the hash
form (`name`, `ver`, `auth`, `api`, `from`, `hints`), `any` alternatives (the first one the ecosystem
can serve wins), `runtime` / `build` / `test` phases with `requires` / `recommends` / `suggests`
(only `requires` are required), `by-distro.name`, `by-kernel.name`, `by-env.VAR`, `by-raku.version`
and friends, and `:from<bin>`, `:from<native>`, `:from<Perl5>` for what Pakku can check but not
install.

> [!NOTE]
> Rakudo itself still turns the selector of a `use dist:ver(...)` into a plain string at run time.
> Pakku honours selectors when resolving and installing; what `use` does with them is Rakudo's call.


<h3>Feeling Rakuish Today?</h3>

Most of `Pakku` commands and options can be written in shorter form, straight from the grammar:
<pre>
<b>commands</b>
add → a ↓     update → u up ↑   remove → r      list → l ↪     search → s 🌎   build → b
test → t      download → d      nuke → n        state → st     config → cnf    refresh → rfr 🔄
info → i ℹ    help → h ❓

<b>general options</b>
pretty → p    nopretty → np     force → f       noforce → nf   bar → b         nobar → nb
spinner → s   nospinner → ns    verbose → v 👓  cache → c      nocache → nc    recman → rec
norecman → nrec               norefresh → nrfr   async → sync   noasync        yolo → y ¯\_(ツ)_/¯

<b>command options</b>
deps → d      nodeps → nd       only → o        exclude → x    build → b       nobuild → nb
test → t      notest → nt       xtest → xt      noxtest → nxt  serial → s      noserial → ns
contained → c nocontained → nc  precomp → p     noprecomp → np details → d     nodetails → nd
latest → l    nolatest → nl     relaxed → r     norelaxed → nr count → c       clean → c
noclean → nc  updates → up      noupdates → nu  from → f

<b>verbosity</b>
nothing → N 0   error → E 1   warn → W 2   info → I 3   now → 4 🦋   debug → D 5   all → A 6 🐝
</pre>

The below are `Pakku` commands as well!
<pre>
<b>pakku 👓 🧚 ↓   dist</b>
<b>pakku ↪</b>
<b>pakku ❓</b>
<b>pakku 🔄</b>
</pre>

## ENV Options

Options can be set via environment variables as well. Booleans take `true`, `false`, `yes`, `no`,
`on`, `off`, `1` or `0`.

**General**
<pre>
PAKKU_VERBOSE PAKKU_CACHE PAKKU_RECMAN PAKKU_NORECMAN PAKKU_REFRESH PAKKU_CONFIG PAKKU_DONT
PAKKU_FORCE PAKKU_PRETTY PAKKU_BAR PAKKU_SPINNER PAKKU_ASYNC PAKKU_CORES PAKKU_YOLO 
</pre>

`PAKKU_CACHE` takes `true`, `false` or the path of the cache directory.

**Add**
<pre>
PAKKU_ADD_TO PAKKU_ADD_DEPS PAKKU_ADD_TEST PAKKU_ADD_BUILD PAKKU_ADD_XTEST
PAKKU_ADD_SERIAL PAKKU_ADD_CONTAINED PAKKU_ADD_PRECOMPILE PAKKU_ADD_EXCLUDE
</pre>

**Test**
<pre>
PAKKU_TEST_BUILD PAKKU_TEST_XTEST PAKKU_TEST_TIMEOUT
</pre>

**Build**
<pre>
PAKKU_BUILD_TIMEOUT
</pre>

**Remove**
<pre>
PAKKU_REMOVE_FROM
</pre>

**List**
<pre>
PAKKU_LIST_REPO PAKKU_LIST_DETAILS
</pre>

**Search**
<pre>
PAKKU_SEARCH_LATEST PAKKU_SEARCH_DETAILS PAKKU_SEARCH_RELAXED PAKKU_SEARCH_COUNT 
</pre>

**Update**
<pre>
PAKKU_UPDATE_IN PAKKU_UPDATE_DEPS PAKKU_UPDATE_TEST PAKKU_UPDATE_XTEST PAKKU_UPDATE_BUILD
PAKKU_UPDATE_CLEAN PAKKU_UPDATE_PRECOMPILE PAKKU_UPDATE_EXCLUDE
</pre>

**State**
<pre>
PAKKU_STATE_CLEAN PAKKU_STATE_UPDATES
</pre>


Pakku Output
============

Pakku output aims to be tidy and concise, uses emojis, colors and three letters key words to convey messages.

For example, the `🦋` emoji indicates that Pakku is starting a task, while `🧚` means Pakku successfully completed a task.

An output line like:

`🦋 BLD: ｢Inline::Perl5:ver<0.60>:auth<cpan:NINE>:api<>｣`

means Pakku is starting to build `Inline::Perl5:ver<0.60>:auth<cpan:NINE>:api<>`, and based on the result another output line could be:

`🧚 BLD: ｢Inline::Perl5:ver<0.60>:auth<cpan:NINE>:api<>｣`  # build success

`🦗 BLD: ｢Inline::Perl5:ver<0.60>:auth<cpan:NINE>:api<>｣`  # build failure

Below is a list of output lines that one can see and their meaning:

```
🧚 ADD → start add command
🦋 SPC → processing Spec
🦋 MTA → processing Meta
🦋 IDX → refreshing an ecosystem index
🦋 FTC → fetching
🦋 BLD → building
🦋 STG → staging
🦋 CMP → compiling a module
🦋 TST → testing
🧚 IDX → index refreshed
🧚 RFR → indexes to refresh
🧚 BLD → build success
🧚 TST → test success
🧚 BIN → binary added
🧚 INF → info about a dist
🧚 VER → the releases of a dist
🧚 REP → installed in that repo
🧚 REV → a dist that depends on it
🐞 WAI → waiting
🐞 TOT → timed out
🐞 OLO → yolo: an error was ignored
🦗 SPC → error processing Spec
🦗 MTA → error processing Meta
🦗 IDX → no usable index
🦗 FTC → fetch failure
🦗 ARC → archive refused
🦗 BLD → build failure
🦗 TST → test failure
🦗 CNF → config error
🦗 CMD → command error
```

**Pakku verbosity levels:**

	- 0 `｢nothing｣`    → Nothing
	- 1 `｢error｣`   🦗 → Errors only
	- 2 `｢warn ｣`   🐞 → Warnings and errors
	- 3 `｢info ｣`   🧚 → Important things only (default)
	- 4 `｢ now ｣`   🦋 → What is happening now
	- 5 `｢debug｣`   🐛 → Debug output
	- 6 `｢ all ｣`   🐝 → All available output

> [!WARNING]
> Pakku uses emoji and ANSI escape codes, If your terminal doesn't support them, you can disable colors, bars and spinners, (eg. `pakku nopretty nobar nospinner add Foo`), or disable permanently in config file. also for emojis, eg. to change the `debug` emoji for example, in config file replace `"debug": {"prefix": "🐛"}` with `"debug": {"prefix": "D"}`.


**Command result**:
  - `-Ofun` - Success
  - `Nofun` - Failure


Gotchas
=======
**Index freshness**

Pakku resolves against its local copy of the ecosystem index, refreshed when older than the
recman's `refresh` hours. A dist released a moment ago may not be there yet: `pakku refresh`, or
`pakku refresh add dist`, fetches a fresh index first. The opposite, `pakku norefresh add dist`,
is how one stays offline with what the index and the cache already know. The cache is only asked
when the index cannot answer, so a cached old version never hides a newer release.

**Pakku installs to _site_ repo by default**

If the user doesn't have `rw` permision to `site` repo, one can change the default repo to `home` in config file using:

```pakku config add set to home```

or specify the repo in the command e.g. `pakku add to home dist`

**Paths look like paths**

`pakku add dist` asks the ecosystem for `dist`, `pakku add ./dist` adds the directory. A path
starts with `./` or `/` (your shell expands `~`), a tarball ends with `.tar.gz`, a git repository with `.git`.

Credits
=======
Thanks to `Panda` and `Zef` for `Pakku` inspiration.
also Thanks to the nice `#raku` community.

Motto
=====
Light like a 🧚, Colorful like a 🧚

Author
======
Haytham Elganiny `elganiny.haytham at gmail.com`

Copyright and License
=====================
Copyright 2026 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
