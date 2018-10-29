const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const { interface, bytecode } = require('../compile');

let notificationContract;
let accounts;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  notificationContract = await new web3.eth.Contract(JSON.parse(interface))
    .deploy({ data: bytecode, arguments: [accounts[1], web3.utils.keccak256("Test message"), 600] })
    .send({ from: accounts[0], gas: '3000000', value: '100' });
});

describe('Notification Contract', () => {
  it('deploys a contract', () => {
    assert.ok(notificationContract.options.address);
  });

  it("state is created and has a hash message", async function () {
    var messageHash = await notificationContract.methods.messageHash().call();
    assert.equal(messageHash, web3.utils.keccak256("Test message"));
  });

});
