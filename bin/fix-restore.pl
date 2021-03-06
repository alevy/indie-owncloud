#!/usr/bin/perl
#
# Upon restore, the restored config.php has the old database information in it.
# We need to take the new database info from autoconfig.php, updated config.php.
# and delete autoconfig.php. This script does not have access to the database
# information directly, so that's the best avenue.
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

my $dir          = $config->getResolve( 'appconfig.apache2.dir' );
my $configDir    = "$dir/config";
my $autoConfFile = "$configDir/autoconfig.php";
my $confFile     = "$configDir/config.php";

my $apacheUname = $config->getResolve( 'apache2.uname' );
my $apacheGname = $config->getResolve( 'apache2.gname' );
my $hostname    = $config->getResolve( 'site.hostname' );

if( 'upgrade' eq $operation ) {

    my $autoConf = IndieBox::Utils::slurpFile( $autoConfFile );

    my $dbname;
    my $dbuser;
    my $dbpass;
    my $dbhost;

    if( $autoConf =~ m!['"]dbname['"]\s+=>\s["'](\S*)["']! ) {
        $dbname = $1;
    }
    if( $autoConf =~ m!['"]dbuser['"]\s+=>\s["'](\S*)["']! ) {
        $dbuser = $1;
    }
    if( $autoConf =~ m!['"]dbpass['"]\s+=>\s["'](\S*)["']! ) {
        $dbpass = $1;
    }
    if( $autoConf =~ m!['"]dbhost['"]\s+=>\s["'](\S*)["']! ) {
        $dbhost = $1;
    }

    my $conf = IndieBox::Utils::slurpFile( $confFile );
    $conf =~ s!(['"]dbname['"]\s+=>\s["'])\S*(["'],?)!$1$dbname$2!;
    $conf =~ s!(['"]dbhost['"]\s+=>\s["'])\S*(["'],?)!$1$dbhost$2!;
    $conf =~ s!(['"]dbuser['"]\s+=>\s["'])\S*(["'],?)!$1$dbuser$2!;
    $conf =~ s!(['"]dbpassword['"]\s+=>\s["'])\S*(["'],?)!$1$dbpass$2!;
    $conf =~ s!(['"]trusted_domains['"]\s+=>\s*array\s*\(\s*0\s*=>\s*["'])\S*(\s*['"]\s*\))!$1$hostname$2!;

    IndieBox::Utils::saveFile( $confFile, $conf, 0640, $apacheUname, $apacheGname );

    IndieBox::Utils::deleteFile( $autoConfFile );
}

1;
