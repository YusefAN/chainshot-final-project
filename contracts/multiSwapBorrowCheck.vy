# @version 0.3.3

from vyper.interfaces import ERC20 as IERC20


interface ERC20:
    def transfer(_receiver: address, _amount: uint256): nonpayable
    def transferFrom(_sender: address, _receiver: address, _amount: uint256): nonpayable
    def approve(_spender: address, _amount: uint256): nonpayable
    def balanceOf(_owner: address) -> uint256: view
    def decimals() -> uint8 : view

 
interface UniswapV2Router:
    def factory() -> address : view
    def swapExactTokensForTokens(amountIn: uint256, amountOutMin: uint256, path: DynArray[address, 16],to: address,deadline: uint256) -> DynArray[uint256, 16]: nonpayable
    def getAmountsOut(amountIn : uint256 , path : DynArray[address, 2]) -> DynArray[uint256, 2] : view
    def getAmountsIn(amountOut : uint256, path : DynArray[address,2]) -> DynArray[uint256, 2] : view


interface Saddle:
    def getTokenIndex(tokenAddress : address) -> uint8 : view
    def calculateSwap(tokenIndexFrom : uint8 , tokenIndexTo : uint8, dx : uint256) -> uint256 : view
    def swap(tokenIndexFrom : uint8 ,tokenIndexTo : uint8, dx: uint256 ,minDy : uint256 ,deadline : uint256) -> uint256 : nonpayable

interface Curve:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view
    def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256: view
    def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256): nonpayable
    def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256): nonpayable

interface UniswapV2Factory:
    def getPair(tokenA: address, tokenB : address) -> address : view

interface UniswapV2Pair:
    def token0() -> address: view
    def token1() -> address: view
    def getReserves() -> (uint112, uint112, uint32): view

interface utilsI:
    def sortTokens(tokenA : address ,tokenB: address) -> (address , address) : pure 

# [Router][token0][token1]
reserves : HashMap[address, HashMap[address, HashMap[address, uint256[2]]]]

fees : HashMap[address, uint256]
utils : address

# kind refers to type of swap -> Uniswap, Saddle or Curve. 'Avto idx' is the Saddle. Other is curve indices
struct swapInfo:
    kind: uint8
    idxI: int128
    idxJ :int128
    avtoIdxI : uint8
    avtoIdxJ : uint8

# Input for mempool adjustment
struct txInfo:
    to : address
    amountIn : uint256
    route : DynArray[address, 16]



@external
def __init__():
        sortSwap : address = 0x2e814eD050F5Ad5D1274b24fEfD124F664D17D1A
        self.utils = sortSwap 
 


# @view
# @internal
# def safegetAmountsOutLP(amountIn : uint256, router : address, route :  DynArray[address, 2]) -> uint256:
    # """
    # getAmountsOut needs safety checks to make sure that 
    # 1: lp exists
    # 2: There's enough of a balance to be able to execute the trade 
    # """


# @view
# @internal
# def safegetAmountsInLP(amountIn : uint256, router : address, route :  DynArray[address, 2]) -> uint256:
    # """
    # getAmountsOut needs safety checks to make sure that 
    # 1: lp exists
    # 2: There's enough of a balance to be able to execute the trade 
    # """



# @internal
# def updateMempool(txns : DynArray[txInfo, 16]):
    # """
    # Example [txInfo(mmf, 1000 , [usdc,dai,cro]),txInfo(mmf, 5000 , [usdc,cro])]
    # Takes the mempool decoded transactions and updates LP reserves based on simulated swap
    # """

        

# @internal
# def findBest(_amountIn : uint256 , route : DynArray[address , 16] , routers : DynArray[address, 16]) -> (int128, DynArray[uint256, 16] , DynArray[address, 16], DynArray[swapInfo, 16]): 
    # """
    # amountIn : the amount of of token 0 to put in -> in a borrow this is amount to borrow 
    # route : the route to check - i.e. [usdc, usdt, usdc]
    # routers: the router addresses as an array - i.e. [vvs finance, mmf , cronaswap]
    # ---
    # Returns 
    # profit : total profit defined as swap amount out minus repay amount  
    # amountsOut : uint256 array of swap values - first is repay amount, second is borrow amount -> swap amounts 
    # routersOut : routers where best swap exists
    # swapInfosOut : swapInfo struct that defines parameters for the swap
    # """



# @external
# def findBestGS(_a : uint256, _b : uint256, route : DynArray[address , 16] , routers : DynArray[address, 16], mptxns : DynArray[txInfo, 16], nIterations : uint256, MPCheck : bool) -> (int128, DynArray[uint256, 16] , DynArray[address, 16], DynArray[swapInfo, 16]):    
# """ 
# Finds best permutation of values given a specific set of ordered tokens and amount using golden search method 
# """


# @view
# @internal
# def generateSwapInfo(router: address , from_token : address , to_token : address) -> (swapInfo):
# """
# Generates the swap parameters needed to execute a trade
# If uniswap its blank
# Else the Curve/Saddle indices
# """

@pure
@external
def getOut(dx : uint256, r0 : uint256 , r1 : uint256, _fee : uint256) -> uint256:
    amountInWithFee : uint256 = dx * (10000 - _fee) 
    num : uint256 = amountInWithFee * r1
    den : uint256 = (r0 * 10000) + amountInWithFee
    return num / den

@pure
@external
def getIn(dy : uint256, r0 : uint256 , r1 : uint256, _fee : uint256) -> uint256:
    num : uint256 = r0 * dy * 10000
    den : uint256 = (r1 - dy) * (10000 - _fee)
    return (num / den)+1



@pure
@external
def maxArray(arr : DynArray[uint256, 16]) -> (uint256, uint256):
    """
    Returns the max value and its corresponding index
    """
    maxAmt : uint256 = 0
    maxIdx : uint256 = 0
    nArr: uint256 = len(arr)

    for j in range(16):
        if j<nArr:
            if max(maxAmt , arr[j]) == arr[j]:
                maxAmt=arr[j]
                maxIdx = j
            else:
                continue
                
    return maxAmt, maxIdx

@pure
@external
def minArray(arr : DynArray[uint256, 16]) -> (uint256, uint256):
    """
    Returns the max value and its corresponding index
    """
    minAmt : uint256 = MAX_UINT256
    minIdx : uint256 = 0
    nArr: uint256 = len(arr)

    for j in range(16):
        if j<nArr:
            if min(minAmt , arr[j]) == arr[j]:
                minAmt=arr[j]
                minIdx = j
            else:
                continue
                
    return minAmt, minIdx


# Used for pulling and updating LP reserves for uniswap v2 pools
@external
def getLPReserves(router: address , tokenFrom : address, tokenTo : address):
    # e.g. get DAI, USDC reserves 
    r0 : uint112= 0
    r1 : uint112 = 0
    ts : uint32 = 0

    factory : address = UniswapV2Router(router).factory()
    pair : address = UniswapV2Factory(factory).getPair(tokenFrom , tokenTo)
    if pair == ZERO_ADDRESS:
        pass
    else:
        r0 , r1 , ts = UniswapV2Pair(pair).getReserves()
        
        token0 : address = ZERO_ADDRESS
        token1 : address = ZERO_ADDRESS
        
        token0, token1 = utilsI(self.utils).sortTokens(tokenFrom, tokenTo)

        self.reserves[router][token0][token1][0] = convert(r0, uint256)
        self.reserves[router][token0][token1][1] = convert(r1, uint256)
