use Test;
use Clifford;

my $i = e(0)*e(1);
my $j = e(1)*e(2);
my $k = e(0)*e(2);

plan 4;

ok $i**2 == -1, 'i² = -1';
ok $j**2 == -1, 'j² = -1';
ok $k**2 == -1, 'k² = -1';
ok $i*$j*$k == -1, 'i*j*k = -1';

# vim: ft=perl6
