use Test;
use MultiVector;

# &prefix:<+> narrows and is therefore needed to compare with Reals
#
plan 11;
is +e(0)**2, 1,  'square of a vector is usually 1';
is +(e(5)*e(3))**2, -1, 'the square of a bivector is -1';

@MultiVector::signature[0] = -1;
is +e(0)**2, -1, 'square of a vector is -1 when signature is negative';

is (1 + e(0)).gist, '1 + e0';
is (-1 + e(0)).gist, '-1 + e0';
is (5 + e(0)).gist, '5 + e0';
is (1 + (1 + e(0))).gist, '2 + e0';
is (2 * (1 + e(0))).gist, '2 + 2*e0';
is (1 + e(0) - e(0)).clean.gist, '1';
is (1 + e(0) - 1 - e(0)).clean.gist, '0';
is (-1*(1 + e(0)) + 1 + e(0)).clean.gist, '0';

# vim: ft=perl6
