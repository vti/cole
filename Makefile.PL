#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install;

name 'Cole';

version_from 'lib/Cole.pm';
author 'Viacheslav Tykhanovskyi <vti@cpan.org>';
abstract 'WebSocket request/response';
license 'artistic_2';
perl_version '5.008007';

requires 'Carp'         => 0;
requires 'Class::Load'  => 0;
requires 'Scalar::Util' => 0;

test_requires 'Test::Spec';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t';

no_index directory => 't';

resources
  bugtracker => 'http://github.com/vti/cole/issues',
  repository => 'http://github.com/vti/cole/',
  license    => 'http://dev.perl.org/licenses/';

auto_install;

WriteAll;
