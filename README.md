WHAT?
=====
`Pakku` - A Package Manager for `Raku`


WHY?
====
Because TMTOWTDI


WHEN?
=====
When she become a fully grown butterfly. currently `Pakku` is at larava.0 version and growing. She can do basic stuff but still little clumsy!


MOTTO
===========
Light as a 🦋, Colorful as a 🦋


INSTALLATION
============

`Pakku` installs herself in a custom `CompUnit::Repository` outside of `Raku`'s default repos.

Requires `git` to be available in `$PATH`

<pre>
git clone https://github.com/hythm7/Pakku.git

cd Pakku

# install to home directory
./hooks/install-pakku.raku

# or to different destination
# ./hooks/install-pakku.raku --dest=/path/to/pakku
</pre>


FEATURES
======

* Add distribution
* Remove distribution
* List distribution
* Build distribution
* Test distribution
* Download distribution


Overview
========

`Pakku` is shy butterfly, she is a bug of little words, So every `Pakku` command result will be one of:

* `Ofun` - Desired operation completed successfully
* `Nofun` - Desired operation did not complete successfully
* `All Good` - Nothing to be done (eg. removing uninstalled distribution)


Of course unless `Pakku` panicked and she doesn't know what to do, then you will be greeted with an `Exception` 


However `Pakku` can be really talkative when need be. She suggests her new friends set the verbosity level to at least `info` specially when adding a `Distribution` with many dependencies or multiple `Distribution`s at once.


USAGE
=====

**Add distribution**

<pre>
<b>pakku add MyModule</b>
<b>pakku add nodeps MyModule</b>
<b>pakku add notest MyModule</b>
<b>pakku add into   /opt/MyApp MyModule</b>
<b>pakku add force  into home  MyModule1 MyModule2</b>


<b>Options:</b>

deps            → add dependencies
nodeps          → dont add dependencies
deps requires   → add required dependencies only
deps recommends → add required and recommended dependencies
deps only       → add dependencies only
build           → build distribution
nobuild         → bypass build
test            → test distribution
notest          → bypass test
force           → force add distribution even if installed
noforce         → no force
into &lt;repo&gt;     → add distribution to repo &lt;home site vendor core /path/to/MyApp&gt;
</pre>

**Remove distribution**
<pre>
<b>pakku remove MyModule</b>


<b>Options:</b>

from &lt;repo&gt; → remove distribution from provided repo only
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


<b>Options:</b>

local       → list local
remote      → list remote
details     → list details
repo &lt;name&gt; → list repo
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


**Pakku Options**

<pre>
<b>pakku update   add MyModule</b>
<b>pakku noupdate add MyModule</b>
<b>pakku dont     add MyModule</b>
<b>pakku nopretty add MyModule</b>
<b>pakku verbose  trace  add    MyModule</b>
<b>pakku pretty   please remove MyModule</b>


<b>Options:</b>

update          → update ecosystem to get latest before adding distribution
pretty          → colorfull butterfly
nopretty        → no color
dont            → do everything but dont do it
verbose &lt;level&gt; → verbose level &lt;silent trace debug info warn error fatal&gt;
please          → be nice to the butterfly, she will be nice to you (TBD)
</pre>


**Check distribution** (download)

<pre>
<b>pakku check MyModule</b>
</pre>


**Print Help**

<pre>
<b>pakku</b>
<b>pakku add</b>
<b>pakku help</b>
<b>pakku help list</b>
<b>pakku help help</b>
</pre>


<h3>Feeling Perlish Today?</h3>

Most of `Pakku` commands and options can be written in shorter form, for example:
<pre>
add    → a     update  → u     noupdate → nu    silent → «S 0»
remove → r     pretty  → p     nopretty → np    trace  → «T 1»
list   → a     deps    → d     nodeps   → nd    debug  → «D 2»
build  → b     force   → f     noforce  → nf    info   → «I 3»
test   → t     verbose → v     details  → d     warn   → «W 4»
check  → c     local   → l     local    → l     error  → «E 5»
help   → h     remote  → r     remote   → r     fatal  → «F 6»
</pre>

So this is a valid `Pakku` command:
<pre>
<b>pakku nu vD a f nt MyModule</b>
</pre>

Did I mention that the below are `Pakku` commands as well?
<pre>
<b>pakku 𝛒 ⟳ ↓ 🔗 🔨 MyModule</b>
<b>pakku 👓 🦋 ↑ MyModule</b>
<b>pakku ↪ 🌎</b>
<b>pakku ❓</b>
</pre>

Can you guess what they do? 
A full list is [here](https://github.com/hythm7/Pakku/blob/master/lib/Pakku/Grammar/Common.pm6),You can add you favourite ones too if you like.


CONFIGURATION
=============

All options can be set in command line or in the config file <b>pakku.cnf</b> in installtion dir. Config file example is provided below:

<pre>
### Pakku Config

# &lt;pakku&gt;
#   update           # update ecosystem
#   pretty           # colors
#   verbose info     # < 0 1 2 3 4 5 6 >
#   dont             # dont do it (dry run)
#
# &lt;add&gt;
#   deps       # add deps as well < deps nodeps only requires recommends >
#   build      # build            < build nobuild >
#   test       # test             < test notest >
#   force      # force install    < force noforce >
#   into  home # install into specific repo <home site vendor core /custom/repo/path>
#
# &lt;remove&gt;
#   from home  # remove from specific repo
#
# &lt;list&gt;
#   local   # local  dists
#   remote  # remote dists
#   details # list   details
#
# custom Log colors, also override unicode
# if symbols not showing
# &lt;log&gt;
#   trace name T:
#   debug name D:
#   info  name I:
#   warn  name W:
#   error name E:
#   fatal name F:
#
#   trace color reset
#   debug color green
#   info  color blue
#   warn  color yellow
#   error color magenta
#   fatal color red

# Add your own source provided it contains
# a valid list of distributions meta files
&lt;source&gt;
https://raw.githubusercontent.com/hythm7/raku-ecosystem/master/resources/ecosystem.json
</pre>


NOTES
=====
`Pakku` ecosystem source is a github file that contains available modules in `p6c` and `cpan`. Its LTA, slow and doesn't scale well (needs to download the file and parse it).

Ideally there need to be an online Recommendation Manager service which can be used by `Raku`'s package managers  to send a request for a `Distribution` and get back `json` contains the `Distribution`'s `META` along with it's dependencies. 
Working on such online Recommendation Manager will take time and I wanted to release `Pakku` sooner. I might work on such Recommendation Manager after `Pakku` becomes little more stable.


Known Issues
============

* `%?RESOURCES` is not available inside a custom repo during the testing phase,  might cause test failure for some modules, see [here](https://github.com/hythm7/Pakku/issues/1) for more info. as temporary workaround you can bypass tests if it failed in custom repo installation. 

* There is  version of `File::Directory::Tree:ver<0.000.001>` in the ecosystem it's `source-url` points to a different version `File::Directory::Tree:ver<*>`, This causes an issue for `Pakku` if `File::Directory::Tree:ver<*>` is already installed, first `Pakku` will see a different version, but when get `source-url` and start installing an error will be thrown that this version is already installed. as a temp workaround use `force`


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


AUTHOR
======

Haytham Elganiny `elganiny.haytham at gmail.com`

COPYRIGHT AND LICENSE
=====================

Copyright 2019 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

