module Clifford;

# metric signature.  Euclidean by default.
our @signature = 1 xx *;

class BasisVector {
    has Int @.index;
    multi method new(Int @index where { none(@_) < 0 and [<] @_ }) {
	self.new: :@index
    }
    method grade { +@!index }
    method gist { @!index ?? <e[ ]>.join: @!index.join: "," !! 1 }
    method WHICH { join '|', 'BasisVector', @.index }
}
sub circumfix:<e[ ]>(*@i) is export { BasisVector.new: my Int @ = @i }

class MultiVector {
    has %.h{BasisVector} handles <pairs>;
    multi method new(%h where %h.elems == 0) { 0 }
    multi method new(%h where {
	[and] %h.elems > 0,
	map -> $_ { .key ~~ BasisVector and .value ~~ Real }, %h.pairs
    }) {
	self.new: :h(my %_h{BasisVector} = %h);
    }
    multi method new(BasisVector $a) {
	self.new: my %_h{BasisVector} = $a => 1;
    }
    method at_pos(Int $n where * >= 0) {
	my %h{BasisVector};
	for self.pairs {
	    %h{.key} = .value if .key.grade == $n;
	}
	%h ?? self.new: :%h !! 0;
    }
    method gist {
	return '0' unless self.pairs;
	join " + ",
	map {
	    .key.grade ?? (
		.value < 0  ?? "({.value})*" !!
		.value == 1 ?? '' !!
		"{.value}*"
	    ) ~ .key.gist
	    !! .value
	}, self.pairs
    }
}

multi prefix:<+>(MultiVector $a) {
    if $a.pairs == 0 { return 0 }
    elsif $a.pairs == 1 {
	my $p = $a.pairs.pick;
	return $p.value if $p.key.grade == 0;
    }
    return $a
}
multi infix:<+>(MultiVector $a, BasisVector $b) is export { $a + MultiVector.new($b) }
multi infix:<+>(BasisVector $a, MultiVector $b) is export { MultiVector.new($a) + $b }
multi infix:<+>(MultiVector $a) is export { $a }
multi infix:<+>(MultiVector $a, MultiVector $b) is export {
    my %h{BasisVector};
    for $a.pairs, $b.pairs {
	%h{.key} += .value;
	%h{.key} :delete if %h{.key} == 0;
    }
    MultiVector.new: %h;
}
multi infix:<->(MultiVector $a, MultiVector $b) is export {
    my %h{BasisVector};
    %h{.key} += .value for $a.pairs;
    for $b.pairs {
	%h{.key} -= .value;
	%h{.key} :delete if %h{.key} == 0;
    }
    MultiVector.new: %h;
}

multi infix:<+>(BasisVector $a, BasisVector $b) is export {
    my %a{BasisVector};
    my %b{BasisVector};
    %a{$a} = 1; %b{$b} = 1;
    MultiVector.new(%a) + MultiVector.new(%b);
}

multi infix:<->(BasisVector $a, BasisVector $b) is export {
    my %a{BasisVector};
    my %b{BasisVector};
    %a{$a} = 1; %b{$b} = 1;
    MultiVector.new(%a) - MultiVector.new(%b);
}

multi infix:<+>(Real $a, BasisVector $b) is export {
    MultiVector.new(my %h{BasisVector} = e[] => $a) + $b
}
multi infix:<+>(Real $a, MultiVector $b) is export {
    my %h{BasisVector};
    %h{e[]} += $a;
    for $b.pairs {
	%h{.key} += .value;
	%h{.key} :delete if %h{.key} == 0;
    }
    MultiVector.new: :%h;
}
multi infix:<+>(MultiVector $b, Real $a) is export { $a + $b }

multi infix:<*>(BasisVector $a, BasisVector $b) is export {
    my @ab = $a.index, $b.index;
    my $end = @ab.end;
    my $sign = 1;
    for reverse ^$a.index -> $i {
	for $i ..^ $end {
	    if @ab[$_] == @ab[$_ + 1] {
		$sign *= @signature[@ab[$_]];
		@ab.splice($_, 2);
		$end = $_;
		last;
	    } elsif @ab[$_] > @ab[$_ + 1] {
		@ab[$_, $_ + 1] = @ab[$_ + 1, $_];
		$sign *= -1;
	    }
	}
    }
    if @ab {
	my %h{BasisVector};
	%h{e[ @ab ]} = $sign;
	return MultiVector.new: %h;
    } else { return $sign }
}

multi infix:<*>(0, MultiVector $) is export { 0 }
multi infix:<*>(MultiVector $, 0) is export { 0 }
multi infix:<*>(Real $x, MultiVector $a) is export {
    my %h{BasisVector};
    %h{.key} = .value * $x for $a.pairs;
    MultiVector.new: %h;
}
multi infix:<*>(MultiVector $a, Real $x) is export { $x * $a }
multi infix:<*>(Real $x, BasisVector $a) is export {
    MultiVector.new: my %_h{BasisVector} = $a => $x
}
multi infix:<*>(BasisVector $a, Real $x) is export { $x * $a }
multi infix:<*>(BasisVector $a, MultiVector $b) is export {
    my %h{BasisVector};
    for $b.pairs {
	my $prod = .value * ($a * .key);
	if $prod ~~ Real {
	    %h{e[]} += $prod;
	    %h{e[]} :delete if %h{e[]} == 0;
	} elsif $prod ~~ MultiVector {
	    die "unexpected size of MultiVector" unless $prod.elems == 1;
	    $prod = $prod.pairs.pick;
	    %h{$prod.key} += $prod.value;
	    %h{$prod.key} :delete if %h{$prod.key} == 0;
	} else { die "unexpected type" }
    }
    MultiVector.new: %h;
}
multi infix:<*>(MultiVector $b, BasisVector $a) is export {
    my %h{BasisVector};
    for $b.pairs {
	my $prod = .value * (.key * $a);
	if $prod ~~ Real {
	    %h{e[]} += $prod;
	    %h{e[]} :delete if %h{e[]} == 0;
	} elsif $prod ~~ MultiVector {
	    die "unexpected size of MultiVector" unless $prod.elems == 1;
	    $prod = $prod.pairs.pick;
	    %h{$prod.key} += $prod.value;
	    %h{$prod.key} :delete if %h{$prod.key} == 0;
	} else { die "unexpected type" }
    }
    MultiVector.new: %h;
}

multi infix:<*>(MultiVector $a) is export { $a }
multi infix:<*>(MultiVector $a, MultiVector $b) is export {
    +[+] map { .value * (.key * $b) }, $a.pairs
}

multi infix:<**>(BasisVector $a, Int $n where $n > 0) is export { +[*] $a xx $n }
multi infix:<**>(MultiVector $a, Int $n where $n > 0) is export { +[*] $a xx $n }
