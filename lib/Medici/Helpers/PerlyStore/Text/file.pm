package Medici::Helpers::PerlyStore::Text::file;
use base package Medici::Helpers::PerlyStore;

# the file is considered a "collection", each line is a "row" with "key" being the line number, e.g.
#	my $line_42 = $st->find( -key => 42 );

1;
