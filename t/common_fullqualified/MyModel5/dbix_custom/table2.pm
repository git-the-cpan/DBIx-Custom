package MyModel5::dbix_custom::table2;

use strict;
use warnings;

use base 'MyModel5';

__PACKAGE__->attr(table => 'dbix_custom.table2');

__PACKAGE__->attr('primary_key' => sub { ['key1', 'key2'] });

1;
