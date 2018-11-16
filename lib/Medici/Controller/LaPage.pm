package Medici::Controller::LaPage;
use Mojo::Base 'Mojolicious::Controller';

use Data::Dumper;

# GET for a normal search, resulting in a complete HTML page
sub oui
{
  my( $c ) = @_;
	my $app = $c->app;

	#print Dumper($app->crud( -db => 'main', -table => 'table' ));
  $c->render(
		'layouts/default',
		center => 'center...',
		detail => 'detail...',
		related => 'related...',
	);
}

# POST for a normal search, resulting in a JSON object containing HTML snippets
sub ouioui
{
  my( $c ) = @_;
	my $app = $c->app;

	#print Dumper($app->crud( -db => 'main', -table => 'table' ));
  $c->render(
		json => {
			center => 'center...',
			detail => 'detail...',
			related => 'IT WORKS - related...',	
			hash => 'hash-of-plain-search', # takes only the query parts into account that do NOT edit/delete!
		},
		#msg => 'Welcome!',
		#content => $app->crud( -db => 'main', -table => 'table' )
	);
}

1;
