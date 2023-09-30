[![Linux](https://github.com/hythm7/Pakku/actions/workflows/linux.yml/badge.svg)](https://github.com/hythm7/Pakku/actions/workflows/linux.yml)
[![macOS](https://github.com/hythm7/Pakku/actions/workflows/mac.yml/badge.svg)](https://github.com/hythm7/Pakku/actions/workflows/mac.yml)
[![Windows](https://github.com/hythm7/Pakku/actions/workflows/windows.yml/badge.svg)](https://github.com/hythm7/Pakku/actions/workflows/windows.yml)

[![SparrowCI](https://ci.sparrowhub.io/project/git-hythm7-Pakku/badge?foo=bar)](https://ci.sparrowhub.io)

Pakku
=====
Package Manager for the Raku Programming Language.

Installation
============
<pre>
# <b>Install</b>
git clone https://github.com/hythm7/Pakku.git
cd Pakku
raku -I. bin/pakku add .

# <b>Install using Zef</b>
zef install Pakku
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
<b>pakku add dist</b>                           # add dist
<b>pakku add notest  dist</b>                   # add dist without testing
<b>pakku add nodeps  dist</b>                   # add dist but dont add dependencies
<b>pakku add serial  dist</b>                   # add dists in serial order
<b>pakku add deps only dist</b>                 # add dist dependencies but dont add dist
<b>pakku add exclude Dep1 dist</b>              # add dist and exclude Dep1 from dependenncies
<b>pakku add noprecomp notest  dist</b>         # add dist without testing and no precompilation
<b>pakku add contained to   /opt/MyApp dist</b> # add dist and all transitive deps to custom repo
<b>pakku add to   vendor     dist1 dist2</b>    # add dist1 and dist2 to vendor repo even if they are installed
</pre>


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
<b>pakku list repo /opt/MyApp dist</b>    # list installed dist in custom repo
</pre>



### search
Search available distributions

**options:**

<pre>
latest           → latest version
relaxed          → relaxed search
details          → details of dist
count < number > → number of dists to be returned
norelaxed        → no relaxed search
</pre>

<b>Examples:</b>
<pre>
<b>pakku search dist</b>               # search distributions matching dist (ignored case) on online recman
<b>pakku search latest dist</b>        # show latest version
<b>pakku search norelaxed dist</b>     # no relaxed search
<b>pakku search count 4 dist</b>       # search dist and return the lates 4 versions only
<b>pakku search details dist</b>       # search dist and list all details
</pre>



### build
Build distributions

<b>Examples:</b>
<pre>
<b>pakku build dist</b>
<b>pakku build .</b>
</pre>


### test
Test distributions

**options:**

<pre>
xtest   → XTest distribution
build   → Build distribution
noxtest → Bypass xtest
nobuild → Bypass build
</pre>

<b>Examples:</b>
<pre>
<b>pakku test dist</b>
<b>pakku test ./dist</b>
<b>pakku test xtest ./dist</b>
<b>pakku test nobuild ./dist</b>
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


### nuke
Nuke directories

<b>Examples:</b>
<pre>
<b>pakku nuke cache</b>    # nuke cache 
<b>pakku nuke pakku</b>    # nuke pakku home directory
<b>pakku nuke home</b>     # nuke home repo
<b>pakku nuke site</b>     # nuke site repo
<b>pakku nuke vendor</b>   # nuke vendor repo
</pre>


### config
Each Pakku command like `add`, `remove`, `search` etc. corresponds to a config module with the same name in the config file.
one can use config command to `enable`, `disable`, `set`, `unset` an option in the config file.


**options:**

<pre>
enable        → enable option
disable       → disable option
set < value > → set option to value 
unset         → unset option
</pre>


<b>Examples:</b>
<pre>
<b>pakku config</b>                             # view all config modules
<b>pakku config new</b>                         # create a new config file
<b>pakku config add</b>                         # view add config module
<b>pakku config add precompile</b>              # view <b>precompile</b> option in <b>add</b> config module
<b>pakku config add enable xtest</b>            # enable option <b>xtest</b> in <b>add</b> module 
<b>pakku config add set to home</b>             # set option <b>to</b> to <b>home</b> (change default repo to home) in <b>add</b> module 
<b>pakku config pakku enable async</b>          # enable  option <b>async</b> in <b>pakku</b> module (general options) 
<b>pakku config pakku unset verbose</b>         # unset option <b>verbose</b> in <b>pakku</b> module 
<b>pakku config recman MyRec disable</b>        # disable recman named <b>MyRec</b> in <b>recman</b> module
<b>pakku config recman MyRec set priority 1</b> # set recman <b>MyRec</b>'s priority to 1 in <b>recman</b> module
<b>pakku config add reset</b>                   # reset <b>add</b> config module to default
<b>pakku config reset</b>                       # reset all config modules to default
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
recman              → enable all remote recommendation manager
recman   < MyRec >  → use MyRec recommendation manager only
norecman            → disable all remote recommendation manager
norecman < MyRec >  → use all recommendation managers excepts MyRec
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
<b>pakku pretty  please remove dist</b>
</pre>



<h3>Feeling Rakuish Today?</h3>

Most of `Pakku` commands and options can be written in shorter form, for example:
<pre>
add    → a  update   → u  yolo     → y  nopretty → np  nothing → «N 0»
remove → r  download → d  exclude  → x  nodeps   → nd  all     → «A 6»
list   → l  help     → h  deps     → d  noforce  → nf  debug   → «D 5»
search → s  verbose  → v  force    → f  notest   → nt  now     → «N 4»
build  → b  pretty   → p  details  → d  nobuild  → nb  info    → «I 3»
test   → t  only     → o  norecman → nr nocache  → nc  warn    → «W 2»
									     
</pre>

The below are `Pakku` commands as well!
<pre>
<b>pakku 👓 🧚 ↓   dist</b>
<b>pakku ↪</b>
<b>pakku ❓</b>
</pre>

## ENV Options

Options can be set via environment variables as well:

**General**
<pre>
PAKKU_VERBOSE PAKKU_CACHE PAKKU_RECMAN PAKKU_NORECMAN PAKKU_CONFIG PAKKU_DONT
PAKKU_FORCE PAKKU_PRETTY PAKKU_BAR PAKKU_SPINNER PAKKU_ASYNC PAKKU_CORES PAKKU_YOLO 
</pre>

**Add**
<pre>
PAKKU_ADD_TO PAKKU_ADD_DEPS PAKKU_ADD_TEST PAKKU_ADD_BUILD PAKKU_ADD_XTEST
PAKKU_ADD_SERIAL PAKKU_ADD_PRECOMPILE PAKKU_ADD_EXCLUDE
</pre>

**Test**
<pre>
PAKKU_TEST_BUILD PAKKU_TEST_XTEST
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
PAKKU_STATE_CLEAN> PAKKU_STATE_UPDATES
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
🦋 FTC → fetching
🦋 BLD → building
🦋 STG → staging
🦋 TST → testing
🧚 BLD → build success
🧚 TST → test success
🧚 BIN → binary added
🐞 WAI → waiting
🐞 TOT → timed out
🦗 SPC → error processing Spec
🦗 MTA → error processing Meta
🦗 BLD → build failure
🦗 TST → test failure
🦗 CNF → config error
🦗 CMD → command error
```

**Pakku verbosity levels:**

	- 1 `｢ all ｣`   🐝 → All avaialble output
	- 2 `｢debug｣`   🐛 → Debug output
	- 3 `｢ now ｣`   🦋 → What is happenning now
	- 4 `｢info ｣`   🧚 → Important things only
	- 5 `｢warn ｣`   🐞 → Warnings only
	- 6 `｢error｣`   🦗 → Errors only
	- 0 `｢nothing｣`    → Nothing

> [!WARNING]
> Pakku uses emoji and ANSI escape codes, If your terminal doesn't support them, you can disable colors, bars and spinners, (eg. `pakku nopretty nobar nospinner add Foo`), or disable permanently in config file. also for emojis, eg. to change the `debug` emoji for example, in config file replace `"debug": {"prefix": "🐛"}` with `"debug": {"prefix": "D"}`.


**Command result**:
  - `-Ofun` - Success
  - `Nofun` - Failure


Gotchas
=======
**Caching downloaded distributions**

When one installs a distribution via `pakku add dist`, Pakku first looks in the local cache to see if there is a downloaded distribution matches `dist` specification, if nothing found in the cache, Pakku then searches the configured `RecMan` and obtain the latest version of `dist` (e.g. `dist:ver<0.4.1>`), download, cache, and install it.

After sometime when a new version `dist:ver<0.4.2>` is released and available in `RecMan`, if one try to install `dist` via `pakku add dist`, what happens is Pakku will find `dist:ver<0.4.1>` available in local cache and will install that version because it matches `dist` specification. so one will not get the latest version `dist:ver<0.4.2>`.

There are two ways to avoid this and get the latest version, either specify the version e.g. `pakku add  dist:ver<0.4.2>` or disable cache lookup e.g. `pakku nocache add dist` (also, one can permenantly disable cache in config file).


**Pakku installs to _site_ repo by default**

If the user doesn't have `rw` permision to `site` repo, one can change the default repo to `home` in config file using:

```pakku config add set to home```

or specify the repo in the command e.g. `pakku add to home dist`

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
Copyright 2023 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
