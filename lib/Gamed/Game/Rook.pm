package Gamed::Game::Rook;

use parent qw/Gamed::Game/;

sub build {
    my $self = shift;
    $self->{seat} = [ map { { name => $_ } } ( 'n', 'e', 's', 'w' ) ];
    $self->{state_table} = {
        WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new('DEALING'),
        DEALING             => Gamed::State::Dealing->new(
            {
                next => 'BIDDING',
                deck => Gamed::Object::Deck::Rook->new('partnership'),
                deal => { seat => 10, nest => 5 },
            }
        ),
        BIDDING => Gamed::State::Bidding->new(
            {
                next  => 'DECLARING',
                min   => 100,
                max   => 200,
                valid => sub { $_[0] % 5 == 0 }
            }
        ),
        DECLARING => Gamed::Game::Rook::Declaring->new('PLAYING'),
        #PLAYING => Gamed::State::PlayTricks->new('SCORING'),
        #SCORING => Gamed::Game::Rook::Scoring->new,
        #FINISHED => Gamed::State::GameOver->new,
    };
    $self->change_state('WAITING_FOR_PLAYERS');
}

1;
