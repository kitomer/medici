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
  
	$self->plugin('Authentication' => {
		autoload_user => 1,
		session_key => 'medici',
		load_user => sub {
			my( $app, $uid ) = @_;
			my $db = $self->sqlite->db;
			return $db->query('SELECT * FROM social_profile WHERE profile_uid = ?', $uid)->hash();
		},
		validate_user => sub {
			my( $c, $username, $password, $extradata ) = @_;
			my $db = $self->sqlite->db;
			my $user = $db->query('SELECT * FROM social_profile WHERE profile_username = ? AND profile_password = ?', $username, $password)->hash();
			return ( defined $user ? $user->{'profile_uid'} : undef );
		},
		current_user_fn => 'user', # compatibility with old code
	});

	# Router
  my $r = $self->routes;

  # Normal route to controller
  $r->get('/')->to('example#welcome');
}

1;
