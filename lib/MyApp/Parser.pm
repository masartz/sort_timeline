package MyApp::Parser;

use strict;
use warnings;

use XML::Feed;
use Encode;
use URI;

sub get_from_feed {
    my $feed_url = shift;

    my $feed = XML::Feed->parse(
        URI->new( $feed_url )
    ) or return [];

    my @timelines;
    for my $entry ( $feed->entries() ) {

        my $comment = $entry->content->body;
        $comment =~ s:^<p>::;
        $comment =~ s:</p>$::;

        my %row = (
            title      => $entry->title,
            link       => $entry->link, 
            author     => $entry->author,
            timestamp  => $entry->issued->datetime,
            comment    => $comment,
        );
        %row = map { $_ => Encode::encode_utf8( $row{$_} ) } keys %row;
        
        push @timelines , \%row;
    }
    return \@timelines;
}

sub get_from_log {
}

1;
