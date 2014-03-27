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

use IndieBox::Logging;
use IndieBox::Testing::AppTest;

# The states and transitions for this test

my $custPointValues = {
        'adminlogin' => 'specialuser',
        'adminpass'  => 'specialpass'
};
my $filesAppRelativeUrl = '/index.php/apps/files';

## Factored out upload routines.

##
# Perform an HTTP POST request uploading a file on the host on which the
# application is being tested.
# $c: TestContext
# $relativeUrl: appended to the host's URL
# $file: name of the file to be uploaded
# $dir: the directory parameter
# $requestToken: the form's request token
# return: hash containing content and headers of the HTTP response
sub httpUploadRelativeHost {
    my $c            = shift;
    my $relativeUrl  = shift;
    my $file         = shift;
    my $dir          = shift;
    my $requestToken = shift;

    my $url = 'http://' . $c->hostName . $relativeUrl;
    my $response;

    debug( 'Posting to url', $url );

    my $cmd = $c->{curl};
    $cmd .= " -F 'files[]=\@$file;filename=$file;type=text/plain'";
    $cmd .= " -F 'requesttoken=$requestToken'";
    $cmd .= " -F 'dir=$dir'";
    $cmd .= " '$url'";

    my $stdout;
    my $stderr;
    if( IndieBox::Utils::myexec( $cmd, undef, \$stdout, \$stderr )) {
        $c->reportError( 'HTTP request failed:', $stderr );
    }
    return { 'content'     => $stdout,
             'headers'     => $stderr,
             'url'         => $url,
             'file'        => $file };
}

##
# Perform an HTTP POST request uploading a file on the application being tested,
# appending to the context URL.
# $c: TestContext
# $relativeUrl: appended to the application's context URL
# $file: name of the file to be uploaded
# return: hash containing content and headers of the HTTP response
sub httpUploadRelativeContext {
    my $c            = shift;
    my $relativeUrl  = shift;
    my $file         = shift;
    my $dir          = shift;
    my $requestToken = shift;

    return httpUploadRelativeHost( $c, $c->context() . $relativeUrl, $file, $dir, $requestToken );
}

##


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
            ),
            new IndieBox::Testing::StateTransition(
                    name       => 'upload-file',
                    transition => sub {
                        my $c = shift;

                        # need to login first, and find requesttoken
                        my $postData = {
                            'user'            => $custPointValues->{'adminlogin'},
                            'password'        => $custPointValues->{'adminpass'},
                            'timezone-offset' => 0
                        };
                        
                        my $response = $c->httpPostRelativeContext( '/', $postData );
                        unless( $response->{headers} =~ m!HTTP/1.1 302 Found! ) {
                            $c->reportError( 'Not HTTP Status 203', $response->{headers} );
                        }

                        $response = $c->httpGetRelativeContext( $filesAppRelativeUrl );
                        unless( $response->{headers} =~ m!HTTP/1.1 200 OK! ) {
                            $c->reportError( 'Not HTTP Status 200', $response->{headers} );
                        }

                        my $requestToken;
                        if( $response->{content} =~ m!<head.*data-requesttoken="([0-9a-f]+)"! ) {
                            $requestToken = $1;
                        } else {
                            $c->reportError( 'Cannot find request token', $response->{content} );
                        }

                        $response = httpUploadRelativeContext( $c, '/index.php/apps/files/ajax/upload.php', 'foo-testfile', '/', $requestToken );
                        unless( $response->{headers} =~ m!HTTP/1.1 200 OK! ) {
                            $c->reportError( 'Not HTTP Status 200', $response->{headers} );
                        }

                        return 1;
                    }
            ),
            new IndieBox::Testing::StateCheck(
                    name  => 'file-uploaded',
                    check => sub {
                        my $c = shift;

                        return 1;
                    }
            )
    ]
);

$TEST;
