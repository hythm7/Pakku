Pakku
=====
A Package Manager for `Raku`.

Overview
========
Pakku is a simple package manager for Raku.

Pakku commands allows you to `add`, `remove`, `upgrade`, `list`, `search` or `download` Raku distributions.

There are two types of options:

**General options**

These are the options that control the general behavior of Pakku, like specify the configuration file, change the verbosity level or disable colors. The general options are valid for all commands, and  must be placed before a command (e.g. `add`, `remove`...).

**Specific command options**

These are the options that control the specified command, for example when installing a distributions one can specify `notest` option to disable testing the distribution. these options must be placed after the command.


Pakku full command is similar to:

`pakku [general options] [command] [specific command options] [distributions to install]`


* `Pakku` command result is either:
  - `-Ofun` - Success
  - `Nofun` - Failure

* `Pakku` verbosity levels:
	- 1 `｢debug｣` 🐛 → Everything
	- 2 `｢ now ｣` 🦋 → What is happenning now
	- 3 `｢info ｣` 🧚 → Important things only
	- 4 `｢warn ｣` 🐞 → Warnings only
	- 5 `｢error｣` 🦗 → Errors only
	- 0 `｢silent｣`   → Nothing


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
🐞 WAI → Waiting
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
<b>pakku add noprecomp notest  MyModule</b>
<b>pakku add to      /opt/MyApp MyModule</b>
<b>pakku add force   to   vendor  MyModule1 MyModule2</b>

<b>Options:</b> Specific to <b>add</b> command

deps            → Add dependencies
nodeps          → No dependencies
exclude Dep1    → Exclude Dep1
deps only       → Dependencies only
build           → Build distribution
nobuild         → Bypass build
test            → Test distribution
notest          → Bypass test
xtest           → XTest distribution
noxtest         → Bypass xtest
force           → Force add distribution even if installed
noforce         → No force
precomp         → Precompile distribution 
noprecomp       → No precompile
to < repo >     → Add distribution to repo < home site vendor core /path/to/MyApp >
</pre>

**Remove distribution**
<pre>
<b>pakku remove MyModule</b>
<b>pakku remove from site MyModule</b>

<b>Options:</b> Specific to <b>remove</b> command

from < repo > → Remove distribution from provided repo only
</pre>


**List installed distributions**
<pre>
<b>pakku list</b>
<b>pakku list MyModule</b>
<b>pakku list details MyModule</b>
<b>pakku list repo home</b>
<b>pakku list repo /opt/MyApp MyModule</b>

<b>Options:</b> Specific to <b>list</b> command

details               → Details
repo < name-or-path > → List specific repo
</pre>


**Search distribution on RecMan**
<pre>
<b>pakku Search MyModule</b>
<b>pakku Search count 4 MyModule</b>
<b>pakku Search details MyModule</b>

<b>Options:</b> Specific to <b>search</b> command

count < number > → Number of dists to be returned
details          → Details of dist
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
<b>pakku test xtest ./MyModule</b>
<b>pakku test nobuild ./MyModule</b>

<b>Options:</b> Specific to <b>add</b> command

xtest           → XTest distribution
noxtest         → Bypass xtest
build           → Build distribution
nobuild         → Bypass build
</pre>

**Upgrade distribution**

<pre>
<b>pakku upgrade MyModule</b>
<b>pakku upgrade nodeps  MyModule</b>
<b>pakku upgrade force   in   vendor  MyModule1 MyModule2</b>

<b>Options:</b> Specific to <b>upgrade</b> command

deps            → Upgrade dependencies
nodeps          → No dependencies
exclude Dep1    → Exclude Dep1
deps only       → Dependencies only
build           → Build distribution
nobuild         → Bypass build
test            → Test distribution
notest          → Bypass test
xtest           → XTest distribution
noxtest         → Bypass xtest
force           → Force upgrade
noforce         → No force
precomp         → Precompile distribution 
noprecomp       → No precompile
in < repo >     → Upgrade distribution in repo < home site vendor core /path/to/MyApp >
</pre>


**Download distribution**

<pre>
<b>pakku download MyModule</b>
</pre>


**General Options**

<pre>
<b>pakku dont     add MyModule</b>
<b>pakku async    add MyModule</b>
<b>pakku nocache  add MyModule</b>
<b>pakku norecman add MyModule</b>
<b>pakku nopretty add MyModule</b>
<b>pakku yolo     add MyFailedModule MyModule</b>
<b>pakku pretty   please remove MyModule</b>

<b>Options:</b> Global options control general Pakku behavior

pretty            → Colors
nopretty          → No colors
async             → Run asynchronously (disabled by default because some dists tests will fail if run asynchronously)
noasync           → Dont run asynchronously
nocache           → Disable cache
norecman          → Disable remote recommendation manager
dont              → Do everything but dont do it (dry run)
verbose < level > → Verbosity < debug now info warn error silent >
config  < path >  → Specify config file
please            → Be nice to butterflies
yolo              → Dont stop on errors (e.g. proceed after Test Failure)
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
add    → a  upgrade  → u  yolo     → y  nopretty → np  silent → «S 0»
remove → r  download → d  exclude  → x  nodeps   → nd  debug  → «D 1»
list   → l  help     → h  deps     → d  noforce  → nf  now    → «N 2»
search → s  verbose  → v  force    → f  notest   → nt  info   → «I 3»
build  → b  pretty   → p  details  → d  nobuild  → nb  warn   → «W 4»
test   → t  only     → o  norecman → nr nocache  → nc  error  → «E 5»
									     
									
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
* All options can be set in command line or in config file <b>pakku.cnf</b>.
Config file will be loaded from command line if specified, or from home directory `｢$*HOME/.pakku/pakku.cnf｣`, if doesn't exist `Pakku` will use default config file from `%?RESOURCES`.
The only needed config is the recommendation manager `<recman>`, otherwise `Pakku` will be able to install local distributions only.

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
  # async            # run asynchronously when possible

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


Gotchas
=======
**Caching downloaded distributions**

When one installs a distribution via `pakku add MyDist`, Pakku first looks in the local cache to see if there is a downloaded distribution matches `MyDist` specification, if nothing found in the cache, Pakku then searches the configured `RecMan` and obtain the latest version of `MyDist` (e.g. `MyDist:ver<0.4.1>`), download, cache, and install it.

After sometime when a new version `MyDist:ver<0.4.2>` is released and available in `RecMan`, if one try to install `MyDist` via `pakku add MyDist`, what happens is Pakku will find `MyDist:ver<0.4.1>` available in local cache and will install that version because it matches `MyDist` specification. so one will not get the latest version `MyDist:ver<0.4.2>`.

There are two ways to avoid this and get the latest version, either specify the version e.g. `pakku add  MyDist:ver<0.4.2>` or disable cache lookup e.g. `pakku nocache add MyDist` (also, one can permenantly disable cache in config file).

**Pakku installs to _site_ repo by default**

If the user doesn't have `rw` permision to `site` repo, one can change the default repo in the config file, or specify the repo in the command e.g. `pakku add to home MyDist`

**Installing already installed distribution**

When trying to install an already installed distribution, Pakku will appear not doing anything and give almost instant `-Ofun` response signaling a success. May be its better to add a debug message informing the user that the distribution is already installed, but that is not yet there.

Caveats
=======
Doesn't play nice with `libcurl.dll` on some windows systems, need to investigate more.

Installation
============
<pre>

# Pakku depends on <b>libarchive</b> and <b>libcurl</b>

# Requires <b>Rakudo 2022.12 </b> version or later

# <b>Install</b>
git clone https://github.com/hythm7/Pakku.git
cd Pakku
raku -I. bin/pakku add .

# <b>Install using Pakku</b>
pakku add Pakku:ver&ltava-1&gt

# <b>Install using Zef</b>
zef install Pakku:ver&ltava-1&gt
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
