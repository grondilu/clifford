let Parser = require('./parser');

let parser = new Parser();

console.log(parser.parse('(a-b)**2').toString());

