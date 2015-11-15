use Clifford;
use Test;

plan 1;

my constant i = e(1)*e(2);
my constant j = e(2)*e(3);
my constant k = e(1)*e(3);

ok i**2 == j**2 == k**2 == i*j*k == -1;

# vim: ft=perl6
