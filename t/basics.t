use Test;
use Clifford;

plan *;
is e[0]**2, 1,  'square of a vector is usually 1';
is e[(^10).pick, (10..20).pick]**2, -1, 'the square of a bivector is -1';

@Clifford::signature[0] = -1;
is e[0]**2, -1, 'square of a vector is -1 when signature is negative';


# vim: ft=perl6
