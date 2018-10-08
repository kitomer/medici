package Medici::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

#use Mojolicious::Plugin::Authentication;

# This action will render a template
sub welcome
{
  my $self = shift;

  my $db = $self->sqlite->db;
  #$self->render(json => $db->query('select datetime("now","localtime") as now')->hash);
  $self->render(json => $db->query('select * from social_profile')->hash);
  
  # Render template "example/welcome.html.ep" with message
  #$self->render(msg => 'Welcome to the Mojolicious real-time web framework!');
}

sub newuser
{
  my $self = shift;
  $self->stash( 'background' => 'test' );
  $self->render( msg => 'new user: '.
	  $self->form_fields( 'newuser', 'name' => { 'data' => 'hi' } ) );  
}

1;
