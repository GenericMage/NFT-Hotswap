# NFT Hotswap

Based on [Dexhune-C](https://github.com/Peng-Protocol/Dexhune-C) but using instant swaps and a speculative price scheme via a modified iteration of constant function market algorithm to pair an ERC-20 token with an ERC-721 collection. Thus allowing instant swaps of an NFT for an FFT (float enabled fungible token). 
The system incorporates design aspects from [Dexhune-P](https://medium.com/@genericmage1127/design-proposal-dexhune-marker-foundry-23585152debb) (not yet implemented). Such as Delta, which are price changes that occur during specific transactions and liquidity slots which allow depositing or withdrawing listed tokens and claiming fees taken from swaps. 

The hotswap contracts are structured differently from other versions of Dexhune, rather than a singular Exchange contract carrying out orders there are instead individual "controllers" who manage tokens in assigned liquidity contracts. 

The Hotswap contracts will be deployed to Polygon MATIC, the team will list xPLEBs NFTs with a bridged version of Plebbit Token. 
