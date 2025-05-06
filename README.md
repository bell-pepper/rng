# rng
Solidity RNG contract

    Random number generation smart contract by pepper.meme to generate unpredictable number using seed and block hash that is unknown on generation moment.
    To use it first generateSeed and store it in your contract, then on next request use generateNumberFromSeed that will give you desired random outcome.
    If it's used for lotery or other activity that involves payments, payment should be deducted in first transaction where seed is generated.
    Second transaction is used for execution when result outcome needs to be executed
    If contract doesn't require high level of security generateNumber could be used to get instant result.

Deployed and monithored RNG contract address is https://basescan.org/address/0x82e0bde01a66c0dd245455461227650609a75b6b
