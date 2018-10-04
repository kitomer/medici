package MyApp::Model::Social::Group;

use strict;
use warnings;

sub new { bless {}, shift }

sub check {
  my ($self, $user, $pass) = @_;

  return 1;
}

1;
