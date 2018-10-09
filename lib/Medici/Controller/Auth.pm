package Medici::Controller::Auth;
use Mojo::Base 'Mojolicious::Controller';

use Mojolicious::Plugin::Authentication;

sub login
{
  my( $c ) = shift;

	if( $c->app->is_user_authenticated() ) {
		$c->redirect_to('/');
	}
	
	my $username = $c->param('username');
	my $password = $c->param('password');

	my $msg = '';
	if( defined $username && defined $password ) {
		# authenticate
		my $authenticated = $c->app->authenticate(
			$username, $password,
			#{ optional => 'extra data stuff' },
		);
		if( $authenticated ) {
			$msg = 'Logged in!';
			$c->redirect_to('/');
		}
		else {
			$msg = 'Failed to login. Please try again.';
		}
	}
	
	$c->render(
		msg => $msg,
		form => $c->form_fields( 'newuser', 'username' => { 'data' => '' }, 'password' => { 'data' => '' } ) );  

	#$self->stash( 'background' => 'test' );
  #$self->render( msg => 'new user: '.
	#  $self->form_fields( 'newuser', 'name' => { 'data' => 'hi' } ) );  
}

1;
