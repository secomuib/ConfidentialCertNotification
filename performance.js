const ganache = require('ganache-cli');
const Web3 = require('web3');
const web3 = new Web3(ganache.provider());

const compiledDeliveryPath = './contracts/build/ConfidentialMultipartyRegisteredEDelivery.json';
const compiledDelivery = require(compiledDeliveryPath);

const compiledNotification2partyPath = './contracts_2party/build/CertifiedMail.json';
const compiledNotification2party = require(compiledNotification2partyPath);

// To prevent warning "MaxListenersExceededWarning: Possible EventEmitter memory leak detected. 11 data listeners added. Use emitter.setMaxListeners() to increase limit"
require('events').EventEmitter.defaultMaxListeners = 0;

const performance = async (functionToTest, functionName, account, results) => {
    let balance1 = await web3.eth.getBalance(account);
    let hrstart = process.hrtime();
    let returnValue = await functionToTest();
    let hrend = process.hrtime(hrstart);
    let balance2 = await web3.eth.getBalance(account);
    console.log('Delay of function '+functionName+'(): %ds %dms', hrend[0], hrend[1] / 1000000);
    console.log('Cost of function '+functionName+'(): \t\t%s', (balance1-balance2).toLocaleString('en').padStart(25));
    results.ms.push(hrend[1] / 1000000);
    results.wei.push(balance1-balance2);
    return returnValue;
};

const average = async (results) => {
    let totalms = 0;
    let totalwei = 0;
    for(let i = 0; i < results.ms.length; i++) {
        totalms += results.ms[i];
        totalwei += results.wei[i];
    }
    console.log('AVERAGE DELAY: %dms', totalms / results.ms.length);
    console.log('AVERAGE COST: %s', (totalwei / results.wei.length).toLocaleString('en'));
}

// Test multiparty contract
const testPerformance = async (numberReceivers, repetitions) => {
    let accounts = await web3.eth.getAccounts();
    let gasPrice = await web3.eth.getGasPrice();
    
    let deliveryContract = [];

    let results = { ms: [], wei: []};
    
    // Add n receivers to the array of receivers
    let arrayReceivers = [];
    for (let i = 1; i<=numberReceivers; i++) {
        arrayReceivers.push(accounts[i%10]);    // i%10 --> There are only 10 addresses.
    }

    console.log('');
    console.log('For %d receiver/s', numberReceivers);
    console.log('------------------------');

    // Deploy notification
    results = { ms: [], wei: []};
    for (let i = 0; i < repetitions; i++) {
        deliveryContract.push(await performance(
            async () => {
                return await new web3.eth.Contract(JSON.parse(compiledDelivery.interface))
                    .deploy({ data: compiledDelivery.bytecode, arguments: [] })
                    .send({ from: accounts[0], gas: '3000000' });
            },
            'deploy',
            accounts[0],
            results
        )); 
    }
    average(results);

    // We add more smart contracts, for cancel() function
    for (let i = 0; i < repetitions; i++) {
        deliveryContract.push(
                await new web3.eth.Contract(JSON.parse(compiledDelivery.interface))
                    .deploy({ data: compiledDelivery.bytecode, arguments: [] })
                    .send({ from: accounts[0], gas: '3000000' })
            
        ); 
    }

    // finish() from accounts[0]
    results = { ms: [], wei: []};
    for (let i = 0; i < repetitions; i++) {
        await performance(
            async () => {
                await deliveryContract[i].methods
                    .finish(1, accounts[1], accounts[2], web3.utils.randomHex(32), web3.utils.randomHex(32))
                    .send({ from: accounts[0], gas: '3000000' });
            },
            'finish',
            accounts[0],
            results
        );
    }
    average(results);

    // cancel() from accounts[1]
    results = { ms: [], wei: []};
    for (let i = repetitions; i < repetitions*2; i++) {
        await performance(
            async () => {
                await deliveryContract[i].methods
                    .cancel(1, arrayReceivers)
                    .send({ from: accounts[1], gas: '3000000' });
            },
            'cancel',
            accounts[1],
            results
        );
    }
    average(results);
    
};

// Test 2-party contract
const testPerformance2party = async (repetitions) => {
    let accounts = await web3.eth.getAccounts();
    let gasPrice = await web3.eth.getGasPrice();
    
    let notification2partyContract = [];

    let results = { ms: [], wei: []};
    
    console.log('');
    console.log('For 2-party notification');
    console.log('------------------------');

    // Deploy notification
    results = { ms: [], wei: []};
    for (let i = 0; i < repetitions; i++) {
        notification2partyContract.push(await performance(
            async () => {
                return await new web3.eth.Contract(JSON.parse(compiledNotification2party.interface))
                    .deploy({ data: compiledNotification2party.bytecode, arguments: [accounts[1], accounts[2]] })
                    .send({ from: accounts[0], gas: '3000000' });
            },
            'deploy',
            accounts[0],
            results
        )); 
    }
    average(results);

    // We add more smart contracts, for cancel() function
    for (let i = 0; i < repetitions; i++) {
        notification2partyContract.push(
                await new web3.eth.Contract(JSON.parse(compiledNotification2party.interface))
                    .deploy({ data: compiledNotification2party.bytecode, arguments: [accounts[1], accounts[2]] })
                    .send({ from: accounts[0], gas: '3000000' })
            
        ); 
    }

    // finish() from accounts[0]
    results = { ms: [], wei: []};
    for (let i = 0; i < repetitions; i++) {
        await performance(
            async () => {
                await notification2partyContract[i].methods
                    .finish(web3.utils.randomHex(32), web3.utils.randomHex(32))
                    .send({ from: accounts[0], gas: '3000000' });
            },
            'finish',
            accounts[0],
            results
        );
    }
    average(results);

    // cancel() from accounts[1]
    results = { ms: [], wei: []};
    for (let i = repetitions; i < repetitions*2; i++) {
        await performance(
            async () => {
                await notification2partyContract[i].methods
                    .cancel()
                    .send({ from: accounts[1], gas: '3000000' });
            },
            'cancel',
            accounts[1],
            results
        );
    }
    average(results);
};

const init = async (repetitions) => {
        await testPerformance(1, repetitions);
        await testPerformance(2, repetitions);
        await testPerformance(10, repetitions);
        await testPerformance2party(repetitions);
}

init(10)