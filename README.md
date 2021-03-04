WHAT?
=====
`Pakku` - A Package Manager for `Raku`.

WHY?
====
TMTOWTDI

WHEN?
=====
`Pakku` is now at version `pupa` and growing towards version `adult`. Currently `Pakku` can do many things like adding, removing, listing and downloading distributions.

INSTALLATION
============
Requires `git`, `curl` and `tar` be available in `$PATH`
<pre>
git clone https://github.com/hythm7/Pakku.git

cd Pakku

# install to home directory
./tools/install-pakku.raku

# --dest=/path/to/pakku     # Install to a different directory
# --verbose=<0 1 2 3 4 5 6> # verbosity level
# --pretty                  # colors
</pre>

Overview
========
* `Pakku` is a simple package manager for `Raku`, with many options and customizations that can be configured in `pakku.cnf` file or via command line options.

* `Pakku` command result is either:
  - `-Ofun` - Desired operation completed successfully
  - `Nofun` - Desired operation did not complete successfully

* `Pakku` verbosity levels:
  - `0 (silent)`   - No output what so ever 
  - `1 (trace)` 🤓 - If you want to see everything
  - `2 (debug)` 🐞 - To debug some issue
  - `3 (info )` 🦋 - Camelia delivers important things
  - `4 (warn )` 🔔 - Only when some warnings happen
  - `5 (error)` ❌ - When errors are what you care about
  - `6 (fatal)` 💀 - You probably don't like to see that when running Pakku, me neither!


* `Pakku` output meaning:
```
🦋 PRC: ｢ ... ｣ → Start processing...
🐞 SPC: ｢ ... ｣ → Spec
🐞 MTA: ｢ ... ｣ → Meta
🐞 FTC: ｢ ... ｣ → Fetch
🐞 BLD: ｢ ... ｣ → Building dist
🐞 TST: ｢ ... ｣ → Testing dist
🐞 ADD: ｢ ... ｣ → Adding dist
🦋 BLD: ｢ ... ｣ → Built dist
🦋 TST: ｢ ... ｣ → Tested dist
🦋 RES: ｢ ... ｣ → Resource
🦋 BIN: ｢ ... ｣ → Biniary
🦋 ADD: ｢ ... ｣ → Added dist
🐞 PAC: ｢ ... ｣ → Packing rakudo and dist 
🦋 PAC: ｢ ... ｣ → Pack location
🐞 WAI: ｢ ... ｣ → Waiting
🔔 TOT: ｢ ... ｣ → Timed out
💀 MTA: ｢ ... ｣ → Meta error
💀 BLD: ｢ ... ｣ → Buld failed
💀 TST: ｢ ... ｣ → Test failed
💀 CNF: ｢ ... ｣ → Config error
💀 CMD: ｢ ... ｣ → Command error
```

* `Pakku` uses [Pakku::RecMan](https://github.com/hythm7/Pakku-RecMan) recommendation manager to obtain distributions `META` info and archives.

USAGE
=====
**Add distribution**

<pre>
<b>pakku add MyModule</b>
<b>pakku add nodeps MyModule</b>
<b>pakku add notest MyModule</b>
<b>pakku add to     /opt/MyApp MyModule</b>
<b>pakku add force  to   home  MyModule1 MyModule2</b>

<b>Options:</b> Specific to <b>add</b> command

deps            → add dependencies
nodeps          → no dependencies
deps runtime    → add runtime dependencies
deps test       → add test    dependencies
deps build      → add build dependencies
deps requires   → only required dependencies
deps recommends → required and recommended dependencies as well
deps suggests   → required, recommended and suggested dependencies
deps only       → dont add the distribution, only it's dependencies
build           → build distribution
nobuild         → bypass build
test            → test distribution
notest          → bypass test
force           → force add distribution even if installed
noforce         → no force
to < repo >     → add distribution to repo < home site vendor core /path/to/MyApp >
</pre>

**Remove distribution**
<pre>
<b>pakku remove MyModule</b>

<b>Options:</b> Specific to <b>remove</b> command

from < repo > → remove distribution from provided repo only
</pre>


**List distribution**
<pre>
<b>pakku list</b>
<b>pakku list MyModule</b>
<b>pakku list details MyModule</b>
<b>pakku list repo home</b>
<b>pakku list repo /opt/MyApp MyModule</b>

<b>Options:</b> Specific to <b>list</b> command

details               → list details of dist
repo < name-or-path > → list dists installed in specific repo
</pre>


**Search distribution on RecMan**
<pre>
<b>pakku Search MyModule</b>
<b>pakku Search details MyModule</b>

<b>Options:</b> Specific to <b>search</b> command

count < number > → return how many dists
details          → list details of dist
</pre>


**Pack rakudo and distribution**
<pre>
<b>pakku pack MyModule</b>
<b>pakku pack notest MyModule</b>
<b>pakku pack rakudo 2020.10 MyModule</b>
<b>pakku pack to     /opt/MyApp MyModule</b>

<b>Options:</b> Specific to <b>pack</b> command

to < path > → pack to path /path/to/MyApp>
rakudo ver  → package rakudo specific version
< addopts > → add command options are available here as well
</pre>


**Build distribution**
<pre>
<b>pakku build MyModule</b>
<b>pakku build .</b>
</pre>


**Test distribution**
<pre>
<b>pakku test MyModule</b>
<b>pakku test ./MyModule</b>
</pre>


**Checkout (download) distribution**

<pre>
<b>pakku checkout MyModule</b>
</pre>


**Pakku Options**

<pre>
<b>pakku dont     add MyModule</b>
<b>pakku nopretty add MyModule</b>
<b>pakku yolo     add MyFailedModule MyModule</b>
<b>pakku pretty   please remove MyModule</b>

<b>Options:</b> Global options control general Pakku behavior and placed before Pakku commands < add remove ... >

pretty            → colors
nopretty          → no colors
dont              → do everything but dont do it (dry run)
verbose < level > → verbosity < silent trace debug info warn error fatal >
please            → be nice to butterflies
yolo              → dont stop on errors, useful when need to proceed after error (e.g. Test Faliure)
</pre>


**Print Help**

<pre>
<b>pakku</b>
<b>pakku add</b>
<b>pakku help</b>
<b>pakku help list</b>
<b>pakku help help</b>
</pre>


<h3>Feeling Rakuish Today?</h3>

Most of `Pakku` commands and options can be written in shorter form, for example:
<pre>
add       → a     verbose → v     nopretty → np     silent → «S 0»
remove    → r     pretty  → p     nodeps   → nd     trace  → «T 1»
list      → l     only    → o     noforce  → nf     debug  → «D 2»
search    → s     deps    → d     notest   → nt     info   → «I 3»
build     → b     force   → f     nobuild  → nb     warn   → «W 4»
test      → t     details → d                       error  → «E 5»
checkout  → c     yolo    → y                       fatal  → «F 6»
help      → h     
</pre>

Did I mention that the below are `Pakku` commands as well?
<pre>
<b>pakku 𝛒 ↓ 🔗 🔨 MyModule</b>
<b>pakku 👓 🦋 ↑   MyModule</b>
<b>pakku 🌎        MyModule</b>
<b>pakku ↪</b>
<b>pakku ❓</b>
</pre>


CONFIGURATION
=============
All options can be set in command line or in the config file <b>pakku.cnf</b> ｢`~/.pakku/pakku.cnf`｣. The only needed config is `<recman>` source, otherwise you will be able to install local distributions only.

Config file example:

<pre>
### pakku Config

# < pakku >
  # pretty           # colors
  # verbose info     # < 0 1 2 3 4 5 6 >
  # dont             # dont do it (dry run)

# < add >
  # deps       # add deps as well < deps nodeps >
  # build      # build            < build nobuild >
  # test       # test             < test notest >
  # force      # force install    < force noforce >
  # to  home   # add to specific repo < home site vendor core /custom/repo/path >

# < remove >
  # from home  # remove from specific repo

# < list >
  # details # list   details of dists

## Customize verbosity levels symbols and colors
# < log >
  # trace name T:
  # debug name D:
  # info  name I:
  # warn  name W:
  # error name E:
  # fatal name F:

  # trace color reset
  # debug color green
  # info  color blue
  # warn  color yellow
  # error color magenta
  # fatal color red

< recman >
http://recman.pakku.org

</pre>


CAVEATS
=======
Currently `Pakku` runs on Linux, more operating systems will be supported in the future.


CREDITS
=======
Thanks to `Panda` and `Zef` for `Pakku` inspiration.
also Thanks to the nice `#raku` community.

MOTTO
===========
Light like a 🦋, Colorful like a 🦋

AUTHOR
======
Haytham Elganiny `elganiny.haytham at gmail.com`

COPYRIGHT AND LICENSE
=====================
Copyright 2019 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

