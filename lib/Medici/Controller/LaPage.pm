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
		msg => 'Welcome!',
		content => "hi...",
	);
}

# POST for a normal search, resulting in a JSON object containing HTML snippets
sub ouioui
{
  my( $c ) = @_;
	my $app = $c->app;

	#print Dumper($app->crud( -db => 'main', -table => 'table' ));
  $c->render(
		format => 'json',
		#msg => 'Welcome!',
		#content => $app->crud( -db => 'main', -table => 'table' )
	);
}

1;
