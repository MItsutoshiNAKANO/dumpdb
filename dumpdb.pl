#! /usr/bin/env perl

=encoding utf8

=head1 NAME

Dump Db - Dump database

=head1 SYNOPSIS

=head1 LICENSE

SPDX-License-Identifier: AGPL-3.0-or-later

=head1 COPYRIGHT

Copyright 2025 Mitsutoshi Nakano <ItSANgo@gmail.com>

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
Usage: $0 [options] query [args]
Options:
    -f file         Configuration file (default: ~/.dumpdb.rc.json)
    -d dsn          Data source
    -u user         User name
    -p password     Password
    -a attributes   Connection attributes
Arguments:
    query           select_query|'table_info'|'column_info'
    args            Arguments
Example:
    $0 -d 'dbi:Pg:dbname=postgres' -u 'user' -a 'RaiseError=1,PrintWarn=1' column_info 'schema=public,table=table_name'
For more details run:
    perldoc -F $0
_END_OF_HELP_

$Getopt::Std::STANDARD_HELP_VERSION = 1;
my $VERSION = '0.1.0-SNAPSHOT';

my $default_rc = {
    defaults => {
        connect => ['dbi:Pg:dbname=postgres', "postgres", "postgres", {
            RaiseError => 1, PrintError => 1
        }]
    }
};

sub HELP_MESSAGE { print HELP }
sub VERSION_MESSAGE { say $VERSION }

getopts('f:d:u:p:a:', \my %opts) or die HELP;
my $rc_file = $opts{f} // $ENV{HOME} . '/.dumpdb.rc.json';

my $json = JSON::PP->new->utf8->pretty->allow_nonref;
my $rc_string = do { local $/; my $fh; open $fh, '<', $rc_file and <$fh> };
my $config;
if ($rc_string) { $config = $json->decode($rc_string) }
elsif ($opts{f}) { die "failed to read $rc_file: $!" }
else { $config = $default_rc }

my $dsn = $opts{d} // $config->{defaults}->{connect}->[0];
my $user = $opts{u} // $config->{defaults}->{connect}->[1];
my $password = $opts{p} // $config->{defaults}->{connect}->[2];
my $attr = {
    split(/[ ,=]/, $opts{a} // '')
} || $config->{defaults}->{connect}->[3];

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
say $json->encode([{ header => \@NAMES }, { body => $table }]);

__END__
