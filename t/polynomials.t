use Algebra;

my ($x, $y, $z) = v:x, v:y, v:z;

use Test;
plan 10;

is $x**2, "x²";
is $x*$y, "x*y";
is $x*$y*$x, "x²*y";
is $y*$y*$x, "x*y²";
is $x*$y*$z, "x*y*z";
is ($x*$y*$z)**2, "x²*y²*z²";
is 1 + $x, "1 + x";
is 1 - $x, "1 - x";
is ($x + $y)**2, "2*x*y + x² + y²";
is ($x + $y)*($x - $y), "x² - y²";

