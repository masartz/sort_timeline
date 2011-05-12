use strict;
use warnings;
    
use Plack::Builder;
use Plack::Request;
use Template;
use XML::Feed;
use Encode;

my $template_config = { INCLUDE_PATH => './templates' };
my $config = require "config.pl";

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    
    my $timelines   = _parse_timeline();
    my $commit_logs = _format_log( $timelines );
    my $args = { commit_logs => $commit_logs } if defined $commit_logs;
    
    my $res = $req->new_response(200);
    $res->content_type('text/html');
    $res->body( _render( 'index.html', $args ) );
    $res->finalize;
};

sub _render {
    my ( $name, $args ) = @_;
    my $tt = Template->new($template_config);
    my $out;
    $tt->process( $name, $args, \$out );
    return $out;
}

sub _parse_timeline {
    my $feed = XML::Feed->parse(
        URI->new( $config->{feed_url} ) )
      or return [];
    my @timelines;
    for my $entry ( $feed->entries() ) {

        my $comment = $entry->content->body;
        $comment =~ s!^<p>!!;
        $comment =~ s!</p>$!!;

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

sub _format_log{
    my $timeline = shift;

    my %logs;
    for my $entry ( @{$timeline} ){
        
        push  @{ $logs{ $entry->{author} } } , +{
            title      => $entry->{title},
            link       => $entry->{link},
            timestamp  => $entry->{timestamp},
            comment    => $entry->{comment},
        };
    }

    my @commit_logs = map {
        +{  
            name   => $_  ,
            entries=> $logs{$_},
        }
    } sort keys %logs;

    return \@commit_logs;
}

builder {
    enable "Plack::Middleware::Static",
      path => qr/static/,
      root => '.';
    $app;
};

