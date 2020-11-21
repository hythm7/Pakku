WHAT?
=====
`Pakku` - A Package Manager for `Raku`

WHY?
====
Because `TMTOWTDI`

WHEN?
=====
`Pakku` is now at version `pupa` and growing towards version `adult`. Currently `Pakku` can do many things like adding, removing, listing and downloading distributions.

INSTALLATION
============
Requires `git`, `curl` and `tar` to be available in `$PATH`
<pre>
git clone https://github.com/hythm7/Pakku.git

cd Pakku

# install to home directory
./tools/install-pakku.raku

# or to different destination
# ./tools/install-pakku.raku --dest=/path/to/pakku
</pre>

Overview
========
* `Pakku` is a simple package manager for `Raku`, with many options and customizations that can be configured in `pakku.cnf` file or via command line options.

* `Pakku` uses [Pakku::RecMan](https://github.com/hythm7/Pakku-RecMan) as a recommendation manager

* `Pakku` command result is one of:
  - `-Ofun` - Desired operation completed successfully
  - `Nofun` - Desired operation did not complete successfully

* `Pakku` has 7 verbosity levels `silent trace debug info warn error fatal`

* `Pakku` output meaning:
  - `🦋 PRC: ｢ ... ｣` → Start Processing...
  - `🐞 SPC: ｢ ... ｣` → Processing Spec
  - `🐞 MTA: ｢ ... ｣` → Processing Meta
  - `🤓 FTC: ｢ ... ｣` → Fetching URL
  - `🐞 BLD: ｢ ... ｣` → Building Dist
  - `🦋 BLT: ｢ ... ｣` → Built Dist successfully
  - `🐞 TST: ｢ ... ｣` → Testing Dist
  - `🦋 TST: ｢ ... ｣` → Tested Dist successfully
  - `🦋 ADD: ｢ ... ｣` → Added Dist
  - `💀 MTA: ｢ ... ｣` → No Meta found for Spec
  - `💀 BLD: ｢ ... ｣` → Bulding Dist failed
  - `💀 TST: ｢ ... ｣` → Testing Dist failed
  - `💀 CNF: ｢ ... ｣` → Config file error
  - `💀 CMD: ｢ ... ｣` → Command error

USAGE
=====
**Add distribution**

<pre>
<b>pakku add MyModule</b>
<b>pakku add nodeps MyModule</b>
<b>pakku add notest MyModule</b>
<b>pakku add to     /opt/MyApp MyModule</b>
<b>pakku add force  to   home  MyModule1 MyModule2</b>


<b>Options:</b> - Specific to <b>add</b> command

deps            → add dependencies
nodeps          → no dependencies
deps runtime    → add runtime dependencies
deps test       → add test    dependencies
deps build      → add build dependencies
deps requires   → add required dependencies
deps recommends → add required and recommended dependencies as well
deps suggests   → add required, recommended and suggested dependencies
deps only       → dont add the distribution, only the dependencies
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


<b>Options:</b> - Specific to <b>remove</b> command

from < repo > → remove distribution from provided repo only
</pre>


**List distribution**
<pre>
<b>pakku list</b>
<b>pakku list MyModule</b>
<b>pakku list local   MyModule</b>
<b>pakku list remote  MyModule</b>
<b>pakku list details MyModule</b>
<b>pakku list repo home</b>
<b>pakku list repo /opt/MyApp MyModule</b>


<b>Options:</b> - Specific to <b>list</b> command

local                 → list local installed dist
remote                → list remote recman's dists
details               → list details of dist
repo < name-or-path > → list dists installed in specific repo
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


**Check distribution** (download)

<pre>
<b>pakku check MyModule</b>
</pre>


**Pakku Options**

<pre>
<b>pakku dont     add MyModule</b>
<b>pakku nopretty add MyModule</b>
<b>pakku yolo     add MyModule MyOtherModule</b>
<b>pakku pretty   please remove MyModule</b>


<b>Options:</b> - Global options control general Pakku behavior and placed before Pakku commands < add remove ... >

pretty            → colors
nopretty          → no color
dont              → do everything but dont do it (dry run)
verbose < level > → verbosity < silent trace debug info warn error fatal >
please            → be nice to the butterfly
yolo              → dont stop on Pakku exceptions, useful when you don't want to stop on error (e.g. Test Faliure)
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
add    → a     yolo    → y     nopretty → np    silent → «S 0»
remove → r     pretty  → p     nodeps   → nd    trace  → «T 1»
list   → l     only    → o     noforce  → nf    debug  → «D 2»
build  → b     verbose → v     noforce  → nf    info   → «I 3»
test   → t     verbose → v     details  → d     warn   → «W 4»
check  → c     deps    → d     local    → l     error  → «E 5»
help   → h     force   → f     remote   → r     fatal  → «F 6»
</pre>

So this is a valid `Pakku` command:
<pre>
<b>pakku y v0 a f nd MyModule</b>
</pre>

Did I mention that the below are `Pakku` commands as well?
<pre>
<b>pakku 𝛒 ↓ 🔗 🔨 MyModule</b>
<b>pakku 👓 🦋 ↑ MyModule</b>
<b>pakku ↪ 🌎</b>
<b>pakku ❓</b>
</pre>

Can you guess what they do?
A full list is [here](https://github.com/hythm7/Pakku/blob/main/lib/Grammar/Pakku/Common.rakumod),You can add you favourite ones too if you like.


CONFIGURATION
=============
All options can be set in command line or in the config file <b>pakku.cnf</b> in installtion dir. Config file example is provided below:

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
  # local   # local  installed dists
  # remote  # remote recman's dists
  # details # list   details of dists

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
recman.pakku.org

</pre>


TODO
====
* Write more tests
* Fix bugs
* Redo things if a better way revealed to me
* Improve the performance to live up to the motto


CAVEATS
=======
Currently `Pakku` Works on GNU/Linux, Unfortunately I don't have access to Windows or Mac machine to test and make it compatible with different Operating Systems. However, PRs are very welcome :)


CREDITS
=======
Thanks to `Panda` and `Zef`, for `Pakku` inspiration.
also Thanks for the nice `#perl6` and `#raku` community.

MOTTO
===========
Light as a 🦋, Colorful as a 🦋

AUTHOR
======
Haytham Elganiny `elganiny.haytham at gmail.com`

COPYRIGHT AND LICENSE
=====================
Copyright 2019 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

