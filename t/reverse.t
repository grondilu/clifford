use MultiVector;
use Test;

plan 6;
is +e(Real).reverse, '1', 'reversion does not change scalars';
is (e(0)).reverse.gist, 'e0', 'reversion does not change vectors';
is (e(0)*e(1)).reverse.gist, '(-1)*e[0,1]', 'bivector reversion';
is (e(0)*e(1)*e(2)).reverse.gist, '(-1)*e[0,1,2]', 'trivector reversion';
is (e(0)*e(1)*e(2)*e(3)).reverse.gist, 'e[0,1,2,3]', 'quadrivector reversion';

is (e(0)†).gist, 'e0', 'use of dagger';

# vim: ft=perl6
