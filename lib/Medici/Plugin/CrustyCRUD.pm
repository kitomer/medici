package Medici::Plugin::CrustyCRUD;
use base 'Mojolicious::Plugin';

use Data::Dumper;

sub register
{
	my( $self, $app ) = @_;
	$app->helper( crud => sub { return crud( @_ ) } );
	push @{$app->renderer->classes}, 'Medici::Plugin::CrustyCRUD';
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
=pod

	- medici: crud( $fixed, $dynamic, $defaults ) prinzipien:
		-> the 3 sets of parameters control the behaviour:
				$fixed are ALWAYS used, $dynamic params are tried and if not supplied, $defaults params are used
		-> internally all known parameters ahave internal defaults as well (which are used as a last resort)
		-> SOME parameters can only be set fixed (e.g. templates etc.)
		-> templates fallbacks: mojos std. render fkt. is used (uses either embedded or file templates)
		-> there is a template-name-fallback in place to have all kinds of templates (from very generic to very specific)

=cut
	my( $c, %params ) = @_;
	my $app = $c->app;
	return 'No -db given' if ! exists $params{'-db'};
	return 'No -table given' if ! exists $params{'-table'};
	my $dbname = $params{'-db'};
	my $table = $params{'-table'};

	# renders data using a chain of fallback template names
	my $r =
		sub {
			my( $tmplnames, $data ) = @_;
			foreach my $tmpl ( @{$tmplnames} ) {
				#print "TRY $tmpl\n";
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
			return \@t;
		};

	my %edit = map { $_ => undef } split /,/, $v->('edit',''); # ids of rows to be shown in edit mode
	
	my $db = $app->db( $dbname );
	my @rows = $db->find( -table => $table );
	#my $_results = $db->query('SELECT * FROM '.$table.);
	#my @rows;
	#while( my $row = $results->hash ) {
	#	push @rows, $row;
	#}
	#print Dumper(\@rows);
	
	# render output
	my $o_title .= $r->( $t->('title'), { 'title' => $v->('-title',ucfirst($table)) } );
	my $o_tbody = '';
	for( my $i = 0; $i < scalar @rows; $i++ )
	{
		my $row = $rows[$i];

		my $o_row = '';
		my @colnames = ('id', sort grep { $_ ne 'id' } keys %{$row} );
		foreach my $colname ( @colnames )	{
			my $o_col = $r->( $t->('col',$table,$colname,$row->{'id'}),	{ 'content' => $row->{$colname} } );
			$o_row .= $o_col;
		}
		$o_tbody .= $r->( $t->('row',$table,$row->{'id'}), { 'content' => $o_row } );
		# ...
	}
	my $o_table = $r->( $t->('table',$table), { 'title' => $o_title, 'body' => $o_tbody } );
	return $o_table;
}

1;

__DATA__

@@ crud/title.html.ep
<h1><%= $title %></h1>

@@ crud/table.html.ep
<%= b($title) %>
<form action="" method="">
	<table>
		<%= b($body) %>
	</table>
</form>

@@ crud/row.html.ep
<tr>
	<%= b($content) %>
</tr>

@@ crud/col.html.ep
<td>
	<%= b($content) %>
</td>

