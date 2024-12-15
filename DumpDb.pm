package DumpDb;

=encoding utf8

=head1 NAME

Dump Db - Dump database

=head1 SYNOPSIS

    use DumpDb;

    my $dummper = DumpDb->new;
    $dummper->connect($dsn, $user, $password, \%attrs);
    ...

=head1 LICENSE

SPDX-License-Identifier: AGPL-3.0-or-later

=head1 COPYRIGHT

Copyright 2024 Mitsutoshi Nakano <ItSANgo@gmail.com>

=head1 DESCRIPTION

=cut

use v5.38.2;
use strict;
use warnings;
use feature 'signatures';
use utf8;
use Carp;
use DBI;

################################################################

=head1 CONSTRUCTOR

=head2 $dumpper = DumpDb->new

=cut

sub new($class, $self = {}) { bless $self, $class }

################################################################

=head1 COMMAND METHODS

=head2 $dumpper->connect($dsn, $user, $password, \%attr)

=cut

sub connect(
    $self, $dsn, $user = undef, $password = undef, $attr = { RaiseError => 1 }
) {
    $self->{dbh} = DBI->connect($dsn, $user, $password, $attr)
    or confess join(
        ' ', "Couldn't connect", $dsn, 'as', $user,
        $DBI::err, $DBI::state, $DBI::errstr
    );
    $self->{_connect_arguments} = {
        dsn => $dsn, user => $user, password => $password, attr => $attr
    };
    $self;
}

################################

=head2 $dumpper->disconnect

=cut

sub disconnect($self) {
    unless (defined($self->{dbh})) { return $self }
    $self->{dbh}->disconnect;
    $self->{_connect_arguments} = $self->{dbh} = undef;
    $self;
}

################################################################

=head1 ACCESSOR METHODS

=head2 $dbh = $dumpper->get_dbh

=cut

sub get_dbh($self) { $self->{dbh} }

################################

=head2 @arguments = $dumpper->get_connect_arguments

=head3 Return value

The following list: ($dsn, $user, $password, $attr)

=cut

sub get_connect_arguments($self) {
    my $c = $self->{_connect_arguments} or return undef;
    return ($c->{dsn}, $c->{user}, $c->{password}, $c->{attr});
}

################################

=head2 $sth = $dumpper->select($statement)

=cut

sub select($self, $statement) {
    my $sth;
    $sth = $self->{dbh}->prepare($statement) and $sth->execute and $sth;
}

################################

=head2 $sth = $dumpper->table_info(\%arguments)

=head3 Arguments

=over 4

=item \%arguments

Hashref has the following keys:

=over 4

=item catalog

=item schema

=item table

=item type

=item attr

=back

=back

=cut

sub table_info($self, $arguments = {}) {
    my $a = $arguments;
    $self->{dbh}->table_info(
        $a->{catalog} // '%', $a->{schema} // '%', $a->{table} // '%',
        $a->{type} // '%', $a->{attr}
    );
}

################################

=head2 $sth = $dumpper->column_info(\%patterns)

=head3 Arguments

=over 4

=item \%patterns

Hashref has the following keys:

=over 4

=item catalog

=item schema

=item table

=item column

=back

=back

=cut

sub column_info($self, $patterns = {}) {
    my $p = $patterns;
    $self->{dbh}->column_info(
        $p->{catalog} // '%', $p->{schema} // '%', $p->{table} // '%',
        $p->{column} // '%'
    );
}

################################################################

=head1 DESTRUCTOR

=cut

sub DESTROY($self) { $self->disconnect }

1;
__END__
