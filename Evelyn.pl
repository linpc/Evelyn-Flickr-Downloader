#!/usr/bin/env perl

# FreeBSD License
# 
# Copyright (c) 2012, Po-Chien Lin
# All rights reserved.
# 
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met: 
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution. 
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

use strict;
use warnings;
use LWP::UserAgent;

our $VERSION = '0.1.2';

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
our $photo_count_num = 1;
our $fetch_tool;

sub get_content($)
{
    my $url = $_[0];

    my $ua = LWP::UserAgent->new;
    $ua->timeout(120);
    $ua->agent('Mozilla/5.0');
    $ua->default_header('Accept-Language' => 'en-US,en;q=0.8');

    my $request = new HTTP::Request('GET', $url);
    my $response = $ua->request($request);
    my $content = $response->content();
}

sub parse_get_img($)
{
    my $url = $_[0];

    my $content = get_content($url);
#    $contents =~ s/\n//g;
#    my ($img_url) = $content =~ /<img src="([^"]+_o.jpg)"/m;
    my ($img_url) = $content =~ m#<img src="(https://farm[^"]+\.jpg)"#m;

    print "[$photo_count_num] img = $img_url\n";
    $photo_count_num++;

    if ($fetch_tool eq 'wget') {
        system 'wget', '-nv', '-c', '-nc', "$img_url";
    } else {    # curl
        system 'curl', '-s', '-C', '-', '-O', "$img_url";
    }
}

sub parse_page(@)
{
    my ($flickr_page, $flickr_title) = @_;

    foreach my $line ($flickr_page) {
        $line =~ s#href="/photos/[^>]+ class="title">##g;
        while ($line =~ m#href="(/photos/[^"]+?/in/[^"]+)"#) {
            my $href = $1;
            $line =~ s/$href//;

            $href =~ s#/in/#/sizes/o/in/#;
            $href = "https://www.flickr.com$href";
            print "$flickr_title: ";
            parse_get_img($href);

            sleep(1);
        }
    }
}

sub download_photoset($)
{
    my $flickr_url = $_[0];
    my $in_dir = 0;
    my $has_next_page = 1;
    my $flickr_title = '';

    # init
    $photo_count_num = 1;

    while ($has_next_page) {
        my $flickr_page = get_content($flickr_url);
        $has_next_page = 0;
        if ($in_dir == 0) {
            if ($flickr_page =~ /<title>(.*?) - (an album on Flickr|a set on Flickr)<\/title>/m) {
                $flickr_title = $1;
                $flickr_title =~ s/[ \/]/_/g;
                print "title = $flickr_title\n";

                my $dir_postfix = 0;
                my $ori_flickr_title = $flickr_title;
                while ( -e $flickr_title) {
                    if ( -f "$flickr_title/url.txt") {
                        open FR, '<', "$flickr_title/url.txt";
                        chomp (my $test_url = <FR>);
                        close FR;

                        if ($test_url eq $flickr_url) {
                            last;
                        }
                    }
                    $flickr_title = "$ori_flickr_title.$dir_postfix";
                    $dir_postfix++;
                }

                if ( ! -e $flickr_title) {
                    mkdir $flickr_title;
                    chdir $flickr_title;
                    $in_dir = 1;

                    open FW, '>', 'url.txt';
                    print FW "$flickr_url\n";
                    close FW;
                } else {
                    print "Find <$flickr_title>, continue to download photos...\n";
                    chdir $flickr_title;
                    $in_dir = 1;
                }
            } else {
                print "Photoset title not found.\n";
                return;
            }
        }

        print "=== Go get $flickr_url ===\n";
        # 
        # try to find next page link
        #
        if ($flickr_page =~ /<span class="this-page">(\d+)<\/span>/m) {
            my $this_page = $1;
            my $next_page = $this_page + 1;
            if ($flickr_page =~ /<a .*?data-track="page-$next_page" href="([^"]+)"/m) {
                $flickr_url = "https://www.flickr.com$1";
                $has_next_page = 1;
            }
        }
        parse_page($flickr_page, $flickr_title);
    }
    chdir '..';
}

sub test_fetch_tool()
{
    $fetch_tool = do {
        if (`which wget` ne '')     { 'wget' }
        elsif (`which curl` ne '')  { 'curl' }
        else                        { '' }
    };

    if ($fetch_tool eq '') {
        print STDERR 'Error: You must have ``wget\'\' or ``curl\'\' to fetch images', "\n";
        exit 1;
    }
}

sub main(@)
{
    my $target = $_[0];

    test_fetch_tool();

    if ( -f $target) {
        open FR, '<', $target;
        my @urls = <FR>;
        close FR;

        foreach (@urls) {
            chomp;
            download_photoset($_);
        }
    } else {
        download_photoset($target);
    }
}

main(@ARGV);

__END__
