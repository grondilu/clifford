use Test;
use MultiVector;

# &prefix:<+> narrows and is therefore needed to compare with Reals
#
plan 15;
is e(0)**2, 1,  'square of a vector is usually 1';
is (e(5)*e(3))**2, -1, 'the square of a bivector is -1';

{
    @MultiVector::signature[0] = -1;
    is +e(0)**2, -1, 'square of a vector is -1 when signature is negative';
    @MultiVector::signature[0] = 1;
}

is 1 + e(0), '1 + e0';
is -1 + e(0), '-1 + e0';
is 5 + e(0), '5 + e0';
is 1 + (1 + e(0)), '2 + e0';
is 2 * (1 + e(0)), '2 + 2*e0';
is (1 + e(0) - e(0)).clean, '1';
is (1 + e(0) - 1 - e(0)).clean, '0';
is (-1*(1 + e(0)) + 1 + e(0)).clean, '0';

is (1 + e(0))**2, '2 + 2*e0';

is e(0) cdot e(1), 0, 'inner product of two orthogonal vectors';
is e(0) cdot e(0), 1, 'inner product of a vector with itself';
is (e(0) + e(1)) cdot (e(0) - e(1)), 0, 'non-trivial inner product';

# vim: ft=perl6
