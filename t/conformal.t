use Clifford;
use Test;

plan 5;

constant no = (e(0) + e(4))/2;
constant ni = e(4) - e(0);
constant E = (ni*no - no*ni)/2;

ok no**2 == 0, 'o² = 0';
ok ni**2 == 0, '∞² = 0';

ok ni*no + no*ni == 2, 'o·∞ = 1';

ok E**2 == 1, 'E² = 1';

sub F($x) { no + $x - 1/2*$x**2*ni }

ok F([+] rand.round(.01) xx 3 Z* map &e, 1..3)**2 == 0, 'F(x)² = 0';

# vim: ft=perl6
