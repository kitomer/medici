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
			#$c->session->{'logged_in'} = 'yes';
			#$c->session->{'profile_uid'} = 42;
			#$c->session(expiration => 604800);
			#$c->session('test' => 123);
			#$c->redirect_to('/');
			$msg = 'Auth success...'
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

sub logout
{
  my( $c ) = shift;
	#$c->logout();
	$c->session( expires => 1 );
	$c->redirect_to('/');
}

1;
