# Smart contracts for the Supreme Bank CBDC sandbox

![The project logo](./assets/distopiacbdc.jpg)


## Disclaimer

This a sandbox project and not intended for production; use at your own risk.

## Introduction

Yesterday I decided to write a Central Bank Digital Currency ( #CBDC ) prototype.

It's an ERC20 with some extra features:

🤨 an event is emitted for every transfer over a certain configurable amount, known as the "suspicious activity amount", to flag unusual movements of funds (as per #FATF guidance)

🧐 it provides the ability to rank addresses on a sliding scale, automatically limiting transfer amounts or even blocking transfers completely from (or to) a negatively ranked address

😒 unranked addresses are automatically limited to a maximum transfer amount per day, which must be less than the suspicious activity amount; higher ranked addresses are allowed larger amounts, more often

😏 there's a multi-sig function that can burn any funds it likes in any address, requiring two signatories - one from the central bank president, and one from the nation's supreme leader, thus instantly plunging terrorists and money launderers into poverty

💵 then I added a "stimulus check" function, which mints and distributes a specified number of tokens to each and every address currently holding a balance - might be useful for the US government

💰 there's also a "go crazy with the quantative easing" function, which automatically determines the current circulating supply of tokens, and then issues eight times more

🪙 a future planned feature is the imposing of an inescapable sales tax on each transaction (now implemented), which can easily be repurposed into a kick-back for politicians

I only spent half an hour on it, so I haven't written any tests yet.

Perhaps I'll do that at the weekend, along with drafting an EIP.

Or perhaps I'll sell it to some Central Bank for one million dollars.

Which I won't accept in tokens. Cash only.

## Advanced Sample Hardhat Project

This project demonstrates an advanced Hardhat use case, integrating other tools commonly used alongside Hardhat in the ecosystem.

The project comes with a sample contract, a test for that contract, a sample script that deploys that contract, and an example of a task implementation, which simply lists the available accounts. It also comes with a variety of other tools, preconfigured to work with the project code.

Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
npx hardhat help
REPORT_GAS=true npx hardhat test
npx hardhat coverage
npx hardhat run scripts/deploy.ts
TS_NODE_FILES=true npx ts-node scripts/deploy.ts
npx eslint '**/*.{js,ts}'
npx eslint '**/*.{js,ts}' --fix
npx prettier '**/*.{json,sol,md}' --check
npx prettier '**/*.{json,sol,md}' --write
npx solhint 'contracts/**/*.sol'
npx solhint 'contracts/**/*.sol' --fix
```

## Etherscan verification

To try out Etherscan verification, you first need to deploy a contract to an Ethereum network that's supported by Etherscan, such as Ropsten.

In this project, copy the .env.example file to a file named .env, and then edit it to fill in the details. Enter your Etherscan API key, your Ropsten node URL (eg from Alchemy), and the private key of the account which will send the deployment transaction. With a valid .env file in place, first deploy your contract:

```shell
hardhat run --network ropsten scripts/deploy.ts
```

Then, copy the deployment address and paste it in to replace `DEPLOYED_CONTRACT_ADDRESS` in this command:

```shell
npx hardhat verify --network ropsten DEPLOYED_CONTRACT_ADDRESS "Hello, Hardhat!"
```

## Performance optimizations

For faster runs of your tests and scripts, consider skipping ts-node's type checking by setting the environment variable `TS_NODE_TRANSPILE_ONLY` to `1` in hardhat's environment. For more details see [the documentation](https://hardhat.org/guides/typescript.html#performance-optimizations).
