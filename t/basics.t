use Test;
use MultiVector;

# &prefix:<+> narrows and is therefore needed to compare with Reals
#
plan 3;
is +e(0)**2, 1,  'square of a vector is usually 1';
is +(e(5)*e(3))**2, -1, 'the square of a bivector is -1';

@MultiVector::signature[0] = -1;
is +e(0)**2, -1, 'square of a vector is -1 when signature is negative';


# vim: ft=perl6
