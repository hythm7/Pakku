Pakku
=====
Package Manager for `Raku`

Installation
============
<pre>

# Pakku depends on libarchive and libcurl, they should be
# installed already on most operating systems but if not,
# they need to be installed for Pakku to function.


# Install using Pakku

git clone https://github.com/hythm7/Pakku.git
cd Pakku
raku -I. bin/pakku add .

# Install using zef
zef install Pakku:ver&ltava-1&gt
</pre>

Overview
========
* `Pakku` is a simple package manager for `Raku`.

* `Pakku` command result is either:
  - `-Ofun` - On success
  - `Nofun` - On failure

* `Pakku` verbosity levels:
`0 ｢silent｣`   → No output what so ever 
`1 ｢debug｣` 🐛 → If you want to see everything
`2 ｢ now ｣` 🦋 → What is happenning now
`3 ｢info ｣` 🧚 → Important things only
`4 ｢warn ｣` 🐞 → Warnings only
`5 ｢error｣` 🦗 → You probably don't like to see that when running Pakku!


* `Pakku` log meaning:
```
🧚 PRC → Start processing
🦋 SPC → Processing Spec
🦋 MTA → Processing Meta
🦋 FTC → Fetching
🦋 BLD → Building
🦋 STG → Staging
🦋 TST → Testing
🧚 BLD → Build success
🧚 TST → Test success
🧚 BIN → Binary added
🦋 WAI → Waiting
🐞 TOT → Timed out
🦗 SPC → Error processing Spec
🦗 MTA → Error processing Meta
🦗 BLD → Build failure
🦗 TST → Test failure
🦗 CNF → Config error
🦗 CMD → Command error
```

Usage
=====
**Add distribution**

<pre>
<b>pakku add MyModule</b>
<b>pakku add nodeps  MyModule</b>
<b>pakku add notest  MyModule</b>
<b>pakku add exclude Dep1 MyModule</b>
<b>pakku add to      /opt/MyApp MyModule</b>
<b>pakku add force   to   vendor  MyModule1 MyModule2</b>

<b>Options:</b> Specific to <b>add</b> command

deps            → add dependencies
nodeps          → no dependencies
exclude Dep1    → exclude Dep1 dependency
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
<b>pakku remove from site MyModule</b>

<b>Options:</b> Specific to <b>remove</b> command

from < repo > → remove distribution from provided repo only
</pre>


**List installed distributions**
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
<b>pakku Search count 4 MyModule</b>
<b>pakku Search details MyModule</b>

<b>Options:</b> Specific to <b>search</b> command

count < number > → number of dists to be returned
details          → list details of dist
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
<b>pakku test nobuild ./MyModule</b>

<b>Options:</b> Specific to <b>add</b> command

build           → build distribution
nobuild         → bypass build
</pre>


**Checkout (download) distribution**

<pre>
<b>pakku checkout MyModule</b>
</pre>


**Pakku Options**

<pre>
<b>pakku dont     add MyModule</b>
<b>pakku nocache  add MyModule</b>
<b>pakku norecman add MyModule</b>
<b>pakku nopretty add MyModule</b>
<b>pakku yolo     add MyFailedModule MyModule</b>
<b>pakku pretty   please remove MyModule</b>

<b>Options:</b> Global options control general Pakku behavior

pretty            → colors
nopretty          → no colors
nocache           → disable cache
norecman          → disable remote recommendation manager
dont              → do everything but dont do it (dry run)
verbose < level > → verbosity < silent debug now info warn error fatal >
config  < path >  → use config file
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
remove    → r     pretty  → p     nodeps   → nd     debug  → «D 1»
list      → l     only    → o     noforce  → nf     now    → «N 2»
search    → s     deps    → d     notest   → nt     info   → «I 3»
build     → b     force   → f     nobuild  → nb     warn   → «W 4»
test      → t     details → d     nocache  → nc     error  → «E 5»
checkout  → c     yolo    → y     norecman → nr
help      → h     exclude → x
</pre>

Did I mention that the below are `Pakku` commands as well?
<pre>
<b>pakku 𝛒 ↓ 🔗 🔨 MyModule</b>
<b>pakku 👓 🧚 ↑   MyModule</b>
<b>pakku 🌎        MyModule</b>
<b>pakku ↪</b>
<b>pakku ❓</b>
</pre>


Configuration
=============
* All options can be set in command line or in the config file <b>pakku.cnf</b>.
Config file will be loaded from command line if specified, or from home directory ｢`$*HOME/.pakku/pakku.cnf`｣, if doesn't exist `Pakku` will use the default config file from `%?RESOURCES`.
The only needed config is the recommendation manager `<recman>`, otherwise you will be able to install local distributions only.

* In case your terminal font does not support emojis, you can replace them by changing `prefix` values in the `< log >` section of your config file `~/.pakku/pakku.cnf`:
```
< log >
  debug prefix DEBUG:
```

Config file example:

<pre>
### pakku Config

# global options
# < pakku >
  # pretty           # colors
  # verbose info     # < 0 1 2 3 4 5 >
  # dont             # dont do it (dry run)

# add command options
# < add >
  # deps       # add deps as well < deps nodeps >
  # build      # build            < build nobuild >
  # test       # test             < test notest >
  # force      # force install    < force noforce >
  # to  home   # add to specific repo < home site vendor core /custom/repo/path >

# remove command options
# < remove >
  # from home  # remove from specific repo

# list command options
# < list >
  # details # list   details of dists

## Customize log levels prefixes and colors
# < log >
  # debug prefix D:
  # now   prefix N:
  # info  prefix I:
  # warn  prefix W:
  # error prefix E:

  # debug color green
  # now   color cyan
  # info  color blue
  # warn  color yellow
  # error color magenta

# Recommendation Manager
< recman >
http://recman.pakku.org

</pre>


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
Copyright 2022 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.
