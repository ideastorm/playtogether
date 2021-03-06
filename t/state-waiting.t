use strict;
use warnings;
use Test::More;
use Gamed;
use Gamed::Test;

subtest 'seat names given out' => sub {
    my ( $game, $p1, $p2 ) = game(
        [ 1, 2 ],
        {
            game  => 'Waiting',
            seats => [ 'n', 's' ],
        },
    );
    is( $p1->{in_game_id}, 'n' );
    is( $p2->{in_game_id}, 's' );
    is( ~~ keys %{ $game->{players} }, 2 );

    done();
};

subtest 'drop/rejoin with names' => sub {
    my $p3 = Gamed::Test::Player->new('3');
    my ( $game, $p1, $p2 ) = game(
        [ 1, 2 ],
        {
            game  => 'Waiting',
            seats => [qw/n e s w/],
        },
    );
    $p3->got( { cmd => 'create' } );
    is( $p1->{in_game_id}, 'n' );
    is( $p2->{in_game_id}, 'e' );

    $p1->quit();
    $p3->join('test');
    is( $p3->{in_game_id}, 'n' );

    $p1->join('test');
    is( $p1->{in_game_id}, 's', 'When seats are specified, ids are recycled' );

    done();
};

subtest 'game starts automatically with all players' => sub {
    my ( $game, $p1, $p2, $p3, $p4 ) = game( [ 1, 2, 3, 4 ], { game => 'Waiting', seats => [qw/n e s w/] } );
    is( $p1->{in_game_id}, 'n' );
    is( $p2->{in_game_id}, 'e' );
    is( $p3->{in_game_id}, 's' );
    is( $p4->{in_game_id}, 'w' );

    is( $game->{state}{name}, 'GameOver' );

    done();
};

sub done {
    delete $Gamed::instance{test};
    done_testing();
}
done_testing();

package Waiting;

use parent 'Gamed::Test::Game::Test';

use Gamed::States {
    start => Gamed::State::WaitingForPlayers->new( next => 'end' ),
    end   => Gamed::State::GameOver->new,
};

1;
