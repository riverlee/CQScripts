use strict;
use warnings;
use File::Basename;

use lib dirname($0);#."/../";
use cmdrunner;

my $runner = cmdrunner->new();
$runner->prefix("prefix");
$runner->submitter("pbs");
$runner->run("cat #<A",["in.txt"],[]);

