use strict;
use warnings;

use Plack::Builder;
use Plack::Request;
use Template;

use lib './lib';
use MyApp::Parser;

my $template_config = { INCLUDE_PATH => './templates' };
my $config = require "config.pl";

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    
    my $timelines;
    if ( $req->path eq '/feed' ){
        $timelines = MyApp::Parser::get_from_feed(
            $config->{feed_url}
        );
    }
    elsif( $req->path eq 'log' ){
#        $timelines   = MyApp::Parser::get_from_log();
    }
    else{
        return [ 404, [ "Content-Type" => "text/plain" ], ["Not Found"] ];
    }

    my $commit_logs = _format_commit_log( $timelines );
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


sub _format_commit_log{
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

