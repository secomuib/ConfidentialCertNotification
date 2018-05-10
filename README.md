# Ethereum project manual
Ethereum project manual: Git, Node, Solidity...

## Table of contents
* [Prerequisites](#prerequisites)
* [Using Git](#using-git)
* [Starting a new project](#starting-a-new-project)
* [Example project](#example-project)
* [Working with an existing project](#working-with-an-existing-project)
  
## Prerequisites
* __Git__
  * [Git for Windows](https://git-scm.com/download/win)
  * Git for Linux:
  ```
  sudo apt-get install git
  ```
  * or [GitHub Desktop](https://desktop.github.com/)
* __Node.js & npm__
  * [Node 8 for Windows](https://nodejs.org/dist/v8.9.1/node-v8.9.1-x64.msi)
  * Node 8 for Linux:
  ```
  curl -sL https://deb.nodesource.com/setup_8.x | sudo -E bash -
  sudo apt-get install -y build-essential
  sudo apt-get install -y nodejs
  ```
  * Execute once to install Web3, __only in Windows__, as administrator:
  ```
  npm install --global --production windows-build-tools 
  ```
* __Visual Studio Code__
  * [Visual Studio Code for Windows/Linux/Mac](https://code.visualstudio.com/Download)
  * [Ethereum Solidity Language plugin for Visual Studio Code](https://marketplace.visualstudio.com/items?itemName=JuanBlanco.solidity)

## Using Git

| Command                             | Description                                           |
| ------------------------------------|-------------------------------------------------------|
| `git init`                          | Creates a new local repository                        |
| `git clone <url>`                   | Downloads an entire repository via URL                |
| `git status`                        | Show modified files in working directory              |
| `git diff [filename]`               | Shows file differences not yet staged                 |
| `git add [-u] [filename|.|pattern]` | Snapshots the file in preparation for versioning      |
| `git commit [-m "message"]`         | Records file snapshots permanently in version history |
| `git push origin master`            | Uploads all local branch commits to GitHub            |
| `git pull origin master`            | Downloads and incorporates changes from GitHub        |

[Using Version Control in Visual Studio Code](https://code.visualstudio.com/docs/editor/versioncontrol)

## Git workflow
![Git workflow](git.png "Git workflow")

## Starting a new project
Create a new project folder
```
mkdir projectname
cd projectname
```
Create a package.json file
```
npm init
```
Install __solc__ (Solidity compiler), __Mocha__ (JavaScript test framework), __Ganache__ (personal Ethereum blockchain), __Web3__ (Ethereum JavaScript API), and __truffle-hdwallet-provider__(HD Wallet-enabled Web3 provider) npm modules, saving this dependencies to package.json file
```
npm install --save solc mocha ganache-cli web3@1.0.0-beta.26 truffle-hdwallet-provider
```
Initialize a new Git local repository
```
git init
```
Add GitHub remote reposotory
```
git remote add origin https://github.com/secomuib/projectname.git
```

## Example project
 * [package.json file](https://github.com/secomuib/ethereum-project-manual/blob/master/package.json)
 * [.gitignore file](https://github.com/secomuib/ethereum-project-manual/blob/master/.gitignore)
 * [compile.js file](https://github.com/secomuib/ethereum-project-manual/blob/master/compile.js)
 * [test.js file](https://github.com/secomuib/ethereum-project-manual/blob/master/test/test.js)
 * [deploy.js file](https://github.com/secomuib/ethereum-project-manual/blob/master/deploy.js)

## Working with an existing project
Clone an exisiting GitHub repository
```
git clone https://github.com/secomuib/projectname.git
cd projectname
```
Install all modules listed as dependencies in package.json
```
npm install
```

__Deploy contract__: `npm start` or `node deploy.js`

__Execute test__: `npm test` or `mocha`
