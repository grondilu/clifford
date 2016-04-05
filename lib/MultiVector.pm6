unit role MultiVector does Numeric; 
method blades {...}

#| AT-KEY is used for grade projection
method AT-KEY(UInt $n) {...}
method grades { self.blades.classify({ [+] .key.polymod(2 xx *) }) }
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
