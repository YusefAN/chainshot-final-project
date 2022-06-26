#!/usr/bin/python3

import pytest
import numpy as np
from random import randint
# Test taken from brownie bake token - making sure that the transfered token is gone


# dy = (dx*fee*y) / (dx*fee + x)
def getAmountsOut(dx, x0 , y0, fee):
    dxFee = dx * (1-(fee/10000))
    return (dxFee * y0) // (dxFee + x0)


def test_getOut(accounts, flashLoanCheck):
    dx = 1000
    x0 = 50000
    y0 = 50000
    fee = 17
    assert flashLoanCheck.getOut(dx,x0,y0,fee) == getAmountsOut(dx, x0, y0,fee)

# by equivalence we can work backwards and check our amount in fn
def test_getIn(accounts, flashLoanCheck):
    dx = 1000
    x0 = 50000
    y0 = 50000
    fee = 17
    out = flashLoanCheck.getOut(dx,x0,y0,fee)
    assert flashLoanCheck.getIn(out, y0, x0 , fee)==dx
