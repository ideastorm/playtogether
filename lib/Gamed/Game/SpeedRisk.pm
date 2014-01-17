package Gamed::Game::SpeedRisk;

use parent qw/Gamed::Game/;

sub build {
    my ($self, %args) = @_;
	my $board_module = "Gamed::Game::SpeedRisk::" . $args{board};
	eval {
		require "$board_module.pm";
		$self->{board} = $board_module->new();
	} or die "Unknown Risk board '" . $args{board} . "' specified";
	$self->{min_players} = 2;
	$self->{max_players} = $self->{board}{max_players};
    $self->{state_table} = {
        WAITING_FOR_PLAYERS => Gamed::State::WaitingForPlayers->new('PLACING'),
        PLACING             => Gamed::State->new,
		#PLACING             => Gamed::Game::SpeedRisk::Placing->new(),
        #        PLAYING             => Gamed::Game::SpeedRisk::Playing->new(),
        #        RUNNING             => Gamed::Game::SpeedRisk::Running->new(),
        GAME_OVER => Gamed::State->new,
    };
    $self->change_state('WAITING_FOR_PLAYERS');
}

1;
