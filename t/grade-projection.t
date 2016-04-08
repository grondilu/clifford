use Clifford;
use Test;

plan 5;

my $M = 1 + @e[1] + @e[2] + @e[0]*@e[3];

ok $M[0] == 1          , '〈M〉[0] = 1';
ok $M[1] == @e[1] + @e[2], '〈M〉[1] = 1';
ok $M[2] == @e[0]*@e[3]  , '〈M〉[2] = 1';
ok $M[3] == 0          , '〈M〉[3] = 1';      

is $M.max-grade, 2, 'maximum grade is correct';
# vim: ft=perl6
