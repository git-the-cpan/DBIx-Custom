use Test::More;
use strict;
use warnings;
use DBI;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required';
    eval { DBD::SQLite->VERSION >= 1 }
        or plan skip_all => 'DBD::SQLite >= 1.00 required';

    plan 'no_plan';
    use_ok('DBIx::Custom::Result');
}

sub test { print "# $_[0]\n" }

sub query {
    my ($dbh, $sql) = @_;
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    return DBIx::Custom::Result->new(sth => $sth);
}

my $dbh;
my $sql;
my $sth;
my @row;
my $row;
my @rows;
my $rows;
my $result;
my $filter;
my @error;
my $error;

$dbh = DBI->connect('dbi:SQLite:dbname=:memory:', undef, undef, {PrintError => 0, RaiseError => 1});
$dbh->do("create table table1 (key1 char(255), key2 char(255));");
$dbh->do("insert into table1 (key1, key2) values ('1', '2');");
$dbh->do("insert into table1 (key1, key2) values ('3', '4');");

$sql = "select key1, key2 from table1";

test 'fetch';
$result = query($dbh, $sql);
@rows = ();
while (my $row = $result->fetch) {
    push @rows, [@$row];
}
is_deeply(\@rows, [[1, 2], [3, 4]]);


test 'fetch_hash';
$result = query($dbh, $sql);
@rows = ();
while (my $row = $result->fetch_hash) {
    push @rows, {%$row};
}
is_deeply(\@rows, [{key1 => 1, key2 => 2}, {key1 => 3, key2 => 4}]);


test 'fetch_first';
$result = query($dbh, $sql);
$row = $result->fetch_first;
is_deeply($row, [1, 2], "row");
$row = $result->fetch;
ok(!$row, "finished");


test 'fetch_hash_first';
$result = query($dbh, $sql);
$row = $result->fetch_hash_first;
is_deeply($row, {key1 => 1, key2 => 2}, "row");
$row = $result->fetch_hash;
ok(!$row, "finished");

$result = query($dbh, 'create table table2 (key1, key2);');
$result = query($dbh, 'select * from table2');
$row = $result->fetch_hash_first;
ok(!$row, "no row fetch");


test 'fetch_multi';
$dbh->do("insert into table1 (key1, key2) values ('5', '6');");
$dbh->do("insert into table1 (key1, key2) values ('7', '8');");
$dbh->do("insert into table1 (key1, key2) values ('9', '10');");
$result = query($dbh, $sql);
$rows = $result->fetch_multi(2);
is_deeply($rows, [[1, 2],
                  [3, 4]], "fetch_multi first");
$rows = $result->fetch_multi(2);
is_deeply($rows, [[5, 6],
                  [7, 8]], "fetch_multi secound");
$rows = $result->fetch_multi(2);
is_deeply($rows, [[9, 10]], "fetch_multi third");
$rows = $result->fetch_multi(2);
ok(!$rows);


test 'fetch_multi error';
$result = query($dbh, $sql);
eval {$result->fetch_multi};
like($@, qr/Row count must be specified/, "Not specified row count");


test 'fetch_hash_multi';
$result = query($dbh, $sql);
$rows = $result->fetch_hash_multi(2);
is_deeply($rows, [{key1 => 1, key2 => 2},
                  {key1 => 3, key2 => 4}], "fetch_multi first");
$rows = $result->fetch_hash_multi(2);
is_deeply($rows, [{key1 => 5, key2 => 6},
                  {key1 => 7, key2 => 8}], "fetch_multi secound");
$rows = $result->fetch_hash_multi(2);
is_deeply($rows, [{key1 => 9, key2 => 10}], "fetch_multi third");
$rows = $result->fetch_hash_multi(2);
ok(!$rows);


test 'fetch_multi error';
$result = query($dbh, $sql);
eval {$result->fetch_hash_multi};
like($@, qr/Row count must be specified/, "Not specified row count");

$dbh->do('delete from table1');
$dbh->do("insert into table1 (key1, key2) values ('1', '2');");
$dbh->do("insert into table1 (key1, key2) values ('3', '4');");

test 'fetch_all';
$result = query($dbh, $sql);
$rows = $result->fetch_all;
is_deeply($rows, [[1, 2], [3, 4]]);

test 'fetch_hash_all';
$result = query($dbh, $sql);
$rows = $result->fetch_hash_all;
is_deeply($rows, [{key1 => 1, key2 => 2}, {key1 => 3, key2 => 4}]);


test 'fetch filter';
$result = query($dbh, $sql);
$result->filters({three_times => sub { $_[0] * 3}});
$result->filter({key1 => 'three_times'});

$rows = $result->fetch_all;
is_deeply($rows, [[3, 2], [9, 4]], "array");

$result = query($dbh, $sql);
$result->filters({three_times => sub { $_[0] * 3}});
$result->filter({key1 => 'three_times'});
$rows = $result->fetch_hash_all;
is_deeply($rows, [{key1 => 3, key2 => 2}, {key1 => 9, key2 => 4}], "hash");

