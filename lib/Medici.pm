package Medici;
use Mojo::Base 'Mojolicious';

use Data::Dumper;
use Mojo::SQLite;
use Mojolicious::Sessions;

use Medici::Helpers::ACL;
use Medici::Model::Media::Collection;
use Medici::Model::Media::Item;
use Medici::Model::Media::Pile;
use Medici::Model::Social::Community;
use Medici::Model::Social::Profile;
use Medici::Model::Social::Group;

# This method will run once at server start
sub startup {
  my $app = shift;
  $app->secrets(['To run or not to run. When in doubt, rephrase and rethink.']);

  # Load configuration from hash returned by "my_app.conf"
  my $config = $app->plugin('Config');
  $app->plugin(
    'FormFieldsFromJSON' => {
      'dir' => 'fields/',
      'template' => '<label for="<%= $id %>"><%= $label %>:</label><div><%= $field %></div>',
    }
  );
  
  $app->helper(
    sqlite => sub {
      state $sql = Mojo::SQLite->new('sqlite:db/medici.db');
      $sql->migrations->from_file('schema/medici.sql')->migrate;
      $sql;
    });

  $app->helper(
    acl => sub {
      state $acl = Medici::Helpers::ACL->new();
    });

  # Documentation browser under "/perldoc"
  $app->plugin('PODRenderer') if $config->{perldoc};
  
	#my $sessions = Mojolicious::Sessions->new();
	#$sessions->cookie_name('medici');
	#$sessions->cookie_domain('localhost');
	#$sessions->default_expiration(86400);
	#$sessions->load(Mojolicious::Controller->new());

	$app->plugin('Authentication' => {
		autoload_user => 1,
		load_user => sub {
			my( $app, $uid ) = @_;
			my $db = $app->sqlite->db;
			print "load some: ".$uid."\n";
			return $db->query('SELECT * FROM social_profile WHERE profile_uid = ?', $uid)->hash();
		},
		validate_user => sub {
			my( $c, $username, $password, $extradata ) = @_;
			my $db = $app->sqlite->db;
			my $user = $db->query('SELECT * FROM social_profile WHERE profile_username = ? AND profile_password = ?', $username, $password)->hash();

			#my $salt = substr $password, 0, 2;
      #if ( $c->bcrypt_validate( $password, $res->{user_passwd} ) ) {

			$c->session(user => $username);
			$c->flash(message => 'Thanks for logging in.');
			
			#print "found some: ".Dumper($user)."\n";
			return ( defined $user ? $user->{'profile_uid'} : undef );
		},
		current_user_fn => 'user', # compatibility with old code
	});
	$app->sessions->default_expiration(3600); # set expiry to 1 hour

	# Router
  my $r = $app->routes;

  # Normal route to controller
  $r->get('/')->to('Example#welcome');
	
  $r->any('/login')->to('Auth#login');
}

1;
