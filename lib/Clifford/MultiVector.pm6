unit role Clifford::MultiVector does Numeric;
use Clifford::Basis;

method blades returns MixHash {...}
method pairs { self.blades.pairs }
method keys  { self.blades.keys  }

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

method reals { self.blades.values }
method narrow returns Numeric {
    return 0 if self.blades.pairs == 0;
    for self.blades.pairs {
	return self if .key > 0;
    }
    return self.blades{0}.narrow;
}
multi method gist {
    if    self.blades.pairs == 0 { return '0' }
    elsif self.blades.pairs == 1 {
	given self.blades.pairs.pick {
	    return .key == 0 ??
	    ~.value !!
	    ("{.value}*{Clifford::Basis::format(.key)}").subst(/<|w>1\*/,'');
	}
    } else {
	return 
	join(
	    ' + ', do for sort *.key, self.blades.pairs {
		.key == 0 ?? .value !! 
		("{.value}*{Clifford::Basis::format(.key)}").subst(/<|w>1\*/,'');
	    }
	).subst('+ -','- ', :g);
    }
}
method AT-POS(UInt $n) {
    ::?CLASS.new:
    blades => self.blades.grep({ Clifford::Basis::grade($_) == $n }).MixHash
}
method max-grade { self.blades.map(&Clifford::Basis::grade).max }

