unit package Clifford::Basis;

subset Basis of Pair where { .key ~~ UInt && .value ~~ Real };

our sub format(UInt $key is copy) {
    join '*', gather {
	my $i = 0;
	while $key > 0 {
	    take "e$i" if $key +& 1;
	    take "ē$i" if $key +& 2;
	    $key +>= 2;
	    $i++;
	}
    }
}

our proto grade($) {*}
multi grade(Basis $basis) { grade($basis.key) }
multi grade(UInt $key is copy) {
    my int $c = 0;
    loop (; $key > 0; $key +>= 1) { $c++ if $key +& 1 }
    return $c;
}

# Flip Check when multiplying two blades
our sub signFlip(uint $a, uint $b, int $c = 0) returns Bool {
  return ($a +> 1 ) > 0 ?? 
  signFlip( $a +> 1 , $b, $c + grade( ( $a +> 1 ) +& $b ) ) !! 
  ?( $c +& 1 )
}   

# Geometric product
our sub product(Basis $a, Basis $b) returns Basis is export {
    state @signature = |(1, -1) xx *;
    ($a.key +^ $b.key) => 
    [*] $a.value, $b.value,
    (signFlip($a.key, $b.key) ?? -1 !! +1),
    |grep +*, (
	@signature Z*
	($a.key +& $b.key).base(2).comb.reverse
    )
}
