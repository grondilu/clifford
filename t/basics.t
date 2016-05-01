use Test;
use Clifford;

plan 13;
ok @e[0]**2 == 1, 'square of a unit euclidean vector is 1';
ok (@e[0]*@e[1])**2 == -1, 'the square of a unit euclidean bivector is -1';

ok @ē[0]**2 == -1, 'square of a unit anti-euclidean vector is -1';

ok .5 * @e[0] == @e[0] / 2, 'scalar multiplication and division look consistent';
ok 1 + (1 + @e[0]) == 2 + @e[0];
ok 2 * (1 + @e[0]) == 2 + 2*@e[0];
ok 1 + @e[0] - @e[0] == 1;
ok 1 + @e[0] - 1 - @e[0] == 0;
ok -1*(1 + @e[0]) + 1 + @e[0] == 0;

ok (1 + @e[0])**2 == 2 + 2*@e[0];

ok @e[0] · @e[1] == 0, 'inner product of two orthogonal vectors';
ok @e[0] · @e[0] == 1, 'inner product of a vector with itself';
ok (@e[0] + @e[1]) · (@e[0] - @e[1]) == 0, 'non-trivial inner product';

# vim: ft=perl6
