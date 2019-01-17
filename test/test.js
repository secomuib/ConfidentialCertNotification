const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const { interface, bytecode } = require('../compile');

let deliveryContract;
let accounts;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  deliveryContract = await new web3.eth.Contract(JSON.parse(interface))
    .deploy({ data: bytecode, arguments: [[accounts[1], accounts[2]], web3.utils.keccak256("Test message"), 600, 1200] })
    .send({ from: accounts[0], gas: '3000000', value: '100' });
});

describe('Certified eDelivery Contract', () => {
  it('deploys a contract', () => {
    assert.ok(deliveryContract.options.address);
  });

  it("state is created and has a hash message", async function () {
    var messageHash = await deliveryContract.methods.messageHash().call();
    assert.equal(messageHash, web3.utils.keccak256("Test message"));
  });

});
