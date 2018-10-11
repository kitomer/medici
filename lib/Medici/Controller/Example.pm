package Medici::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

# This action will render a template
sub welcome
{
  my $c = shift;

	if ( not $c->user_exists ) {

        $c->flash( message => 'You must log in to view this page' );

        $c->redirect_to('/login');

        return;

    }
    else {

        $c->render( template => 'welcome' );

}
	
  my $db = $c->sqlite->db;
  #$c->render(json => $db->query('select datetime("now","localtime") as now')->hash);
	
	$c->render(text => ($c->is_user_authenticated) ? 'authenticated' : 'not authenticated');
  #$c->render(json => $db->query('select * from social_profile')->hash);
  
  # Render template "example/welcome.html.ep" with message
  #$c->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

1;
