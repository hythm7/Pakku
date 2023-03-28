[![SparrowCI](https://ci.sparrowhub.io/project/git-hythm7-Pakku/badge)](https://ci.sparrowhub.io)

Pakku
=====
A Package Manager for Raku.

Installation
============
<pre>

# Pakku depends on <b>libarchive</b> and <b>libcurl</b>
# Requires <b>Rakudo 2022.12 </b> version or later

# <b>Install</b>
git clone https://github.com/hythm7/Pakku.git
cd Pakku
raku -I. bin/pakku add .

# <b>Install using Zef</b>
zef install Pakku
</pre>

Usage
=====
Pakku commands allows one to `add`, `remove`, `upgrade`, `list`, `search` or `download` Raku distributions.

There are two types of options:

**General options**

These are the options that control the general behavior of Pakku, like specify the configuration file, run asynchronously or disable colors. The general options are valid for all commands, and  must be placed before the specified command (`add`, `remove`...).

**Specific command options**

These are the options that control the specified command, for example when installing a distributions one can specify `notest` option to disable testing. these options must be placed after the command.


Full command is similar to:

`pakku [general options] [command] [specific command options] [dists]`


A Pakku command result is either:
  - `-Ofun` - Success
  - `Nofun` - Failure


**General Options**

Options to control general Pakku behavior.

<b>Options:</b>

<pre>
pretty             → use colors
nopretty           → no colors
async              → run asynchronously (disabled by default because some dists tests are not async safe) 
noasync            → dont run asynchronously
nocache            → disable cache
dont               → do everything but dont do it (dry run)
verbose  < level > → verbosity < debug now info warn error silent >
config   < path >  → specify config file
recman             → enable all remote recommendation manager
norecman           → disable all remote recommendation manager
recman   < MyRec > → use MyRec recommendation manager only
norecman < MyRec > → use all recommendation managers excepts MyRec
please             → be nice to butterflies
yolo               → dont stop on errors (eg. proceed after test failure)
</pre>

<b>Examples:</b>
<pre>
<b>pakku async   add Dist</b>                # run in async mode while adding Dist
<b>pakku nocache add Dist</b>                # dont use local cache
<b>pakku dont    add Dist</b>                # dont add Dist (dry run)
<b>pakku pretty  please remove Dist</b>

</pre>



**add command**

**options:**

<pre>
deps                → all dependencies
nodeps              → no dependencies
exclude < Dep1 >    → exclude Dep1
deps    < only >    → only dependencies
deps    < build >   → build dependencies only
deps    < test >    → test dependencies only
deps    < runtime > → runtime dependencies only
build               → build distribution
nobuild             → bypass build
test                → test distribution
notest              → bypass test
xtest               → xTest distribution
noxtest             → bypass xtest
force               → force add distribution even if installed
noforce             → no force
precomp             → precompile distribution 
noprecomp           → no precompile
to < repo >         → add distribution to repo < home site vendor core /path/to/MyApp >
</pre>

<b>Examples:</b>
<pre>
<b>pakku add Dist</b>                                # add Dist
<b>pakku add notest  Dist</b>                        # add Dist without testing
<b>pakku add nodeps  Dist</b>                        # add Dist but dont add dependencies
<b>pakku add deps only Dist</b>                      # add Dist dependencies but dont add Dist
<b>pakku add exclude Dep1 Dist</b>                   # add Dist and exclude Dep1 from dependenncies
<b>pakku add noprecomp notest  Dist</b>              # add Dist without testing and no precompilation
<b>pakku add to      /opt/MyApp Dist</b>             # add Dist to custom repo
<b>pakku add force   to   vendor  Dist1 Dist2</b>    # add Dist1 and Dist2 to vendor repo even if they are installed
</pre>


**remove command**

**options:**

<pre>
from < repo > → remove distribution from provided repo only
</pre>

<b>Examples:</b>
<pre>
<b>pakku remove Dist</b>            # remove Dist from all repos
<b>pakku remove from site Dist</b>  # remove Dist from site repo only
</pre>



**list command**

**options:**

<pre>
details               → details
repo < name-or-path > → list specific repo
</pre>

<b>Examples:</b>
<pre>
<b>pakku list</b>                         # list all installed dists
<b>pakku list Dist</b>                    # list installed Dist
<b>pakku list details Dist</b>            # list installed Dist details
<b>pakku list repo home</b>               # list all dists installed to home repo
<b>pakku list repo /opt/MyApp Dist</b>    # list installed Dist in custom repo
</pre>



**search command**

**options:**

<pre>
details            → details of dist
count   < number > → number of dists to be returned
</pre>

<b>Examples:</b>
<pre>
<b>pakku search dist</b>               # search distributions matching dist (ignored case) on online recman
<b>pakku search count 4 Dist</b>       # search dist and return the lates 4 versions only
<b>pakku search details Dist</b>       # search dist and list all details
</pre>



**build command**

<b>Examples:</b>
<pre>
<b>pakku build Dist</b>
<b>pakku build .</b>
</pre>


**test command**

**options:**

<pre>
xtest   → XTest distribution
noxtest → Bypass xtest
build   → Build distribution
nobuild → Bypass build
</pre>

<b>Examples:</b>
<pre>
<b>pakku test Dist</b>
<b>pakku test ./Dist</b>
<b>pakku test xtest ./Dist</b>
<b>pakku test nobuild ./Dist</b>
</pre>


**upgrade command**

**options:**

<pre>
deps         → upgrade dependencies
nodeps       → no dependencies
exclude Dep1 → exclude Dep1
deps only    → dependencies only
build        → build distribution
nobuild      → bypass build
test         → test distribution
notest       → bypass test
xtest        → xTest distribution
noxtest      → bypass xtest
force        → force upgrade
noforce      → no force
precomp      → precompile distribution 
noprecomp    → no precompile
in < repo >  → upgrade distribution in repo < home site vendor core /path/to/MyApp >
</pre>

<b>Examples:</b>
<pre>
<b>pakku upgrade Dist</b>
<b>pakku upgrade nodeps  Dist</b>
<b>pakku upgrade force   in   vendor  Dist1 Dist2</b>
</pre>


**download command**

<b>Examples:</b>
<pre>
<b>pakku download Dist</b>     # download source code od Dist
</pre>



**config**

Each Pakku command like `add`, `remove`, `search` etc. corresponds to a config module with the same name in the config file.
one can use config command to `enable`, `disable`, `set`, `unset` an option in the config file.

<pre>
<b>pakku config</b>                             # view all config modules
<b>pakku config new</b>                         # create a new config file
<b>pakku config add</b>                         # view add config module
<b>pakku config add precompile</b>              # view <b>precompile</b> option in <b>add</b> config module
<b>pakku config add enable force</b>            # enable option <b>force</b> in <b>add</b> module 
<b>pakku config add set to home</b>             # set option <b>to</b> to <b>home</b> (change default repo to home) in <b>add</b> module 
<b>pakku config pakku enable async</b>          # enable  option <b>async</b> in <b>pakku</b> module (general options) 
<b>pakku config pakku unset verbose</b>         # unset option <b>verbose</b> in <b>pakku</b> module 
<b>pakku config recman MyRec disable</b>        # disable recman named <b>MyRec</b> in <b>recman</b> module
<b>pakku config recman MyRec set priority 1</b> # set recman <b>MyRec</b>'s priority to 1 in <b>recman</b> module
<b>pakku config add reset</b>                   # reset <b>add</b> config module to default
<b>pakku config reset</b>                       # reset all config modules to default
</pre>

**options:**

<pre>
enable        → enable option
disable       → disable option
set < value > → set option to value 
unset         → unset option
</pre>



**help**

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

The below are `Pakku` commands as well!
<pre>
<b>pakku 👓 🧚 ↓   Dist</b>
<b>pakku ↪</b>
<b>pakku ❓</b>
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
🧚 PRC → started successfully and processing
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

	- 1 `｢debug｣` 🐛 → Everything
	- 2 `｢ now ｣` 🦋 → What is happenning now
	- 3 `｢info ｣` 🧚 → Important things only
	- 4 `｢warn ｣` 🐞 → Warnings only
	- 5 `｢error｣` 🦗 → Errors only
	- 0 `｢silent｣`   → Nothing

Gotchas
=======
**Caching downloaded distributions**

When one installs a distribution via `pakku add MyDist`, Pakku first looks in the local cache to see if there is a downloaded distribution matches `MyDist` specification, if nothing found in the cache, Pakku then searches the configured `RecMan` and obtain the latest version of `MyDist` (e.g. `MyDist:ver<0.4.1>`), download, cache, and install it.

After sometime when a new version `MyDist:ver<0.4.2>` is released and available in `RecMan`, if one try to install `MyDist` via `pakku add MyDist`, what happens is Pakku will find `MyDist:ver<0.4.1>` available in local cache and will install that version because it matches `MyDist` specification. so one will not get the latest version `MyDist:ver<0.4.2>`.

There are two ways to avoid this and get the latest version, either specify the version e.g. `pakku add  MyDist:ver<0.4.2>` or disable cache lookup e.g. `pakku nocache add MyDist` (also, one can permenantly disable cache in config file).


**Pakku installs to _site_ repo by default**

If the user doesn't have `rw` permision to `site` repo, one can change the default repo to `home` in config file using:

```pakku config add set to home```

or specify the repo in the command e.g. `pakku add to home MyDist`

Caveats
=======
Doesn't play nice with `libcurl.dll` on some windows systems, need to investigate more.

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
