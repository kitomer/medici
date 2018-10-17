package Medici::Plugin::PerlyStore;
use base 'Mojolicious::Plugin';

use Data::Dumper;
use Medici::Helpers::PerlyStore;

sub register
{
	my( $self, $app ) = @_;

	my $base_path = 'db';
	if( opendir( my $dh, $base_path ) ) {
		my $lut = {}; # <dbname> => $db
		foreach my $e ( readdir $dh ) {
			next if $e =~ /^\.+$/;
			next unless -d $base_path.'/'.$e;
			my $dbname = $e;
			   $dbname =~ s/^(.*)\..*$/$1/;
			my $db = Medici::Helpers::PerlyStore->new( $base_path.'/'.$e );
			$app->helper( 'db_'.$dbname => sub { $db } );
			$lut->{$dbname} = $db;
		}
		#print Dumper($lut);
		$app->helper( 
			'db' => sub { 
				my( $app, $dbname ) = @_;
				( defined $dbname && exists $lut->{$dbname} ? $lut->{$dbname} : undef );
			}
		);
		closedir $dh;
	}
}


1;
