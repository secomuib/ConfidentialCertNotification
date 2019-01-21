const path = require("path");
const fs = require("fs");
const solc = require("solc");

const CONTRACT_FILE_NAME = "ConfidentialMultipartyRegisteredEDelivery";

var contractPath = path.resolve(__dirname, "contracts", CONTRACT_FILE_NAME+".sol");
var contractSource = fs.readFileSync(contractPath, "utf8");

// solc.compile generates a JSON output
console.log("Compiling "+contractPath+"...");
const output = solc.compile(contractSource, 1).contracts;

for (let contract in output) {
    var contractName = contract.replace(":", "");
    console.log("Exporting "+contractName+" contract...");
    module.exports[contractName] = output[contract];
}
