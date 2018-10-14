package Medici::Plugin::PerlyStore;
use base 'Mojolicious::Plugin';

use Medici::Helpers::PerlyStore;

sub register
{
	my( $self, $app ) = @_;

	my $base_path = 'where/to/find/dbs';
	if( opendir( my $dh, $base_path ) ) {
		foreach my $e ( readdir $dh ) {
			$app->helper(
				'db_'.$dbname => 
					sub { 
						state $db = Medici::Helpers::PerlyStore->new( $base_path.'/'.$e );
						return $db;
					} 
			);
		}
		closedir $dh;
	}
}


1;
