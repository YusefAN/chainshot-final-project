// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IUniswapV2Pair.sol";
import "./interfaces/IUniswapV2Factory.sol";



interface IVVSCallee {
    function vvsCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface IMeerkatCallee {
    function MeerkatCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

interface mm_swapI {
    function exchange(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);

    function get_virtual_price() external view returns (uint256);

    function exchange_underlying(
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);

    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external view returns (uint256);
}

interface avtoI {
    function getTokenIndex(address tokenAddress) external view returns (uint8);

    // min return calculation functions
    function calculateSwap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx
    ) external view returns (uint256);

    function swap(
        uint8 tokenIndexFrom,
        uint8 tokenIndexTo,
        uint256 dx,
        uint256 minDy,
        uint256 deadline
    ) external returns (uint256);
}

interface uniswapI {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

contract multiSwapBorrow {
    address public owner;

    //Create index for swapKind - 0 for uniswap, 1 for Saddle, 2 for Curve(metapool) , 3 Curve(base-pool)
    struct swapInfo {
        uint8 kind;
        int128 idxI;
        int128 idxJ;
        uint8 avtoIdxI;
        uint8 avtoIdxJ;
    }

    struct stableSwaps {
        address avtoAddress;
        address mm_swapAddress;
        address annex_swapAddress;
        address ferro_swapAddress;
    }

    constructor() {
        owner = msg.sender;
    }

    // Refactored as internal function to clear up memory
    function _getAmountsOut(
        address to,
        uint256 _amountIn,
        address[2] memory _route
    ) internal view returns (uint256) {
        // Needs a non 2 length array
        address[] memory tempRoute = new address[](2);
        (tempRoute[0], tempRoute[1]) = (_route[0], _route[1]);

        uint256[] memory tempOut = new uint256[](2);
        tempOut = uniswapI(to).getAmountsOut(_amountIn, tempRoute);

        // Assuming route length 2 - returns the output amount
        return tempOut[1];
    }

    // Refactored as internal function to clear up memory
    function _getAmountsIn(
        address to,
        uint256 _amountOut,
        address[2] memory _route
    ) internal view returns (uint256) {
        // Needs a non 2 length array
        address[] memory tempRoute = new address[](2);
        (tempRoute[0], tempRoute[1]) = (_route[0], _route[1]);

        uint256[] memory tempOut = new uint256[](2);
        tempOut = uniswapI(to).getAmountsIn(_amountOut, tempRoute);

        // Assuming route length 2 - returns the output amount
        return tempOut[0];
    }

    function _getDeadline() internal view returns (uint256) {
        return block.timestamp + 600;
    }

    function _needsApproval(
        address _token,
        address _spender,
        uint256 _amount
    ) internal {
        uint256 approvedAmount = IERC20(_token).allowance(
            address(this),
            _spender
        );

        if (approvedAmount < _amount) {
            IERC20(_token).approve(_spender, type(uint256).max);
        }
    }

    function swap(
        address[] calldata tos,
        address[] calldata route,
        swapInfo[] calldata swapKind,
        uint256 amountIn,
        stableSwaps calldata _stableSwaps
    ) external returns (bool) {
        // e.g. swap to MMF, AVTO - > nSwaps = 2
        uint256 nSwaps = tos.length;
        uint256 amount = amountIn;
        //Amounts out - length 3

        //Amount In is the amount to borrow
        uint256 repayAmount = _getAmountsIn(
            tos[0],
            amountIn,
            [route[0], route[1]]
        );

        for (uint256 i = 1; i < nSwaps; i++) {
            // if Avto
            if (swapKind[i].kind == 1) {
                amount = avtoI(_stableSwaps.avtoAddress).calculateSwap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount
                );
            }
            // Curve
            else if (swapKind[i].kind == 2) {
                amount = mm_swapI(_stableSwaps.mm_swapAddress)
                    .get_dy_underlying(
                        swapKind[i].idxI,
                        swapKind[i].idxJ,
                        amount
                    );
            } else if (swapKind[i].kind == 3) {
                amount = mm_swapI(_stableSwaps.annex_swapAddress).get_dy(
                    swapKind[i].idxI,
                    swapKind[i].idxJ,
                    amount
                );
            } else if (swapKind[i].kind == 4) {
                amount = avtoI(_stableSwaps.ferro_swapAddress).calculateSwap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount
                );
            }
            // Uniswap
            else {
                amount = _getAmountsOut(
                    tos[i],
                    amount,
                    [route[i], route[i + 1]]
                );
            }
        }

        if (repayAmount > amount) {
            return false;
        } else {
            {
                bytes memory swapData = abi.encode(
                    tos,
                    route,
                    repayAmount,
                    amountIn,
                    _stableSwaps,
                    swapKind
                );
                {
                    address factory = uniswapI(tos[0]).factory();
                    uint256[2] memory borrowData = route[0] < route[1]
                        ? [0, amountIn]
                        : [amountIn, 0];
                    IUniswapV2Pair(
                        IUniswapV2Factory(factory).getPair(route[0], route[1])
                    ).swap(
                            borrowData[0],
                            borrowData[1],
                            address(this),
                            swapData
                        );
                }
            }
            return false;
        }
    }

    function vvsCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        (
            address[] memory tos,
            address[] memory route,
            uint256 repayAmount,
            uint256 amount,
            stableSwaps memory _stableSwaps,
            swapInfo[] memory swapKind
        ) = abi.decode(
                data,
                (
                    address[],
                    address[],
                    uint256,
                    uint256,
                    stableSwaps,
                    swapInfo[]
                )
            );

        uint256 nSwaps = tos.length;
        for (uint256 i = 1; i < nSwaps; i++) {
            // If needs approval for the token then approve else don't
            _needsApproval(route[i], tos[i], amount);

            // if Avto
            if (swapKind[i].kind == 1) {
                amount = avtoI(_stableSwaps.avtoAddress).swap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount,
                    0,
                    _getDeadline()
                );
            } else if (swapKind[i].kind == 4) {
                amount = avtoI(_stableSwaps.ferro_swapAddress).swap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount,
                    0,
                    _getDeadline()
                );
            } else if (swapKind[i].kind == 2) {
                amount = mm_swapI(_stableSwaps.mm_swapAddress)
                    .exchange_underlying(
                        swapKind[i].idxI,
                        swapKind[i].idxJ,
                        amount,
                        0
                    );
            } else if (swapKind[i].kind == 3) {
                amount = mm_swapI(_stableSwaps.annex_swapAddress).exchange(
                    swapKind[i].idxI,
                    swapKind[i].idxJ,
                    amount,
                    0
                );
            } else {
                address[] memory tempRoute = new address[](2);
                (tempRoute[0], tempRoute[1]) = (route[i], route[i + 1]);

                uint256[] memory tempOut = uniswapI(tos[i])
                    .swapExactTokensForTokens(
                        amount,
                        0,
                        tempRoute,
                        address(this),
                        _getDeadline()
                    );
                amount = tempOut[1];
            }
        }

        IERC20(route[0]).transfer(msg.sender, repayAmount);
    }

    function MeerkatCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        (
            address[] memory tos,
            address[] memory route,
            uint256 repayAmount,
            uint256 amount,
            stableSwaps memory _stableSwaps,
            swapInfo[] memory swapKind
        ) = abi.decode(
                data,
                (
                    address[],
                    address[],
                    uint256,
                    uint256,
                    stableSwaps,
                    swapInfo[]
                )
            );

        uint256 nSwaps = tos.length;
        for (uint256 i = 1; i < nSwaps; i++) {
            // If needs approval for the token then approve else don't
            _needsApproval(route[i], tos[i], amount);

            // if Avto
            if (swapKind[i].kind == 1) {
                amount = avtoI(_stableSwaps.avtoAddress).swap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount,
                    0,
                    _getDeadline()
                );
            } else if (swapKind[i].kind == 4) {
                amount = avtoI(_stableSwaps.ferro_swapAddress).swap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount,
                    0,
                    _getDeadline()
                );
            } else if (swapKind[i].kind == 2) {
                amount = mm_swapI(_stableSwaps.mm_swapAddress)
                    .exchange_underlying(
                        swapKind[i].idxI,
                        swapKind[i].idxJ,
                        amount,
                        0
                    );
            } else if (swapKind[i].kind == 3) {
                amount = mm_swapI(_stableSwaps.annex_swapAddress).exchange(
                    swapKind[i].idxI,
                    swapKind[i].idxJ,
                    amount,
                    0
                );
            } else {
                address[] memory tempRoute = new address[](2);
                (tempRoute[0], tempRoute[1]) = (route[i], route[i + 1]);

                uint256[] memory tempOut = uniswapI(tos[i])
                    .swapExactTokensForTokens(
                        amount,
                        0,
                        tempRoute,
                        address(this),
                        _getDeadline()
                    );
                amount = tempOut[1];
            }
        }

        IERC20(route[0]).transfer(msg.sender, repayAmount);
    }

    function cronaCall(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external {
        (
            address[] memory tos,
            address[] memory route,
            uint256 repayAmount,
            uint256 amount,
            stableSwaps memory _stableSwaps,
            swapInfo[] memory swapKind
        ) = abi.decode(
                data,
                (
                    address[],
                    address[],
                    uint256,
                    uint256,
                    stableSwaps,
                    swapInfo[]
                )
            );

        uint256 nSwaps = tos.length;
        for (uint256 i = 1; i < nSwaps; i++) {
            // If needs approval for the token then approve else don't
            _needsApproval(route[i], tos[i], amount);

            // if Avto
            if (swapKind[i].kind == 1) {
                amount = avtoI(_stableSwaps.avtoAddress).swap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount,
                    0,
                    _getDeadline()
                );
            } else if (swapKind[i].kind == 4) {
                amount = avtoI(_stableSwaps.ferro_swapAddress).swap(
                    swapKind[i].avtoIdxI,
                    swapKind[i].avtoIdxJ,
                    amount,
                    0,
                    _getDeadline()
                );
            } else if (swapKind[i].kind == 2) {
                amount = mm_swapI(_stableSwaps.mm_swapAddress)
                    .exchange_underlying(
                        swapKind[i].idxI,
                        swapKind[i].idxJ,
                        amount,
                        0
                    );
            } else if (swapKind[i].kind == 3) {
                amount = mm_swapI(_stableSwaps.annex_swapAddress).exchange(
                    swapKind[i].idxI,
                    swapKind[i].idxJ,
                    amount,
                    0
                );
            } else {
                address[] memory tempRoute = new address[](2);
                (tempRoute[0], tempRoute[1]) = (route[i], route[i + 1]);

                uint256[] memory tempOut = uniswapI(tos[i])
                    .swapExactTokensForTokens(
                        amount,
                        0,
                        tempRoute,
                        address(this),
                        _getDeadline()
                    );
                amount = tempOut[1];
            }
        }

        IERC20(route[0]).transfer(msg.sender, repayAmount);
    }

    function withdraw(address token) external {
        IERC20(token).transfer(
            owner,
            IERC20(token).balanceOf(address(this)) - 1
        );
    }

    receive() external payable {}
}
