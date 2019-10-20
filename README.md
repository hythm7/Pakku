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


FEATURES
======

* Add `Raku` distribution
* Remove `Raku` distribution
* List `Raku` distribution
* Build `Raku` distribution
* Test `Raku` distribution
* Download `Raku` distribution


Overview
========

`Pakku` is shy butterfly, she is a bug of little words, So every `Pakku` command result will be one of:

* `Ofun` - Desired operation completed successfully
* `Nofun` - Desired operation did not complete successfully
* `All Good` - Nothing to be done (eg. removing uninstalled distribution)


Of course unless `Pakku` panicked and she doesn't know what to do, then you will be greeted with an `Exception` 


However `Pakku` can be really talkative when need be. She suggests new friends of her to set the verbosity level to `info` (per command or in the configuration file) specially when adding a `Distribution` with many dependencies or multiple `Distribution`s at once.


EXAMPLES
========

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

update          → update  ecosystem
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


AUTHOR
======

Haytham Elganiny `elganiny.haytham at gmail.com`

COPYRIGHT AND LICENSE
=====================

Copyright 2019 Haytham Elganiny

This library is free software; you can redistribute it and/or modify it under the Artistic License 2.0.

