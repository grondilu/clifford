use MultiVector;
use Test;

plan 4;

given 1 + e(0) + e(0)*e(1) - e(0)*e(1)*e(4) {
    is .[0], '1';
    is .[1], 'e0';
    is .[2], 'e(0)*e(1)';
    is .[3], '(-1)*e(0)*e(1)*e(4)';
}

# vim: ft=perl6
