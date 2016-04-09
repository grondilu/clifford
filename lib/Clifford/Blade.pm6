unit class Clifford::Blade;

has UInt $.index handles <WHICH> = 0;
has Int  $.sign = +1;

our sub grade(UInt $i) { (state @)[$i] //= [+] $i.polymod(2 xx *) }
method grade { grade($!index) }
method abs { ::?CLASS.new: :$!index }

method gist {
    join '*',
    gather {
	my $index = $!index;
	my $i = 0;
	while $index > 0 {
	    take "e$i" if $index +& 1;
	    take "ē$i" if $index +& 2;
	    $index +>= 2;
	    $i++;
	}
    }
}

my sub sign(UInt:D $i is copy, UInt:D $j) {
    my $n = 0;
    repeat {
	$i +>= 1;
	$n += grade($i +& $j);
    } until $i == 0;
    return $n +& 1 ?? -1 !! +1;
}
multi infix:<*>(::?CLASS $a, ::?CLASS $b) returns ::?CLASS is export {
    my ($i, $j) = ($a, $b)».index;
    my Int $sign = [*] $a.sign, $b.sign, sign($i, $j);
    my $t = $i +& $j;
    my $k = 0;
    while $t !== 0 {
	if $t +& 1 && $k % 2 { $sign*=-1 }
	$t +>= 1;
	$k++;
    }
    return ::?CLASS.new: :index($i +^ $j), :$sign;
}
