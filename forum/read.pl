#!/usr/bin/perl
=pod

=head1 read.pl - Handle file based discussion forum

The purpose of read.pl is the commandline based management of discussion messages
that are plain file based (to be exact the file format is RST, or “reStructured text”).
The messages are stored in a directory structure like this (in the current directory):

  <year>/<month>/<day>/<hour><minute>_<author>.rst
  <year>/<month>/<day>/<hour><minute>_<author>.zip

The .rst file is the message itself and the (unencrypted) .zip file is the container
of the message attachments.

Usually this whole directory is versioned in a source code repository to allow for
easy sharing and history logging.

=head2 Usage

  read.pl new
    Create a new message in editor.

	read.pl thread I<message-filename>
		e.g.: read.pl thread 2018/11/26/0513_torvalds
		Show the thread of messages starting with the given message.

	read.pl threads I<message-filename-prefix>
	  e.g.: read.pl threads 2018/11/26/05
		Show the list of threads that contains all messages matching the given message prefix.

	read.pl reply I<message-filename>
	  e.g.: read.pl reply 2018/11/26/0513_torvalds
		Opens the editor with the given messages quoted and show its potential filename.

	read.pl attach I<message-filename> I<file(s)-to-attach>
	  e.g.: read.pl attach 2018/11/26/0513_torvalds myfile.png
		Attach the given files to the attachment container of the given message.

	read.pl detach I<message-filename> I<file(s)-to-detach>
	  e.g.: read.pl detach 2018/11/26/0513_torvalds myfile.png
		Detach the given files from the attachment container of the given message.

=head2 Environment variables

=over 1

=item READPL_AUTHORNAME

This is the default author names of new messages.

=item READPL_EDITOR

This is the command used to open a message for editing.

=item READPL_VIEWER

This is the command used to open a message for viewing it.

=back

=cut

use strict;
use warnings;

my $rtfm = “Invalid call. Get usage info with $ perldoc read.pl\n”;

my( $cmd, @args ) = @ARGV;
die $rtfm	unless defined $cmd;
die $rtfm if ! scalar grep { $_ eq $cmd } qw(new thread threads reply attach detach);
eval('cmd_'.$cmd.'( @args )');
die “Internal error. You can cry now.\n” if $@;

sub cmd_new
{
  # Create a new message in editor.
}

sub cmd_thread
{
  # I<message-filename>
	#	e.g.: read.pl thread 2018/11/26/0513_torvalds
	#	Show the thread of messages starting with the given message.
}

sub cmd_threads
{
  # I<message-filename-prefix>
	# e.g.: read.pl threads 2018/11/26/05
	# Show the list of threads that contains all messages matching the given message prefix.
}

sub cmd_reply
{
  # I<message-filename>
	# e.g.: read.pl reply 2018/11/26/0513_torvalds
	# Opens the editor with the given messages quoted and show its potential filename.
}

sub cmd_attach
{
  # I<message-filename> I<file(s)-to-attach>
	# e.g.: read.pl attach 2018/11/26/0513_torvalds myfile.png
	# Attach the given files to the attachment container of the given message.
}

sub cmd_detach
{
  # I<message-filename> I<file(s)-to-detach>
}

