const path = require("path");
const fs = require("fs");
const solc = require("solc");

const CONTRACT_NAME = "ExampleContract";

var contractPath = path.resolve(__dirname, "contracts", CONTRACT_NAME+".sol");
var contractSource = fs.readFileSync(contractPath, "utf8");

// solc.compile generates a JSON output
module.exports = solc.compile(contractSource, 1).contracts[":"+CONTRACT_NAME];