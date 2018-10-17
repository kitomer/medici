package Medici::Plugin::CrustyCRUD;
use base 'Mojolicious::Plugin';

use Data::Dumper;

sub register
{
	my( $self, $app ) = @_;
	$app->helper( crud => sub { return crud( @_ ) } );
}

# render a list of records from a specific table with a lot of features:
# - specific individual rows can be shown in edit-mode
# - specific rows can be deleted prior to rendering
# - the list of rows is paginated
# - there is a form for creating a new row
# - rows can be filtered using an advanced query syntax
# - the rendering can be controlled by supplying custom templates
sub crud
{
	my( $app, %params ) = @_;
	return 'No -db given' if ! exists $params{'-db'};
	return 'No -table given' if ! exists $params{'-table'};
	my $dbname = $params{'-db'};
	my $table = $params{'-table'};

	# renders data using a chain of fallback template names
	my $r =
		sub {
			my( $tmplnames, $data ) = @_;
			foreach my $tmpl ( @{$tmplnames} ) {
				my $s = $c->render_to_string( $tmpl, format => 'html', %{$data} );
				return $s if defined $s;
			}
			return 'Failed to render data ('.join(', ',@{$tmplnames}).'): '.Dumper($data);
		};
	# returns a value from a hash or a given default
	my $v =
		sub {
			my( $name, $default ) = @_;
			return ( exists $params{$name} && defined $params{$name} ? $params{$name} : $default );
		};
	# generates a list of fallback template names
	my $t	=
		sub {
			my( $prefix, @parts ) = @_;
			my @t; # template names
			foreach my $preprefix ("crud/","") {
				my @p = @{[ @parts ]};
				foreach (0 .. scalar @p) {
					push @t, $preprefix.join('.',$prefix,@p);
					pop @p;
				}
			}
		};

	my %edit = map { $_ => undef } split /,/, $v->('edit',''); # ids of rows to be shown in edit mode
	
	my $db = $app->db( $dbname );
	my @rows = $db->find( -table => $table );
	#my $_results = $db->query('SELECT * FROM '.$table.);
	#my @rows;
	#while( my $row = $results->hash ) {
	#	push @rows, $row;
	#}
	
	# render output
	my $o_title .= $r->( $t->('title'), { 'content' => $v->('-title',ucfirst($table)) } );
	my $o_tbody = '';
	for( my $r = 0; $r < scalar @rows; $r++ )
	{
		my $row = $rows[$r];

		my $o_row = '';
		my @colnames = ('id', sort grep { $_ ne 'id' } keys %{$row} );
		foreach my $colname ( @colnames )	{
			$o_row .= $r->( $t->('col',$t,$colname,$row->{'id'}),	{ 'content' => $o_row } );
		}
		$o_tbody .= $r->( $t->('row',$t,$row->{'id'}), { 'content' => $o_row } );
		# ...
	}
	my $o_table = $r->( $t->('table',$t), { 'title' => $o_title, 'body' => $o_tbody } );
	return $o;
}

1;

__DATA__

@@ crud/title.html.ep
<h1><%= $title %></h1>

@@ crud/table.html.ep
<%= $title %>
<form action="" method="">
	<table>
		<%= $body %>
	</table>
</form>
