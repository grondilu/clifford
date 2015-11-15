unit role MultiVector does Numeric; 
method blades {...}

#| AT-KEY is used for grade projection
method AT-KEY(UInt $n) {...}
method grades { self.blades.classify({ [+] .key.polymod(2 xx *) }) }
multi method gist {
    my sub blade-gist($blade) {
	join(
	    '*',
	    $blade.value,
	    map { "e({$_ - 1})" },
	    grep +*,
	    ($blade.key.base(2).comb.reverse Z* 1 .. *)
	).subst(/<|w>1\*/, '')
    }
    if    self.blades == 0 { return '0' }
    elsif self.blades == 1 {
	given self.blades.pick {
	    if .key == 0 {
		return .value.gist;
	    } else {
		return blade-gist($_);
	    }
	}
    } else {
	return 
	join(
	    ' + ', do for sort *.key, self.blades {
		.key == 0 ?? .value.gist !! blade-gist($_);
	    }
	).subst('+ -','- ', :g);
    }
}
method Real {
    if any(self.blades.keys) > 0 {
	fail X::Numeric::Real.new:
	target => Real,
	source => self,
	reason => 'not purely scalar'
	;
    }
    return self.blades{0} // 0;
}

method reals { self.blades».value }
method narrow returns Numeric {
    for self.blades {
	return self if .key > 0 && .value !== 0;
    }
    return (self.blades.hash{0} // 0).narrow;
}
