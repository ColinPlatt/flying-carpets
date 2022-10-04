warpToken

Heavily modified ERC20 that offers the ability to "warp" to a new deployment on a weekly basis. 

Implementing a "grasshopper" method, allowing a contract to be both a factory and instance of itself, warpToken, can redeploy a copy of itself as a new token which simultaneously is deployed and removes all liquidity from its previous Uniswap pair to restart its life as a new token at a new address. Only token holders who have _received_ warp tokens in the last 48 hours are eligible to continue on the journey. The remaining holders, well, rugged. 