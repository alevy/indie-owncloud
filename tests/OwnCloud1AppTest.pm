#!/usr/bin/perl
#
# Simple test for indie-owncloud
#
# Copyright (C) 2013 Indie Box Project http://indieboxproject.org/
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
use warnings;

package OwnCloud1AppTest;

use Data::Dumper;
use IndieBox::Testing::AppTest;

# The states and transitions for this test

my $custPointValues = {
        'adminlogin' => 'specialuser',
        'adminpass'  => 'specialpass'
};
my $filesAppRelativeUrl = '/index.php/apps/files';

my $TEST = new IndieBox::Testing::AppTest(
    name                     => 'OwnCloud1AppTest',
    description              => 'Tests whether anonymous guests can leave messages.',
    appToTest                => 'indie-owncloud',
    hostname                 => 'owncloud-test',
    customizationPointValues => $custPointValues,

    checks => [
            new IndieBox::Testing::StateCheck(
                    name  => 'virgin',
                    check => sub {
                        my $c = shift;

                        my $response = $c->httpGetRelativeContext( '/' );
                        unless( $response->{headers} =~ m!HTTP/1.1 200 OK! ) {
                            $c->reportError( 'Not HTTP Status 200', $response->{headers} );
                        }
                        unless( $response->{content} =~ m!<label for="user" class="infield">Username</label>! ) {
                            $c->reportError( 'Wrong front page' );
                        }

                        my $postData = {
                            'user'            => $custPointValues->{'adminlogin'},
                            'password'        => $custPointValues->{'adminpass'},
                            'timezone-offset' => 0
                        };
                        
                        $response = $c->httpPostRelativeContext( '/', $postData );
                        unless( $response->{headers} =~ m!HTTP/1.1 302 Found! ) {
                            $c->reportError( 'Not HTTP Status 203', $response->{headers} );
                        }
                        unless( $response->{headers} =~ m!Location:.*$filesAppRelativeUrl! ) {
                            $c->reportError( 'Not redirected to files app', $response->{headers} );
                        }
                            
                        
                        $response = $c->httpGetRelativeContext( $filesAppRelativeUrl );
                        unless( $response->{headers} =~ m!HTTP/1.1 200 OK! ) {
                            $c->reportError( 'Not HTTP Status 200', $response->{headers} );
                        }
                        if( $response->{content} =~ m!<label for="user" class="infield">Username</label>! ) {
                            $c->reportError( 'Wrong logged-on page (still front page)' );
                        }
                        my $adminLogin = $custPointValues->{'adminlogin'};
                        unless( $response->{content} =~ m!<span id="expandDisplayName">$adminLogin</span>! ) {
                            $c->reportError( 'Wrong logged-on page (logged-in user not shown)' );
                        }
                        					
                        return 1;
                    }
            )
    ]
);

$TEST;
