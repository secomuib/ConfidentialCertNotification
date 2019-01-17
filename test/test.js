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

  it("non receivers can't accept delivery", async function() {
    try { 
      await deliveryContract.methods.accept().send({ from: accounts[3] });
      assert(false);
    } catch (err) {
      assert(err);
    } 
  });

  it("receiver can accept delivery", async function() {
    await deliveryContract.methods.accept().send({ from: accounts[1] });
    var state = await deliveryContract.methods.getState(accounts[1]).call();
    assert.equal(state, "accepted");
  });

  it("non sender can't finish delivery", async function() {
    await deliveryContract.methods.accept().send({ from: accounts[1] });
    await deliveryContract.methods.accept().send({ from: accounts[2] });
    try { 
      await deliveryContract.methods.finish("Test message").send({ from: accounts[3] });
      assert(false);
    } catch (err) {
      assert(err);
    } 
  });

  it("sender can finish delivery", async function() {
    await deliveryContract.methods.accept().send({ from: accounts[1] });
    await deliveryContract.methods.accept().send({ from: accounts[2] });
    await deliveryContract.methods.finish("Test message").send({ from: accounts[0] });
    var message = await deliveryContract.methods.message().call();
    var state = await deliveryContract.methods.getState(accounts[1]).call();
    assert.equal(message, "Test message");
    assert.equal(state, "finished");
  });

});
