#! /usr/bin/env perl

=encoding utf8

=head1 NAME

Dump Db - Dump database

=head1 SYNOPSIS

=head1 LICENSE

SPDX-License-Identifier: AGPL-3.0-or-later

=head1 COPYRIGHT

Copyright 2024 Mitsutoshi Nakano <ItSANgo@gmail.com>

=head1 DESCRIPTION

=cut

use v5.38.2;
use strict;
use warnings;
use utf8;
use lib '.';
use Getopt::Std;
use JSON::PP;
use DumpDb;

use constant HELP => <<_END_OF_HELP_;
Usage: $0 [-u user] [-p password] [-a attributes] dsn query [args]
Options:
    -u user         User name
    -p password     Password
    -a attributes   Connection attributes
Arguments:
    dsn             Data source
    query           select_query|'table_info'|'column_info'
    args            Arguments
Example:
    $0 -u 'user' -a 'RaiseError=1,PrintWarn=1' 'dbi:Pg:host=localhost' column_info 'schema=public,table=table_name'
For more details run:
    perldoc -F $0
_END_OF_HELP_

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my $VERSION = '0.1.0-SNAPSHOT';

sub HELP_MESSAGE { print HELP }
sub VERSION_MESSAGE { say $VERSION }

getopts('u:p:a:', \my %opts) or die HELP;

my $user = $opts{u} // '';
my $password = $opts{p};
my $attr = { split(/[ ,=]/, $opts{a} // '') };

my $dsn = shift @ARGV or die HELP;
my $query = shift @ARGV or die HELP;
my $args = { split(/[ ,=]/, shift @ARGV // '') };

my $dumpper = DumpDb->new;
$dumpper->connect($dsn, $user, $password, $attr);

my $sth;
if ($query eq 'table_info') { $sth = $dumpper->table_info($args) }
elsif ($query eq 'column_info') { $sth = $dumpper->column_info($args) }
else { $sth = $dumpper->select($query) }

unless ($sth) {
    die join(' ', $query, 'was failed,', $DBI::err, $DBI::state, $DBI::errstr);
}

my @NAMES = @{$sth->{NAME}};

my $table = $sth->fetchall_arrayref;
my $json = JSON::PP->new->utf8->pretty->allow_nonref;
say $json->encode([{ header => \@NAMES }, { body => $table }]);

__END__
