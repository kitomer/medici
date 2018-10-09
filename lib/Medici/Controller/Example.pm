package Medici::Controller::Example;
use Mojo::Base 'Mojolicious::Controller';

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

1;
