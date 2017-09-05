let Parser = require('./parser');

let parser = new Parser();

for(let t of parser.parse('(a+b)**10').terms) console.log(t.toString());


