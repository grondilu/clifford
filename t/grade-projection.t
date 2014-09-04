use MultiVector;
use Test;

plan 4;

given 1 + e(0) + e(0)*e(1) - e(0)*e(1)*e(4) {
    is +.[0], '1';
    is .[1].gist, 'e0';
    is .[2].gist, 'e[0,1]';
    is .[3].gist, '(-1)*e[0,1,4]';
}

# vim: ft=perl6
