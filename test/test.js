const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const compile = require('../compile');
const compiledDelivery = compile.ConfidentialMultipartyRegisteredEDelivery;

let deliveryContract;
let accounts;

// To prevent warning "MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 data listeners added. Use emitter.setMaxListeners() to increase limit"
require('events').EventEmitter.defaultMaxListeners = 0;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  deliveryContract = await new web3.eth.Contract(JSON.parse(compiledDelivery.interface))
    .deploy({ data: compiledDelivery.bytecode, arguments: [] })
    .send({ from: accounts[0], gas: '3000000' });
});

describe('Certified eDelivery Contract', () => {
  it('deploys a delivery', () => {
    assert.ok(deliveryContract.options.address);
  });

  it("non TTP can't finish delivery", async function() {
    try { 
      await deliveryContract.methods
        .finish(1, accounts[1], accounts[2], web3.utils.randomHex(32), web3.utils.randomHex(32))
        .send({ from: accounts[1], gas: '3000000' });
      assert(false);
    } catch (err) {
      assert(err);
    } 
  });

  it("TTP can finish delivery", async function() {
    await deliveryContract.methods
      .finish(1, accounts[1], accounts[2], web3.utils.randomHex(32), web3.utils.randomHex(32))
      .send({ from: accounts[0], gas: '3000000' });
    var state = await deliveryContract.methods.getState(1, accounts[1], accounts[2]).call();
    assert.equal(state, "finished");
  });

  it("sender can cancel delivery", async function() {
    await deliveryContract.methods
      .cancel(1, [accounts[2], accounts[3]])
      .send({ from: accounts[1], gas: '3000000' });
      var state = await deliveryContract.methods.getState(1, accounts[1], accounts[2]).call();
    assert.equal(state, "cancelled");
  });
});
