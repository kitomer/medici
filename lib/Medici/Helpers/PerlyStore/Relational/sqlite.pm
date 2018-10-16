package Medici::Helpers::PerlyStore::Relational::sqlite;
use base Medici::Helpers::PerlyStore;

use Data::Dumper;

our $TypeLUT = { # <typename> => [ <sqltype>, <default> ]
	'int' => [ 'INTEGER', 0 ],
	'str' => [ 'VARCHAR(255)', '' ],
	'txt' => [ 'TEXT', '' ],
	'ts' => [ 'INT8', 0 ],
	'bool' => [ 'BOOLEAN', 0 ],
	'real' => [ 'DOUBLE', 0.0 ],
	'bin' => [ 'BLOB', '' ],
};

sub _connect
{
	my( $self ) = @_;
	return 1 if defined $self->{'handle'};
	my $dbfile = $self->{'dir'}.'/db.sq3';
	#`touch '$dbfile'` unless -f $dbfile;
  $self->{'handle'} = DBI->connect( 'dbi:SQLite:dbname='.$dbfile, undef, undef, { AutoCommit => 1, PrintError => 0, RaiseError => 0, sqlite_unicode => 1 } );
	if( ! defined $self->{'handle'} || ! $self->{'handle'} ) {
		die "Error: could not connect to database: ".( defined $DBI::errstr ? $DBI::errstr : '?' )."\n";
		$self->{'handle'} = undef;
		return 0;
	}
	return 1;
}

sub _disconnect
{
	my( $self ) = @_;
	$self->{'handle'}->disconnect() if defined $self->{'handle'};
	$self->{'handle'} = undef;
	return 1;
}

sub _table_info # get table info, includes fields info
{
	my( $self, $tablename ) = @_;
	my $qu = $self->query( 'PRAGMA table_info('.$self->_quotename($tablename).')' );
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

sub _init_table # create new table
{
	my( $self, $tablename, $columns, $rows_to_insert ) = @_;
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
		$self->create( -table => 'column', -where_tablename => $tablename, 
					       	 -row => { 'name' => $columnname, 'type' => $columntype } );
	}
	# insert initial data
	if( defined $self->query( $sql ) ) {
		map { $self->create( -table => $tablename, -row => $_, -accesscheck => 0 ) } @{$rows_to_insert};
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
sub _alter_table # rename/change table
{
	my( $self, $tablename, $new_tablename, $fields ) = @_;
	# on-demand
	# ...
	#	if defined table_info(<name>)
	#		ALTER TABLE t RENAME TO x
	return 1;
}

sub _drop_table # drop table(s)
{
	my( $self, @tablenames ) = @_;
	# on-demand
	# ...
	#	if defined table_info(<name>)
	#		DROP TABLE <name>;
	return 1;
}

sub _create_column # create field(s)
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

sub _alter_column # rename/change field
{
	my( $self, $tablename, $fieldname, $new_fieldname, $type, $new_type ) = @_;
	# on-demand
	# ...
	#	-> RENAME and CHANGE TYPE is not supported, only DROP
	#	if defined table_info(<name>) && column exists
	#		ALTER TABLE <name> DROP COLUMN <column>
	return 1;
}

sub _drop_column # drop field(s)
{
	my( $self, $tablename, @fieldnames ) = @_;
	# on-demand
	# ...
	#	if defined table_info(<name>) && column exists
	#		ALTER TABLE <name> DROP COLUMN <column>;
	return 1;
}
=cut

sub _backup_db # backup db
{
	my( $self ) = @_;
	my $file_basename = '';
	$self->disconnect();
	#	shell: sqlite3 my_database.sq3 ".backup 'backup_file.sq3'"
	# ...
	return $file_basename;
}

sub _load_db_backup # load db backup
{
	my( $self, $file_basename ) = @_;
	$self->disconnect();
	#	shell: sqlite3 my_database.sq3 ' .restore [zielDatenbank] dateiBackup.db"
	# ...
	return 1;
}

sub _typename_to_sql
{
	my( $self, $type ) = @_;
	return '' unless exists $TypeLUT->{$type};
	my( $sqltype, $sqldefault ) = @{ $TypeLUT->{$type} };
	return $sqltype.' NOT NULL DEFAULT '.$self->_quote($sqldefault);
}

sub _sqltype_to_typename
{
	my( $self, $sqltype ) = @_;
	foreach my $typename (keys %{$TypeLUT}) {
		if( $TypeLUT->{$typename}->[0] eq $sqltype ){
			return $typename;
		}
	}
	return undef;
}

sub _find
{
	my( $self, %opts ) = @_;
	my @tablenames = $opts{'tables'};

	if( $opts{'tables'}->[0] eq 'column' ) {
		return unless $self->_has_access( 'w', $opts{'table'} );
		
		my %tables = $self->tables();
		my @rows = ();
		foreach my $tablename ( keys %tables ) {
			my $table_info = $self->table_info( $tablename );
			foreach my $columnname ( keys %{$tables{$tablename}} ) {
				push @rows, { 'table' => $tablename, 'name' => $columnname,
											'type' => $self->_sqltype_to_typename($tables{$tablename}->{$columnname}) };
			}
		}
		return @rows;
	}
	
	my $qu = $self->__find( \%opts );
	my @rows = ();
	while (my $row = $qu->fetchrow_hashref()) {
		next if $opts{'accesscheck'} && ! $self->_has_access( 'r', \@tablenames, $row );
		push @rows, $row;
	}
	return ( $opts{'generalize'} ? $self->generalize( \@rows, $tablenames[0] ) : @rows );
}


#	- foreign key constraints PER fieldname, e.g.
#		myfield__othertable or myfield__othertable__otherfield
#		wenn fieldname = othertablename und otherfield = id dann geht auch: otherfield__
sub __find
{
	my( $self, %opts ) = @_;

	my @tables = map { $self->_quotename($_) } @{$opts{'tables'}};
	#push @tables, $self->_quotename($opts{'table'}) if length $opts{'table'};

	my @columns = map { $self->_quotename($_) } @{$opts{'columns'}};

	my @joins =
		map {
			$self->_quotename($_).' = '.$self->_quotename($opts{'joins'}->{$_});
		}
		keys %{$opts{'joins'}};

	my @group = map { $self->_quotename($_) } @{$opts{'group'}};

	my @order = map { $self->_quotename($_) } @{$opts{'order'}};
	
	my $sql =
		'SELECT'
		.($opts{'distinct'} == 1 ? ' DISTINCT' : '')
		.' '.(scalar @columns ? join(', ', @columns) : '*')
		.' FROM '.join(', ', @tables)
		.' WHERE '
		.(scalar keys %{$opts{'where'}} ?
			$self->_make_sql_where_clause($opts{'where'})
			: '1')
		.(scalar keys %{$opts{'wherelike'}} ?
			' AND '.$self->_make_sql_where_clause($opts{'wherelike'}, 1)
			: '')
		.(scalar @joins ? ' AND '.join(' AND ', @joins) : '')
		.(scalar @group ? ' GROUP BY '.join(', ', @group) : '')
		.(scalar @order ? ' ORDER BY '.join(', ', @order).' '.uc($opts{'sortdir'}) : '')
		.($opts{'offset'} > 0 ? ' OFFSET '.$opts{'offset'} : '')
		.($opts{'limit'} > 0 ? ' LIMIT '.$opts{'limit'} : '');
	
	return $self->query($sql);
}

sub _create
{
	my( $self, %opts ) = @_;
	return if $opts{'accesscheck'} && ! $self->_has_access( 'w', $opts{'table'} );

	if( $opts{'table'} eq 'column' ) {
		return 0 unless defined $opts{'row'}->{'table'};
		return 0 unless defined $opts{'row'}->{'name'};
		return 0 unless defined $opts{'row'}->{'type'};
		
		my $tablename = $opts{'row'}->{'table'};
		my $columnname = $opts{'row'}->{'name'};
		my $columntype = $opts{'row'}->{'type'};
		my $table_info = $self->table_info( $tablename );
		unless( defined $table_info ) {
			my $sql = 'CREATE TABLE '.$self->_quotename($tablename).' ('.$self->_quotename('id').' '.$self->_typename_to_sql('int').' PRIMARY KEY)';
			return 0 unless defined $self->query( $sql );
		}
		return 0 if $columnname eq 'id'; # implicitly created
		$table_info = $self->table_info( $tablename );
		if( defined $table_info && ! exists $table_info->{$columnname} ) {
			my $sql = 'ALTER TABLE '.$self->_quotename($tablename).' ADD COLUMN '.$self->_quotename($columnname).' '.$self->_typename_to_sql($columntype);
			return 0 unless defined $self->query( $sql );
		}
		return 1;
	}
	
	my @columns;
	my @values;
	map {
		push @columns, $self->_quotename($_);
		push @values,  $self->_quote($opts{'row'}->{$_});
	}
	keys %{$opts{'row'}};

	my $sql =
		  'INSERT'
			.' INTO '.$self->_quotename($opts{'table'})
			.' ('.join(', ', @columns).')'
			.' VALUES ('.join(', ', @values).')';

	unless( defined $self->query($sql) ) {
		die "failed to create row: ".Dumper($opts);
	}
	return $D->last_insert_id(undef, undef, $opts{'table'}, 'id');
}

sub _update
{
	my( $self, %opts ) = @_;

	if( $opts{'accesscheck'} ) {
		if( $opts{'table'} eq 'column' ) {
			return unless $self->_has_access( 'w', $opts{'table'} );
		}
		# TODO: this is quite elaborate to fetch all matching rows and check their access etc.
		# maybe there is a faster way...
		my @rows = $self->find( -table => $opts{'table'}, -where => $opts{'where'}, -wherelike => $opts{'wherelike'} );
		foreach my $row ( @rows ) {
			return undef unless $self->_has_access( 'w', $opts{'table'}, $row );
		}
	}

	if( $opts{'table'} eq 'column' ) {
		# TODO
		# ...
		return 1;
	}

	my @sets =
		map {
			$self->_quotename($_).' = '.$self->_quote($opts{'set'}->{$_});
		}
		keys %{$opts{'set'}};

	my $sql =
		  'UPDATE'
			.' '.$self->_quotename($opts{'table'})
			.' SET '.join(', ', @sets)
			.' WHERE '
			.(scalar keys %{$opts{'where'}} ?
				$self->_make_sql_where_clause($opts{'where'})
				: '1')
			.(scalar keys %{$opts{'wherelike'}} ?
				' AND '.$self->_make_sql_where_clause($opts{'wherelike'}, 1)
				: '');

	return $self->query($sql);
}

sub _remove
{
	my( $self, %opts ) = @_;

	if( $opts{'accesscheck'} ) {
		if( $opts{'table'} eq 'column' ) {
			return unless $self->_has_access( 'w', $opts{'table'} );
		}
		# TODO: this is quite elaborate to fetch all matching rows and check their access etc.
		# maybe there is a faster way...
		my @rows = $self->find( -table => $opts{'table'}, -where => $opts{'where'}, -wherelike => $opts{'wherelike'} );
		foreach my $row ( @rows ) {
			return undef unless $self->_has_access( 'w', $opts{'table'}, $row );
		}
	}
	
	if( $opts{'table'} eq 'column' ) {
		# TODO
		# ...
		return 1;
	}

	my $sql =
		  'DELETE'
			.' FROM '.$self->_quotename($opts{'table'})
			.' WHERE '
			.(scalar keys %{$opts{'where'}} ?
				$self->_make_sql_where_clause($opts{'where'})
				: '1')
			.(scalar keys %{$opts{'wherelike'}} ?
				' AND '.$self->_make_sql_where_clause($opts{'wherelike'}, 1)
				: '');

	return $self->query($sql);
}

sub _load
{
	my( $self, %opts ) = @_;
	
	my $records	= $self->__load_data($opts{'data'});
	
	my $inserted = 0;
	foreach my $record (@{$records})
	{
		unless( exists $record->{'id'} ) {
			die "record does not have an id field, in data\n";
			return 0;
		}
		
		my $query =
			$self->__find(
				-table  => $opts{'table'},
				-where  => {'id' => $record->{'id'}},
				-limit  => 1,
			);
			
		if (my $row = $query->fetchrow_hashref()) {
			# do nothing
		}
		else {
			# insert
			$self->create(
				-table => $opts{'table'},
				-row   => $record,
			);
			$inserted ++;	
		}
	}
	return (scalar @{$records}, $inserted);
}

sub _query
{
	my( $self, $sql, $ignore_errors ) = @_;
	$ignore_errors = 0 unless defined $ignore_errors;
	$self->connect();

	#print "-------\n$sql\n";
	#print Dumper($self);
	print "($ignore_errors)\n";

	my $error = 0;
	my $sth = $self->{'handle'}->prepare($sql);
	if( ( ! defined $sth || ! $sth ) && ! $ignore_errors ) {
		die 'The preparation of query ['.$sql.'] failed: '.$DBI::errstr."\n";
		$error = 1;
	}
	print Dumper($sth);
	my $result = $sth->execute();
	if( ! $result && ! $ignore_errors ) {
		die 'The query ['.$sql.'] failed: '.$DBI::errstr."\n";
		$error = 1;
	}
	return ( $error ? undef : $sth );
}

sub _tables
{
	my( $self ) = @_;
	my %tables = ();
	foreach my $name ( $self->find( -table => 'sqlite_master', -where => { 'type' => 'table' } ) ) {
		$tables{$name->{'name'}} = $self->table_info( $name->{'name'} );
	}
	return %tables;
}

# ------------------------------------------------------------------------------

sub __load_data
{
	my( $self, $data ) = @_;
	
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
	my( $self, $where, $use_like ) = @_;
	$use_like = 0 unless defined $use_like;
	
	my @parts =
		map {
			my $f = $_;
			my $fieldname  = $self->_quotename($f);
			my $fieldvalue = 'NULL';
			if( defined $where->{$f} ) {
				$fieldvalue = ( ref $where->{$f} eq 'ARRAY' ? 
													'('.join(',', map { $self->_quote($_) } @{$where->{$f}} ).')' :
													$self->_quote($where->{$f}) );
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

1;
