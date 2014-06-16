package bot;

use strict;
use warnings;

use File::Slurp;
use IO::Select;
use IO::Socket;
use JSON::XS;
use YAML::XS;
use FindBin;
use Getopt::Long;
use Data::Dumper;
$Data::Dumper::Terse = 1;

our $| = 1;
my ( $config, $socket, $token, $username, %f, $game, $bot );

sub import {
    my ( $pkg, $game_name ) = @_;
    $game = $game_name;
    strict->import;
    warnings->import;
    my $caller = caller(0);
    no strict 'refs';
    *{"$caller\::on"}     = \&register_callback;
    *{"$caller\::config"} = \&config;
    *{"$caller\::cmd"}    = \&send_cmd;
    *{"$caller\::play"}   = \&play;
}

sub register_callback {
    my ( $cmd, $callback ) = @_;
    $f{$cmd} = $callback;
}

sub config {
    $config;
}

sub send_cmd {
    my ( $cmd, $msg ) = @_;
    $msg ||= {};
    $msg = { $cmd => $msg } unless ref($msg) eq 'HASH';
    $msg->{cmd} = $cmd;
    $socket->send( encode_json $msg);
}

my %cmd = (
    login => sub {
        my $msg = shift;
        $socket->send(
            encode_json {
                cmd        => 'login',
                username   => $username || $config->{username},
                passphrase => $config->{passphrase},
                token      => $token,
            } );
    },
    error => sub {
        my $msg = shift;
        if ( $msg->{reason} eq 'Login failed' ) {
            $socket->send(
                encode_json {
                    cmd        => 'create_user',
                    username   => $config->{username},
                    passphrase => $config->{passphrase},
                    name       => $config->{name} } );
        }
    },
    welcome => sub {
        my $msg = shift;
        print "Connected\n";
        $token    = $msg->{token};
        $username = $msg->{username};
        write_file( ".$bot.session", encode_json( [ $token, $username ] ) );
        send_cmd 'games';
    },
    games => sub {
        my $msg = shift;
        die "$game not available on server, quitting.\n" unless grep { /$game/ } @{ $msg->{games} };
        my @games = grep { $_->{game} eq $game } @{ $msg->{instances} };
        if (@games) {
            print "Joining ", $games[0]{name}, "\n";
            send_cmd join => { name => $games[0]{name} };
        }
    },
    create => sub {
        my $msg = shift;
        if ( $msg->{game} eq $game ) {
            print "Joining ", $msg->{name}, "\n";
            send_cmd join => { name => $msg->{name} };
        }
    } );

sub unhandled {
    print 'Unhandled message: ', Data::Dumper->Dump( [shift], [''] );
}

sub play {
    die "Usage: $0 host config" unless @ARGV == 2;
    my $host = $ARGV[0];
    $bot = $ARGV[1];
    my $session = read_file(".$bot.session", err_mode => 'quiet');
    if ($session) {
        ( $token, $username ) = @{ decode_json $session};
    }
    my $file = read_file("$FindBin::Bin/$bot.yaml");
    $config = Load($file);

    $socket = IO::Socket::INET->new(
        PeerHost => $host,
        PeerPort => 3001,
        Proto    => 'tcp',
    );
    die "Can't connect to '$host'" unless $socket;
    $socket->autoflush(1);
    my $select = IO::Select->new($socket);

    my $buf;
    my $json = JSON::XS->new;
    while (1) {
        my @ready = $select->can_read(30);
        if (@ready) {
            $socket->recv( $buf, 4096 );
            my @messages = $json->incr_parse($buf);
            for my $msg (@messages) {
                my $func = $f{ $msg->{cmd} } || $cmd{ $msg->{cmd} } || \&unhandled;
                $func->($msg);
            }
        }
    }
}

1;