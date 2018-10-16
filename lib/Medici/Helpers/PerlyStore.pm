package Medici::Helpers::PerlyStore;

use Data::Dumper;

=pod

	- KeyValue::* engines store multiple tables! and each table has specific column names,
		where the primary key column is specified. all of this meta info stored in JSON, e.g.
			{ "tables": { "tablename": { "columns": { "key": { "type": "string" }, "value": ... } } }
	- upsert() -> calls find() and create() or update()
	- get( $tablename, $key ) as shortcuts to find()
	- set( $tablename, $key, $value ) as shortcuts to upsert()
	- rem( $tablename, $key ) as shortcut to remove()
	- call _has_access() when needed
	- let _has_access() be passed as an external callback sub
	- call _generalize() when needed
	- call connect() in each sub that needs it

	my $st = Medici::Helpers::PerlyStore->new( 'path/to/mydb' );
	$st->find(...);

	Medici::Plugin::PerlyStore
		- basic interface to any kind of dbms (relational or key/value):
			has find(), create(), remove(), ...
		- PerlyStore impl. as MUCH behaviour as possible but sub-classes (e.g. PerlyStore::Memcached)
			may overwrite certain functions if needed
		- PerlyStore knows the available engines
		- engines are organized as subclasses: PerlyStore::<EngineKind>::<EngineName> e.g. PerlyStore::Relational::DBI or PerlyStore::KeyValue::Memcached
		- PerlyStore::new( $dir ) used to open a storage, syntax of $dir: “.../<StoreName>.<EngineName>”
				e.g. my $st = PerlyStore->new( ‘/path/to/mystore.memcached’ )
		- query language has basicly the same features as SQL (-where, -sort etc.)
		- find() does not work for key/value storages, use get() and set() instead
		- the special table named “columns” is used to manipulate the actual storage structure/schema
			(has limited ways of expression)

=cut

sub new
{
	my( $class, $directory ) = @_;
	my $self = bless {}, $class;
	$self->{'dir'} = $directory;
	$self->{'kind'} = ''; # Relational | KeyValue | ...
	$self->{'engine'} = '';
	$self->{'handle'} = undef;
	$self->_determine_engine( $directory );
	return $self;
}

sub _determine_engine
{
	my( $self, $directory ) = @_;
	my $engine = $directory;
	   $engine =~ s/^.*\.([^\.]+)$/$1/;
	foreach my $kind (qw(Relational KeyValue Text Binary)) {
		my $class = 'Medici::Helpers::PerlyStore::'.$kind.'::'.$engine;
		print "$class\n";
		eval 'use '.$class;
		unless( $@ ) {
			$self->{'kind'} = $kind;
			$self->{'engine'} = $engine;
			bless $self, $class;
			return 1;
		}
	}
	die "Could not determine PerlyStore engine (unknown engine '".$engine."')\n";
}

# -1 = $a, then $b
#  0 = $a same as $b
#  1 = else ($b, then $a)
sub _sort_by_fieldname
{
	return -1 if $a eq 'id'; # id always first
	return  1 if $b eq 'id';
	return $a cmp $b;
}

# turns data into generic array-of-hashes
sub _generalize
{
	my( $self, $rows, $tablename ) = @_;
	my $table_info = ( defined $tablename ? $self->table_info( $tablename ) : {} );
	my %auto_fields; # <fieldname> => <type> (auto-detected from first occurred value)
	my @res;
	foreach my $row ( @{$rows} ) {
		my @r;
		foreach my $key ( sort sort_by_fieldname keys %{$row} ) {
			my %f = ( 'name' => $key, 'value' => $row->{$key}, 
								'table' => ( defined $tablename ? $tablename : '' ), 'type' => 'txt' );
			if( defined $table_info && exists $table_info->{$key} ) {
				$f{'type'} = $table_info->{$key};
			}
			elsif( exists $auto_fields{$key} ) {
				$f{'type'} = $auto_fields{$key};
			}
			else {
				# auto-detect field type
				my $value = $row->{'key'};
				if( $value =~ /^\d+\.\d+$/ ) {
					$auto_fields{$key} = 'real';
				}
				elsif( $value =~ /^\d{10,}$/ ) {
					$auto_fields{$key} = 'ts';
				}
				elsif( $value =~ /^(0|1)$/ ) {
					$auto_fields{$key} = 'bool';
				}
				elsif( $value =~ /\0/ ) {
					$auto_fields{$key} = 'bin';
				}
				else { #elsif( length $value > 255 ) {
					$auto_fields{$key} = 'txt';
				}
				# type "str" not detectable since we don't know if upcoming values might be
				# larger than 255... (maybe better detectiong sometimes...)
				
				$f{'type'} = $auto_fields{$key} if exists $auto_fields{$key};
			}
			push @r, \%f;
		}
		push @res, \@r;
	}
	return @res;
}

sub _load_data
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

sub _quote
{
	my( $self, @args ) = @_;
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
	my( $self, $fieldname ) = @_;
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

sub _has_access
{
	my( $self, $r_or_w, $tablename, $row_or_id, $authenticate_if_needed ) = @_;
=pod
	security:
		- only sanitized params should be processed serverside (relies on programmers configuration effort)
		- auth is done through http basic auth
		- auth-names INCLUDE the groupname, e.g. “admin-kir”
		- existing groups are hardcoded and form a hierarchy:
				“admin” > “author” > “user”
		- everyone can r/w (delete, update) the rows they CREATED
		- each group can edit specific set of tables (s. access table)
		- a more powerful group is allowed all its lower groups accesses
		- every table with a column “owner” is access-controlled in this way
			-> when someone authenticates, his groupname is extracted and access rights can be determined
		- the table “access” can ONLY be accessed by “admin” group! (hardcoded special case)
=cut
	$row_or_id = 0 unless defined $row_or_id;
	$authenticate_if_needed = 0 unless defined $authenticate_if_needed;
	return 1 if ! defined $G;
	if( ref $tablename eq 'ARRAY' ) {
		foreach my $name ( @{$tablename} ) {
			return 0 unless has_access( $r_or_w, $name, $row_or_id, $authenticate_if_needed );
		}
		return 1;
	}
	else { # single table check
		my $allowed = 1;
		my $read = ( defined $R && exists $R->{$G} ? $R->{$G} : [] );
		my $write = ( defined $W && exists $W->{$G} ? $W->{$G} : [] );
		my $read_ok = ( scalar grep { $_ eq $tablename } @{$read} );
		my $write_ok = ( scalar grep { $_ eq $tablename } @{$write} );
		$allowed = $allowed && ( $r_or_w eq 'r' ? ( $read_ok || $write_ok ) : $write_ok );
		unless( $allowed ) { # check if owner, then always allowed
			my( $row ) = 	( ref $row_or_id eq 'HASH' ? ( $row_or_id ) : 
										( int($row_or_id) > 0 ? find( -table => $tablename, -where => { 'id' => $row_or_id } ) : ( undef ) ) );
			if( defined $row ) {
				$allowed = ( exists $row->{'owner'} && defined $U && $row->{'owner'} eq $U );
			}
		}
		if( ! $allowed && $authenticate_if_needed ) {
			authenticate( 'Restricted access, please login.' );
		}	
		return $allowed;
	}	
}

# these should be overwritten by the engine subclass
sub _connect { warn('Failed call: _connect() is not implemented.') }
sub _disconnect { warn('Failed call: _disconnect() is not implemented.') }
sub _tables { warn('Failed call: _tables() is not implemented.') }
sub _table_info { warn('Failed call: _table_info() is not implemented.') }
sub _find { warn('Failed call: _find() is not implemented.') }
sub _query { warn('Failed call: _query() is not implemented.') }
sub _alter_table { warn('Failed call: _alter_table() is not implemented.') }
sub _drop_tables { warn('Failed call: _drop_tables() is not implemented.') }
sub _create_column { warn('Failed call: _create_column() is not implemented.') }
sub _alter_column { warn('Failed call: _alter_column() is not implemented.') }
sub _drop_column { warn('Failed call: _drop_column() is not implemented.') }
sub _backup_db { warn('Failed call: _backup_db() is not implemented.') }
sub _load_db_backup { warn('Failed call: _load_db_backup() is not implemented.') }

########################## actual programmer api follows

sub connect
{
	my( $self ) = @_;
	return $self->_connect();
}

sub disconnect
{
	my( $self ) = @_;
	return $self->_connect();
}

sub tables
{
	my( $self, @args ) = @_;
	return $self->_tables( @args );
}

sub table_info # get table info, includes fields info
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

sub find
{
	my( $self, %options ) = @_;
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
	die "No tablename given" unless scalar @tablenames;
	delete $opts->{'table'};
	$opts->{'tables'} = [ @tablenames ];
	return $self->_find( %{$opts} );
}

sub first
{
	my( $self, @args ) = @_;
	my @rows = $self->find( @args, -limit => 1 );
	return ( scalar @rows ? $rows[0] : undef );
}

sub create
{
	my( $self, %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => undef,
			'row' => {},
			'accesscheck' => 1
		});
	return $self->_create( %{$opts} );
}

sub update
{
	my( $self, %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => '',
			'set' => {},
			'where' => {},
			'wherelike' => {},
			'accesscheck' => 1,
		});
	return $self->_update( %{$opts} );
}

sub remove
{
	my( $self, %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => '',
			'where' => {},
			'wherelike' => {},
			'accesscheck' => 1,
		});
	return $self->_remove( %{$opts} );
}

sub query
{
	my( $self, $sql, $ignore_errors ) = @_;
	$ignore_errors = 0 unless defined $ignore_errors;
	return $self->_query( $sql, $ignore_errors );
}

sub load
{
	my( $self, %options ) = @_;
	my $opts = _parse_params( \%options,
		{
			'table' => '',
			'data' => '',
		});
	
	my $records	= $self->_load_data($opts->{'data'});
	
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

sub init_table # create new table
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

sub alter_table # rename/change table
{
	my( $self, $tablename, $new_tablename, $fields ) = @_;
	return $self->_alter_table( $tablename, $new_tablename, $fields );
}

sub drop_tables # drop table(s)
{
	my( $self, @tablenames ) = @_;
	return $self->_drop_tables( @tablenames );
}

sub create_column # create field(s)
{
	my( $self, $tablename, $column ) = @_;
	return $self->_create_column( $tablename, $column );
}

sub alter_column # rename/change field
{
	my( $self, $tablename, $fieldname, $new_fieldname, $type, $new_type ) = @_;
	return $self->_alter_column( $tablename, $fieldname, $new_fieldname, $type, $new_type );
}

sub drop_column # drop field(s)
{
	my( $self, $tablename, @fieldnames ) = @_;
	return $self->_drop_column( $tablename, @fieldnames );
}

sub backup_db # backup db
{
	my( $self ) = @_;
	return $self->_backup_db();
}

sub load_db_backup # load db backup
{
	my( $self, $file_basename ) = @_;
	return $self->_load_db_backup( $file_basename );
}

1;
