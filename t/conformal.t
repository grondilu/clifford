use Clifford;
use Test;

plan 4;

constant no = (e(0) + e(4))/2;
constant ni = e(4) - e(0);
constant E = (ni*no - no*ni)/2;

ok no**2 == 0, 'o² = 0';
ok ni**2 == 0, '∞² = 0';

ok ni*no + no*ni == 2, 'o·∞ = 1';

ok E**2 == 1, 'E² = 1';


# vim: ft=perl6
