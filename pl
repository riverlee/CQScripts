#!/usr/bin/env perl
my @str=<DATA>;
my $str=join "",@str;
my $t=scalar(localtime);
$str=~s/replacetime/$t/g;

print $str;

__DATA__
#!/usr/bin/env perl
###################################
# Author: Jiang (River) Li
# Email:  riverlee2008@gmail.com
# Date:   replacetime
###################################
use strict;
use warnings;

