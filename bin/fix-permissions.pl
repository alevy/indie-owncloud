#!/usr/bin/perl
#
# Fix permissions.
#
# Copyright (C) 2013-2014 Indie Box Project http://indieboxproject.org/
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

use strict;

use IndieBox::Utils;
use POSIX;

my $dir         = $config->getResolve( 'appconfig.apache2.dir' );
my $appsDir     = "$dir/apps";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );

if( 'install' eq $operation ) {
    IndieBox::Utils::myexec( "chown -R $apacheUname:$apacheGname '$appsDir' '$dir/index.html'" );
}

1;
