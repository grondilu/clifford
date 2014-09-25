use Clifford;
use Test;

plan 4;

given 1 + e(0) + e(0)*e(1) - e(0)*e(1)*e(4) {
    ok .[0] == 1;
    ok .[1] == e(0);
    ok .[2] == e(0)*e(1);
    ok .[3] == -e(0)*e(1)*e(4);
}

# vim: ft=perl6
