package Gamed::Player;

use JSON;
use Gamed::Login;

my $json = JSON->new->convert_blessed;

sub new {
    my $pkg = shift;
    my $self = bless $_[0], $pkg;
    $self->{game} = Gamed::Login->new;
    return $self;
}

sub handle {
    my ( $self, $msg_json ) = @_;
	print "$msg_json\n";
    my $msg = $json->decode($msg_json);
    for my $p (qw/before on after/) {
        ref($self->{game})->handle( $self->{game}, $self, $p, $msg );
    }
}

sub send {
    my ( $self, $cmd, $msg ) = @_;
    $msg->{cmd} = $cmd;
    $self->{sock}->send( $json->encode($msg) );
}

sub err {
    my ( $self, $reason ) = @_;
    chomp $reason;
    $self->{sock}->send( $json->encode( { cmd => 'error', reason => $reason } ) );
}

1;
