use Clifford;
use Test;

plan 4;

sub random {
    use MultiVector;
    [+] map {
	class :: does MultiVector {
	    has Real %.blades{UInt};
	    method AT-KEY($) {};
	}.new: :blades(my Real %{UInt} = $_ => rand.round(.01));
    }, (^32).pick(5);
}

my ($a, $b, $c) = random() xx 3;

ok ($a*$b)*$c == $a*($b*$c), 'associativity';
ok $a*($b + $c) == $a*$b + $a*$c, 'left distributivity';
ok ($a + $b)*$c == $a*$c + $b*$c, 'right distributivity';

my @coeff = (.5 - rand) xx 4;
my $v = [+] @coeff Z* map &e, ^4;
ok ($v**2).narrow ~~ Real, 'contraction';

# vim: ft=perl6
