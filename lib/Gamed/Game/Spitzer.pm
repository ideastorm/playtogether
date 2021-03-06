package Gamed::Game::Spitzer;

use Gamed::Handler;
use Gamed::Game::Spitzer::Announcing;
use Gamed::Game::Spitzer::PlayLogic;

use parent 'Gamed::Game';

use Gamed::States {
    WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new( next => 'DEALING' ),
    DEALING             => Gamed::State::Dealing->new(
        next => 'ANNOUNCING',
        deck => Gamed::Object::Deck::FrenchSuited->new('spitzer'),
        deal => 8,
    ),
    ANNOUNCING => Gamed::Game::Spitzer::Announcing->new,
    PLAYING    => Gamed::State::PlayTricks->new( next => '?', logic => Gamed::Game::Spitzer::PlayLogic->new ),
    GAME_OVER  => Gamed::State::GameOver->new,
};

on 'create' => sub {
    my ( $self, $player, $msg ) = @_;
    $self->{public}{rules}{play_to}          = $msg->{points} ? int($msg->{points}) : 42;
    $self->{public}{rules}{reztips}          = 1 if $msg->{reztips};
    $self->{states}{PLAYING}{logic}{reztips} = 1 if $msg->{reztips};
    $self->{public}{rules}{allow_schneider}  = 1 if $msg->{allow_schneider};
    $self->{public}{rules}{autocount}        = 1 if $msg->{autocount};
    $self->{seats}       = [qw/n e s w/];
    $self->change_state('WAITING_FOR_PLAYERS');
};

before 'join' => sub {
    my ( $self, $player, $msg ) = @_;
    die "Game in progress\n" unless $self->{state}{name} eq 'WaitingForPlayers';
};

1;
