use Clifford;
use Test;

plan 10;

{
    my $a = Clifford::Basis.new: :blade(2), :weight(3);
    my $b = Clifford::Basis.new: :blade(1), :weight(2);

    my $c = $a * $b;

    is $c.blade, 3;
    is $c.weight, -6;
}

{
    my $a = Clifford::Basis.new: :blade(0), :weight(3);
    my $b = Clifford::Basis.new: :blade(1), :weight(2);

    my $c = $a * $b;

    is $c.blade, 1;
    is $c.weight, 6;
}

{
    my $a = Clifford::Basis.new: :blade(5), :weight(3);
    my $b = Clifford::Basis.new: :blade(1), :weight(2);

    my $c = $a * $b;

    is $c.blade, 4;
    is $c.weight, -6;
}

{
    my ($i, $j, $k, $l) = (^10).pick(*);
    my $a = Clifford::Basis.new: :blade($i), :weight(3);
    my $b = Clifford::Basis.new: :blade($j), :weight(2);

    my $c = Clifford::Basis.new: :blade($k), :weight(2);
    my $d = Clifford::Basis.new: :blade($l), :weight(5);

    my $e = $a + $b;
    my $f = $c + $d;
    my $g = $e + $f;
    is $e.blades.elems, 2;
    is $g.blades.elems, 4;
}

{
    my $i = (^10).pick;
    my @w = (5*(rand - .5)) xx 2;
    my $a = Clifford::Basis.new: :blade($i), :weight(@w[0]);
    my $b = Clifford::Basis.new: :blade($i), :weight(@w[1]);

    my $c = $a + $b;
    is $c.blades.elems, 1;
    is $c.blades[0].weight, [+] @w;
}


=finish
for ^32 -> $i {
    my $a = Clifford::Basis.new: :blade($i), :weight(1);
    for ^32 -> $j {
	my $b = Clifford::Basis.new: :blade($j), :weight(1);
	my $c = $a * $b;
	say $c;
    }
}
