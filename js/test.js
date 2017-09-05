let Parser = require('./parser');

let parser = new Parser();

for(let t of parser.parse('4*x/5 - a*(b+c)**2').terms) console.log(t);


