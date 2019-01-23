const assert = require('assert');
const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const compile = require('../compile');
const compiledFactory = compile.ConfidentialMultipartyRegisteredEDeliveryFactory;
const compiledDelivery = compile.ConfidentialMultipartyRegisteredEDelivery;

let factoryContract;
let deliveryContract;
let deliveryContractAddress;
let accounts;

// To prevent warning "MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 data listeners added. Use emitter.setMaxListeners() to increase limit"
require('events').EventEmitter.defaultMaxListeners = 0;

beforeEach(async () => {
  accounts = await web3.eth.getAccounts();

  factoryContract = await new web3.eth.Contract(JSON.parse(compiledFactory.interface))
    .deploy({ data: compiledFactory.bytecode, arguments: [] })
    .send({ from: accounts[0], gas: '3000000' });

  var a = await factoryContract.methods
    .createDelivery([accounts[2],accounts[3]])
    .send({ from: accounts[1], gas: '3000000' });

  const addresses = await factoryContract.methods.getDeliveries().call();
  deliveryContractAddress = addresses[0];

  deliveryContract = await new web3.eth.Contract(JSON.parse(compiledDelivery.interface), deliveryContractAddress);
});

describe('Certified eDelivery Contract', () => {
  it('deploys a factory and a delivery', () => {
    assert.ok(factoryContract.options.address);
    assert.ok(deliveryContract.options.address);
  });

  it("non TTP can't finish delivery", async function() {
    try { 
      await deliveryContract.methods
        .finish(accounts[2], web3.utils.keccak256("ReceiverSignature"), web3.utils.keccak256("KeySignature"))
        .send({ from: accounts[1] });
      assert(false);
    } catch (err) {
      assert(err);
    } 
  });

  it("TTP can finish delivery", async function() {
    await deliveryContract.methods
      .finish(accounts[2], web3.utils.keccak256("ReceiverSignature"), web3.utils.keccak256("KeySignature"))
      .send({ from: accounts[0] });
    var state = await deliveryContract.methods.getState(accounts[2]).call();
    assert.equal(state, "finished");
  });

  it("non sender can't cancel delivery", async function() {
    try { 
      await deliveryContract.methods
        .cancel()
        .send({ from: accounts[2] });
      assert(false);
    } catch (err) {
      assert(err);
    } 
  });

  it("sender can cancel delivery", async function() {
    await deliveryContract.methods
      .cancel()
      .send({ from: accounts[1] });
    var state = await deliveryContract.methods.getState(accounts[2]).call();
    assert.equal(state, "cancelled");
  });
});
