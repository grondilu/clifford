use Clifford;
use Test;

constant E = (ni*no - no*ni)/2;

plan 8;
ok no**2 == 0, 'o² = 0';
ok ni**2 == 0, '∞² = 0';

ok no·ni == -1, 'o·∞ = -1';

ok E**2 == 1, 'E² = 1';

ok no*E == -E*no == -no, 'oE = -Eo = -o';
ok E*ni == -ni*E == -ni, 'E∞ = -∞E = -∞';

sub F($x) { no + $x + 1/2*$x**2*ni }

my $x = [+] rand.round(.01) xx 3 Z* @e[1..3];
ok F($x)**2 == 0, 'F(x)² = 0';
ok F($x)·ni == -1, 'F(x)·∞ = 1';

# vim: ft=perl6
