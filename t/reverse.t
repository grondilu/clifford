use Clifford;
use Test;

plan 6;
ok e().reverse == 1, 'reversion does not change scalars';
ok e(0).reverse == e(0), 'reversion does not change vectors';
ok (e(0)*e(1)).reverse == -e(0)*e(1), 'bivector reversion';
ok (e(0)*e(1)*e(2)).reverse == -e(0)*e(1)*e(2), 'trivector reversion';
ok (e(0)*e(1)*e(2)*e(3)).reverse == e(0)*e(1)*e(2)*e(3), 'quadrivector reversion';

ok e(0)† == e(0), 'use of dagger';

# vim: ft=perl6
