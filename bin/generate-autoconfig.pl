#!/usr/bin/perl
#
# Generate the autoconfig.php file. This is a perlscript instead of a
# varsubst-d template because OwnCloud will remove this file, and then
# Indie Box undeploy will emit a warning, and we don't want that.
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

if( 'install' eq $operation ) {

    my $dir            = $config->getResolve( 'appconfig.apache2.dir' );
    my $autoConfigFile = "$dir/config/autoconfig.php";

    my $apacheUname = $config->getResolve( 'apache2.uname' );
    my $apacheGname = $config->getResolve( 'apache2.gname' );

    my $dbname = $config->getResolve( 'appconfig.mysql.dbname.maindb' );
    my $dbuser = $config->getResolve( 'appconfig.mysql.dbuser.maindb' );
    my $dbpass = $config->getResolve( 'appconfig.mysql.dbusercredential.maindb' );
    my $dbhost = $config->getResolve( 'appconfig.mysql.dbhost.maindb' );

    my $adminlogin = $config->getResolve( 'appconfig.installable.customizationpoints.adminlogin.value' );
    my $adminpass  = $config->getResolve( 'appconfig.installable.customizationpoints.adminpass.value' );

    my $autoConfigContent = <<END;
<?php
\$AUTOCONFIG = array(
  "dbtype"        => "mysql",
  "dbname"        => "$dbname",
  "dbuser"        => "$dbuser",
  "dbpass"        => "$dbpass",
  "dbhost"        => "$dbhost",
  "dbtableprefix" => "",
  "adminlogin"    => "$adminlogin",
  "adminpass"     => "$adminpass",
  "directory"     => "data"
);
END
    
    IndieBox::Utils::saveFile( $autoConfigFile, $autoConfigContent, 0640, $apacheUname, $apacheGname );
}
                
1;
