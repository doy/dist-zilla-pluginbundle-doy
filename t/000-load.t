#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

package Foo;
::use_ok('Dist::Zilla::PluginBundle::DOY')
    or ::BAIL_OUT("couldn't load Dist::Zilla::PluginBundle::DOY");
