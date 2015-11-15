use MultiVector;
unit role Vector does MultiVector does Positional;
method blades { grep *.value, ((1, 2, 4 ... *) Z=> self[]) }
method AT-KEY(UInt $n) { $n == 1 ?? self !! 0*self }
method norm { sqrt [+] self »**» 2 }
