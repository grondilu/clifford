use Polynomial;

my ($x, $y, $z) = map { Polynomial.new($_) }, <x y z>;

use Test;
plan 13;

is $x**2, "x²";
is -$x, "-x";
is $x*$y, "x*y";
is $x*$y*$x, "x²*y";
is $y*$y*$x, "x*y²";
is $x*$y*$z, "x*y*z";
is ($x*$y*$z)**2, "x²*y²*z²";
is 1 + $x, "1 + x";
is 1 - $x, "1 - x";
is ($x + $y)**2, "2*x*y + x² + y²";
is ($x + $y)*($x - $y), "x² - y²";

is ($x + 2*$y).closure.(x => 1, y => 2), 5;
is ($x + 2*$y).closure.(x => 2, y => 1), 4;


# vim: ft=perl6
