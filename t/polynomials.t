use Test;
use lib <lib>;
use Polynomials;

isa-ok +:x, Polynomial, "instantiation from Pair literal";

is-deeply (:x+pi), pi+:x, "π+x == x+π";

is-deeply (:a + :b)², :a² + 2*:a*:b + :b², "(a+b)² = a²+2ab+b²";
is-deeply (:a - :b)*(:a + :b), :a² - :b², "(a-b)(a+b) = a²-b²";

done-testing;

# vi: ft=raku
