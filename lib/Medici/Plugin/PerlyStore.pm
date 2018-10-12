package Medici::Plugin::PerlyStore;
use base 'Mojolicious::Plugin';

# abstracts a perlish api onyo various rdbms and key/value stores

use Mojo::SQLite;
use Memcached;
use LMDB;
# ...		

sub find {}
sub update {}
sub delete {}


sub table_info # get table info, includes fields info
{
	my( $tablename ) = @_;
	my $qu = query( 'PRAGMA table_info('._quotename($tablename).')' );
	# example result:
	#	cid      name          type     notnull  dflt_value  pk     
	#	-------  ------------  -------  -------  ----------  -------
	#	0        account_id    text     1                    0      
	#	1        account_name  text     1                    0      	
	my %columns = (); # <name> => <sqltype>
	while (my $row = $qu->fetchrow_hashref()) {
		$columns{ $row->{'name'} } = $row->{'type'};
	}
	return ( scalar keys %columns ? \%columns : undef );
}

sub init_table # create new table
{
	my( $tablename, $columns, $rows_to_insert ) = @_;
	$rows_to_insert = [] unless defined $rows_to_insert;

	#create( -table => 'table', -row => { 'name' => $tablename } );
	
=pod
	# create id column
	my $created_id_column = 0;
	for( my $i = 0; $i < scalar @{$columns} - 1; $i += 2 ) {
		last if $created_id_column;
		my( $columnname, $columntype ) = ( $columns->[$i], $columns->[$i+1] );
		next if $columnname ne 'id';
		create( -table => 'column', -where_tablename => $tablename, 
						-row => { 'name' => $columnname, 'type' => $columntype } );
		$created_id_column = 1;
	}
	return 0 unless $created_id_column;
=cut

	# other columns
	for( my $i = 0; $i < scalar @{$columns} - 1; $i += 2 ) {
		my( $columnname, $columntype ) = ( $columns->[$i], $columns->[$i+1] );
		next if $columnname eq 'id';
		create( -table => 'column', -where_tablename => $tablename, 
						-row => { 'name' => $columnname, 'type' => $columntype } );
	}
	# insert initial data
	if( defined query( $sql ) ) {
		map { create( -table => $tablename, -row => $_, -accesscheck => 0 ) } @{$rows_to_insert};
	}

=pod
	unless( defined table_info( $tablename ) ) {
		my @columns;
		for( my $i = 0; $i < scalar @{$columns}; $i += 2 ) {
			my $addon = ( $columns->[$i] eq 'id' ? ' PRIMARY KEY' : '' );
			push @columns, _quotename($columns->[$i]).' '._typename_to_sql($columns->[$i+1]).$addon;
		}
		my $sql = 'CREATE TABLE '._quotename($tablename).' ('.join(', ', @columns).')';
		if( defined query( $sql ) ) {
			map { create( -table => $tablename, -row => $_, -accesscheck => 0 ) } @{$rows_to_insert};
		}
	}
	return 0;
=cut
}

=pod
sub alter_table # rename/change table
{
	my( $tablename, $new_tablename, $fields ) = @_;
	# on-demand
	# ...
	#	if defined table_info(<name>)
	#		ALTER TABLE t RENAME TO x
	return 1;
}

sub drop_table # drop table(s)
{
	my( @tablenames ) = @_;
	# on-demand
	# ...
	#	if defined table_info(<name>)
	#		DROP TABLE <name>;
	return 1;
}

sub create_column # create field(s)
{
	my( $tablename, $column ) = @_;
	my %tab = table_info( $tablename );
	if( scalar keys %tab && ! exists $tab{$column->{'name'}} ) {
		return defined
			query( 	'ALTER TABLE '._quotename($tablename).' '.
							'ADD COLUMN '._quotename($column->{'name'}).' '.
							_typename_to_sql($column->{'name'}) );
	}
	return 0;
}

sub alter_column # rename/change field
{
	my( $tablename, $fieldname, $new_fieldname, $type, $new_type ) = @_;
	# on-demand
	# ...
	#	-> RENAME and CHANGE TYPE is not supported, only DROP
	#	if defined table_info(<name>) && column exists
	#		ALTER TABLE <name> DROP COLUMN <column>
	return 1;
}

sub drop_column # drop field(s)
{
	my( $tablename, @fieldnames ) = @_;
	# on-demand
	# ...
	#	if defined table_info(<name>) && column exists
	#		ALTER TABLE <name> DROP COLUMN <column>;
	return 1;
}
=cut

sub backup_db # backup db
{
	my $file_basename = '';
	disconnect_db();
	#	shell: sqlite3 my_database.sq3 ".backup 'backup_file.sq3'"
	# ...
	connect_db();
	return $file_basename;
}

sub load_db_backup # load db backup
{
	my( $file_basename ) = @_;
	disconnect_db();
	#	shell: sqlite3 my_database.sq3 ' .restore [zielDatenbank] dateiBackup.db"
	# ...
	connect_db();
	return 1;
}


sub first
{
	my( @args ) = @_;
	my $qu = _find( @args, -limit => 1 );
	my $row = $qu->fetchrow_hashref();
	return $row;
}

sub find
{
	my( %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'tables' 		=> [],
			'table'     => '',
			'where' 		=> {},
			'wherelike' => {},
			'group' 		=> [],
			'order' 		=> [],
			'limit' 		=> 0,
			'offset' 		=> 0,
			'distinct' 	=> 0,
			'columns'		=> [],
			'joins'		  => {},
			'sortdir'		=> 'asc', # 'asc' or 'desc'
			'resolve'		=> [], # foreign-key column names that should be resolved to their actual values
			'accesscheck' => 1,
			'general'   => 0, # generalized result or original
		});
	my @tablenames = ( @{$opts->{'tables'}}, ( length $opts->{'table'} ? $opts->{'table'} : () ) );
	die "no tablename given" unless scalar @tablenames;

	if( $opts->{'table'} eq 'column' ) {
		return unless has_access( 'w', $opts->{'table'} );
		
		my %tables = builtin::tables();
		my @rows = ();
		foreach my $tablename ( keys %tables ) {
			my $table_info = table_info( $tablename );
			foreach my $columnname ( keys %{$tables{$tablename}} ) {
				push @rows, { 'table' => $tablename, 'name' => $columnname,
											'type' => _sqltype_to_typename($tables{$tablename}->{$columnname}) };
			}
		}
		return @rows;
	}
	
	my $qu = _find( $opts );
	my @rows = ();
	while (my $row = $qu->fetchrow_hashref()) {
		next if $opts->{'accesscheck'} && ! has_access( 'r', \@tablenames, $row );
		push @rows, $row;
	}
	return ( $opts->{'generalize'} ? generalize( \@rows, $tablenames[0] ) : @rows );
}


#	- foreign key constraints PER fieldname, e.g.
#		myfield__othertable or myfield__othertable__otherfield
#		wenn fieldname = othertablename und otherfield = id dann geht auch: otherfield__
sub _find
{
	my( $opts ) = @_;

	my @tables = map { _quotename($_) } @{$opts->{'tables'}};
	push @tables, _quotename($opts->{'table'}) if length $opts->{'table'};

	my @columns = map { _quotename($_) } @{$opts->{'columns'}};

	my @joins =
		map {
			_quotename($_).' = '._quotename($opts->{'joins'}->{$_});
		}
		keys %{$opts->{'joins'}};

	my @group = map { _quotename($_) } @{$opts->{'group'}};

	my @order = map { _quotename($_) } @{$opts->{'order'}};
	
	my $sql =
		'SELECT'
		.($opts->{'distinct'} == 1 ? ' DISTINCT' : '')
		.' '.(scalar @columns ? join(', ', @columns) : '*')
		.' FROM '.join(', ', @tables)
		.' WHERE '
		.(scalar keys %{$opts->{'where'}} ?
			_make_sql_where_clause($opts->{'where'})
			: '1')
		.(scalar keys %{$opts->{'wherelike'}} ?
			' AND '._make_sql_where_clause($opts->{'wherelike'}, 1)
			: '')
		.(scalar @joins ? ' AND '.join(' AND ', @joins) : '')
		.(scalar @group ? ' GROUP BY '.join(', ', @group) : '')
		.(scalar @order ? ' ORDER BY '.join(', ', @order).' '.uc($opts->{'sortdir'}) : '')
		.($opts->{'offset'} > 0 ? ' OFFSET '.$opts->{'offset'} : '')
		.($opts->{'limit'} > 0 ? ' LIMIT '.$opts->{'limit'} : '');
	
	return query($sql);
}

sub create
{
	my( %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => undef,
			'row' => {},
			'accesscheck' => 1
		});
	
	return if $opts->{'accesscheck'} && ! has_access( 'w', $opts->{'table'} );

	if( $opts->{'table'} eq 'column' ) {
		return 0 unless defined $opts->{'row'}->{'table'};
		return 0 unless defined $opts->{'row'}->{'name'};
		return 0 unless defined $opts->{'row'}->{'type'};
		
		my $tablename = $opts->{'row'}->{'table'};
		my $columnname = $opts->{'row'}->{'name'};
		my $columntype = $opts->{'row'}->{'type'};
		my $table_info = table_info( $tablename );
		unless( defined $table_info ) {
			my $sql = 'CREATE TABLE '._quotename($tablename).' ('._quotename('id').' '._typename_to_sql('int').' PRIMARY KEY)';
			return 0 unless defined query( $sql );
		}
		return 0 if $columnname eq 'id'; # implicitly created
		$table_info = table_info( $tablename );
		if( defined $table_info && ! exists $table_info->{$columnname} ) {
			my $sql = 'ALTER TABLE '._quotename($tablename).' ADD COLUMN '._quotename($columnname).' '._typename_to_sql($columntype);
			return 0 unless defined query( $sql );
		}
		return 1;
	}
	
	my @columns;
	my @values;
	map {
		push @columns, _quotename($_);
		push @values,  _quote($opts->{'row'}->{$_});
	}
	keys %{$opts->{'row'}};

	my $sql =
		  'INSERT'
			.' INTO '._quotename($opts->{'table'})
			.' ('.join(', ', @columns).')'
			.' VALUES ('.join(', ', @values).')';

	unless( defined query($sql) ) {
		die "failed to create row: ".Dumper($opts);
	}
	return $D->last_insert_id(undef, undef, $opts->{'table'}, 'id');
}

sub update
{
	my( %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => '',
			'set' => {},
			'where' => {},
			'wherelike' => {},
			'accesscheck' => 1,
		});
	
	if( $opts->{'accesscheck'} ) {
		if( $opts->{'table'} eq 'column' ) {
			return unless has_access( 'w', $opts->{'table'} );
		}
		# TODO: this is quite elaborate to fetch all matching rows and check their access etc.
		# maybe there is a faster way...
		my @rows = find( -table => $opts->{'table'}, -where => $opts->{'where'}, -wherelike => $opts->{'wherelike'} );
		foreach my $row ( @rows ) {
			return undef unless has_access( 'w', $opts->{'table'}, $row );
		}
	}

	if( $opts->{'table'} eq 'column' ) {
		# TODO
		# ...
		return 1;
	}

	my @sets =
		map {
			_quotename($_).' = '._quote($opts->{'set'}->{$_});
		}
		keys %{$opts->{'set'}};

	my $sql =
		  'UPDATE'
			.' '._quotename($opts->{'table'})
			.' SET '.join(', ', @sets)
			.' WHERE '
			.(scalar keys %{$opts->{'where'}} ?
				_make_sql_where_clause($opts->{'where'})
				: '1')
			.(scalar keys %{$opts->{'wherelike'}} ?
				' AND '._make_sql_where_clause($opts->{'wherelike'}, 1)
				: '');

	return query($sql);
}

sub remove
{
	my( %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => '',
			'where' => {},
			'wherelike' => {},
			'accesscheck' => 1,
		});

	if( $opts->{'accesscheck'} ) {
		if( $opts->{'table'} eq 'column' ) {
			return unless has_access( 'w', $opts->{'table'} );
		}
		# TODO: this is quite elaborate to fetch all matching rows and check their access etc.
		# maybe there is a faster way...
		my @rows = find( -table => $opts->{'table'}, -where => $opts->{'where'}, -wherelike => $opts->{'wherelike'} );
		foreach my $row ( @rows ) {
			return undef unless has_access( 'w', $opts->{'table'}, $row );
		}
	}
	
	if( $opts->{'table'} eq 'column' ) {
		# TODO
		# ...
		return 1;
	}

	my $sql =
		  'DELETE'
			.' FROM '._quotename($opts->{'table'})
			.' WHERE '
			.(scalar keys %{$opts->{'where'}} ?
				_make_sql_where_clause($opts->{'where'})
				: '1')
			.(scalar keys %{$opts->{'wherelike'}} ?
				' AND '._make_sql_where_clause($opts->{'wherelike'}, 1)
				: '');

	return query($sql);
}

sub load
{
	my( %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => '',
			'data' => '',
		});
	
	my $records	= _load_data($opts->{'data'});
	
	my $inserted = 0;
	foreach my $record (@{$records})
	{
		unless( exists $record->{'id'} ) {
			die "record does not have an id field, in data\n";
			return 0;
		}
		
		my $query =
			_find(
				-table  => $opts->{'table'},
				-where  => {'id' => $record->{'id'}},
				-limit  => 1,
			);
			
		if (my $row = $query->fetchrow_hashref()) {
			# do nothing
		}
		else {
			# insert
			create(
				-table => $opts->{'table'},
				-row   => $record,
			);
			$inserted ++;	
		}
	}
	return (scalar @{$records}, $inserted);
}

sub query
{
	my( $sql, $ignore_errors ) = @_;
	$ignore_errors = 0 unless defined $ignore_errors;

	#print "-------\n$sql\n";

	my $error = 0;
	my $sth = $D->prepare($sql);
	if( ! $sth && ! $ignore_errors ) {
		die 'the preparation of query ['.$sql.'] failed: '.$DBI::errstr."\n";
		$error = 1;
	}
	my $result = $sth->execute();
	if( ! $result && ! $ignore_errors ) {
		die 'the query ['.$sql.'] failed: '.$DBI::errstr."\n";
		$error = 1;
	}
	return ( $error ? undef : $sth );
}

sub tables
{
	my %tables = ();
	foreach my $name ( find( -table => 'sqlite_master', -where => { 'type' => 'table' } ) ) {
		$tables{$name->{'name'}} = table_info( $name->{'name'} );
	}
	return %tables;
}

# ------------------------------------------------------------------------------

sub _load_data
{
	my( $data ) = @_;
	
	my @records;
	my $current_id     = undef;
	my $current_field  = undef;
	my $current_record = {};
	foreach my $line (split /\r?\n/, $data) {
				
		if (defined $current_id && defined $current_field && $line =~ /^[\s\t]/) {
			# possibly field value line
			$line =~ s/^[\s\t]//;
			$current_record->{$current_field} .= $line;
		}
		else {
			if ($line =~ /^\[(\d+)\][\s\t\n\r]*$/) {
				# id line
				if (defined $current_id) {
					# save previous record
					push @records, $current_record;
				}
				# reset
				$current_id = $line;
				$current_id =~ s/^\[(\d+)\][\s\t\n\r]*$/$1/;
				$current_record = { 'id' => $current_id };
			}
			elsif ($line =~ /^(\w+)[\s\t]*([\:\.])(.*)\n\r?$/) {
				# field line
				my ($fieldname, $type, $value) = $line =~ /^(\w+)[\s\t]*([\:\.])(.*)\n\r?$/;
				if ($type eq ':') {
					$current_record->{$fieldname} = $value;
					$current_field = undef;
				}
				else {
					$current_record->{$fieldname} = '';
					$current_field = $fieldname;
				}
			}
		}
	}
	if (defined $current_id) {
		# save last record
		push @records, $current_record;
	}		
	return \@records;
}

sub _make_sql_where_clause
{
	my( $where, $use_like ) = @_;
	$use_like = 0 unless defined $use_like;
	
	my @parts =
		map {
			my $f = $_;
			my $fieldname  = _quotename($f);
			my $fieldvalue = 'NULL';
			if( defined $where->{$f} ) {
				$fieldvalue = ( ref $where->{$f} eq 'ARRAY' ? 
													'('.join(',', map { _quote($_) } @{$where->{$f}} ).')' :
													_quote($where->{$f}) );
			}
			my $s  = $fieldname;
			   $s .= ($use_like == 1 ? ' LIKE ' : 
									(defined $where->{$_} ? ( ref $where->{$_} eq 'ARRAY' ? ' IN ' : ' = ' ) : ' IS '));
			   $s .= ''.$fieldvalue;
			$s;
		}
		keys %{$where};
	
	return join(' AND ', @parts);
}

sub _quote
{
	my( @args ) = @_;
	my $quoted = $D->quote( @args );
	if( ! $quoted ) {
			die 'quote failed: '.DBI->errstr()."\n";
			return undef;
	}
	return $quoted;
}

# escapes a DB::Functional field identifier, e.g. "mytable.myfield" or "myfield" etc.
sub _quotename
{
	my( $fieldname ) = @_;
	#my $quoted = $D->quote_identifier( $fieldname );

	my @parts = split /\./, $fieldname;
	
	my $quoted;
	if (scalar @parts == 1) {
		$quoted = '`'.$parts[0].'`';
	} else {
		$quoted = '`'.$parts[0].'`'.'.'.'`'.$parts[1].'`';
	}
	return $quoted;
}

sub _parse_params
{
	my( $params, $defaults ) = @_;
	my $values = {};
	foreach my $key (keys %{$defaults}) {
		$values->{$key} = $defaults->{$key};
	}
	foreach my $key (keys %{$params}) {
		my $cleankey = lc $key;
		   $cleankey =~ s/^\-//;
		$values->{$cleankey} = $params->{$key}
			if exists $defaults->{$cleankey};
	}
	return $values;
}

1;
