package Gamed::Handler;

use strict;
use warnings;

sub import {
	no strict 'refs';
	my $caller = caller(0);
	*{"$caller\::before"} = \&before;
	*{"$caller\::on"} = \&on;
	*{"$caller\::after"} = \&after;
	*{"$caller\::handle"} = \&handle;
	strict->import;
	warnings->import;
}

our %handler;

sub before {
    _install( 'before', @_ );
}

sub on {
    _install( 'on', @_ );
}

sub after {
    _install( 'after', @_ );
}

sub _install {
    my ( $when, $cmd, $code ) = @_;
	my $pkg = caller(1);
	if (ref($code) eq 'CODE') {
		$handler{$pkg}{$when}{$cmd} = $code;
	}
	else {
		$handler{$pkg}{$when}{$cmd} = $handler{$code}{$when}{$cmd};
	}
}

sub handle {
    my ( $obj, $player, $msg ) = @_;
    for my $p (qw/before on after/) {
        _handle( ref($obj), $obj, $player, $p, $msg );
    }
}

sub _handle {
	no strict;
    my ( $pkg, $obj, $player, $when, $msg ) = @_;
    *isa = *{"$pkg\::ISA"};
    for my $parent (@isa) {
        _handle( $parent, $obj, $player, $when, $msg );
    }
    my $name = $player->{user} ? $player->{user}{name} : 'undef';
    my $p = $handler{$pkg}{$when};
    for my $cmd ( $msg->{cmd}, '*' ) {
        #print( $pkg, " $when ", $cmd, " ($name)\n" ) if $p->{$cmd};
		my $player_data = exists $player->{game}{players} ? $player->{game}{players}{$player->{in_game_id}} : undef;
        $p->{$cmd}( $obj, $player, $msg, $player_data ) if $p && $p->{$cmd};
    }
    _handle( ref( $obj->{state} ), $obj->{state}, $player, $when, $msg )
      if defined $obj->{state} && ref($obj) eq $pkg;
}

1;
