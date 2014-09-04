use MultiVector;
use Test;

plan 5;

ok e(Real) ~~ Blade, 'a scalar is a blade';
ok e((^10).pick) ~~ Blade, 'a vector of the orthonormal basis is a blade';

my $random = [+] (rand - .5)*e((^10).pick) xx 3; 
ok $random ~~ Blade, 'a random vector is a Blade';

nok 1 + $random ~~ Blade, '(1 + random vector) is NOT a blade';
nok (1 + $random)**2 ~~ Blade, '(1 + random vector)² is NOT a blade';



# vim: ft=perl6
