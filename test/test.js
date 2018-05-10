const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const { interface, bytecode } = require('../compile');

let exampleContract;
let accounts;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  exampleContract = await new web3.eth.Contract(JSON.parse(interface))
    .deploy({ data: bytecode, arguments: ["Test message"] })
    .send({ from: accounts[0], gas: '1000000' });
});

describe('ExampleContract Contract', () => {
  it('deploys a contract', () => {
    assert.ok(exampleContract.options.address);
  });

  it("state is created and has a hash message", async function () {
    var message = await exampleContract.methods.message().call();
    assert.equal(message, "Test message");
  });

});
