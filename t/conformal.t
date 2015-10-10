use Clifford;
use Test;

plan 6;

constant no = (e(0) + e(4))/2;
constant ni = e(4) - e(0);
constant E = (ni*no - no*ni)/2;

ok no**2 == 0, 'o² = 0';
ok ni**2 == 0, '∞² = 0';

sub infix:<cdot>($a, $b) { ($a*$b + $b*$a)/2 }
ok no cdot ni == 1, 'o·∞ = 1';

ok E**2 == 1, 'E² = 1';

sub F($x) { no + $x - 1/2*$x**2*ni }

my $x = [+] rand.round(.01) xx 3 Z* map &e, 1..3;
ok F($x)**2 == 0, 'F(x)² = 0';
ok F($x) cdot ni == 1, 'F(x)·∞ = 1';

# vim: ft=perl6
