package Medici::Plugin::PerlyStore;
use base 'Mojolicious::Plugin';

use Medici::Helpers::PerlyStore;

sub register
{
	my( $self, $app ) = @_;

	my $base_path = 'db';
	if( opendir( my $dh, $base_path ) ) {
		foreach my $e ( readdir $dh ) {
			next if $e =~ /^\.+$/;
			next unless -d $base_path.'/'.$e;
			my $dbname = $e;
			   $dbname =~ s/^(.*)\..*$/$1/;
			my $db = Medici::Helpers::PerlyStore->new( $base_path.'/'.$e );
			$app->helper( 'db_'.$dbname => sub { $db } );
		}
		closedir $dh;
	}
}


1;
