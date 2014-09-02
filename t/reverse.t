use Clifford;
use Test;

plan 6;
is e[].reverse, '1', 'reversion does not change scalars';
is (e[0]).reverse, 'e[0]', 'reversion does not change vectors';
is (e[0, 1]).reverse, '(-1)*e[0,1]', 'bivector reversion';
is (e[0, 1, 2]).reverse, '(-1)*e[0,1,2]', 'trivector reversion';
is (e[0, 1, 2, 3]).reverse, 'e[0,1,2,3]', 'quadrivector reversion';

is e[0]†, 'e[0]', 'use of dagger';

# vim: ft=perl6
