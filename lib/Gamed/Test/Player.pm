package Gamed::Test::Player;

use Data::UUID;
use Test::Builder;
my $tb   = Test::Builder->new;
my $uuid = Data::UUID->new;

sub new {
    my ( $pkg, $name ) = @_;
    $name ||= 'test';
    bless { sock => SocketMock->new, id => $uuid->create_b64, name => $name }, shift;
}

sub handle {
    my ( $self, $msg ) = @_;
    my $cmd = $msg->{cmd};
    for my $p (qw/before on after/) {
        for my $h ( @{ $self->{handlers} } ) {
            $h->handle( $self, $msg );
        }
    }
}

sub create {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $game, $name, $opts ) = @_;
    $opts ||= {};
    $opts->{cmd}  = 'create';
    $opts->{game} = $game;
    $opts->{name} = $name;
    $self->handle($opts);
    return $self->join($name);
}

sub join {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my ( $self, $name ) = @_;
    $self->handle( { cmd => 'join', name => $name } );
    my %players;
    for my $p ( values %{ $self->{game}{players} } ) {
        $players{ $p->{in_game_id} } = $p->{public};
    }
    Gamed::Test::broadcast(
        $self->{game},
        {   cmd     => 'join',
            players => \%players,
            player  => $self->{in_game_id},
        },
        "Got join"
    );
    return $self->{game};
}

sub quit {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    my $self = shift;
    $self->handle( { cmd => 'quit' } );
    Gamed::Test::broadcast( $self->{game}, { cmd => 'quit', player => $self->{in_game_id} }, 'Quit broadcast' );
}

sub game {
    my ( $self, $msg, $test, $desc ) = @_;
    $self->handle($msg);
    if ( defined $test ) {
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        $self->{sock}->got_one( $test, $desc );
    }
}

sub broadcast {
    my ( $self, $msg, $test, $desc ) = @_;
    $test ||= $msg;
    print Dumper $msg;
    $self->handle($msg);
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    Gamed::Test::broadcast_one( $self->{game}, $test, $desc );
}

sub got {
    my $self = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got(@_);
}

sub got_one {
    my $self = shift;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $self->{sock}->got_one(@_);
}

sub send {
    my ( $self, $cmd, $msg ) = @_;
    $msg->{cmd} = $cmd;
    $self->{sock}->send($msg);
}

sub err {
    my ( $self, $reason ) = @_;
    chomp($reason);
    $self->{sock}->send( { cmd => 'error', reason => $reason } );
}

1;
