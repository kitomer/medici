package Medici;
use Mojo::Base 'Mojolicious';

use Mojo::SQLite;
use Medici::Helpers::ACL;
use Medici::Model::Media::Collection;
use Medici::Model::Media::Item;
use Medici::Model::Media::Pile;
use Medici::Model::Social::Community;
use Medici::Model::Social::Profile;
use Medici::Model::Social::Group;

# This method will run once at server start
sub startup {
  my $self = shift;
  $self->secrets(['To run or not to run. When in doubt, rephrase and rethink.']);

  # Load configuration from hash returned by "my_app.conf"
  my $config = $self->plugin('Config');
  $self->plugin(
    'FormFieldsFromJSON' => {
      'dir' => 'fields/',
      'template' => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
    }
  );
  
  $self->helper(
    sqlite => sub {
      state $sql = Mojo::SQLite->new('sqlite:db/medici.db');
      $sql->migrations->from_file('schema/medici.sql')->migrate;
      $sql;
    });

  $self->helper(
    acl => sub {
      state $acl = Medici::Helpers::ACL->new();
    });

  # Documentation browser under "/perldoc"
  $self->plugin('PODRenderer') if $config->{perldoc};
  
  # Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
  $r->get('/user/new')->to('example#newuser');
}

1;
