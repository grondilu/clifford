use Clifford;
use Test;

plan 4;

given 1 + e[0] + e[0, 1] - e[0, 1, 4] {
    is .[0], '1';
    is .[1], 'e[0]';
    is .[2], 'e[0,1]';
    is .[3], '(-1)*e[0,1,4]';
}

# vim: ft=perl6
