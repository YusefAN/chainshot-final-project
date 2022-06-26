#!/usr/bin/python3

import pytest
import numpy as np
from random import randint
# Test taken from brownie bake token - making sure that the transfered token is gone
def test_max_array(accounts, flashLoanCheck):
    rand_array = [randint(1, 1000) for i in range(5)]
    np_rand_array = np.array(rand_array)
    max_num = max(np_rand_array)
    max_idx = np.where(max(np_rand_array)==np_rand_array)[0][0]
    a, b = flashLoanCheck.maxArray(rand_array)
    assert (a,b) == (max_num, max_idx)

def test_min_array(accounts, flashLoanCheck):
    rand_array = [randint(1, 1000) for i in range(5)]
    np_rand_array = np.array(rand_array)
    max_num = min(np_rand_array)
    min_idx = np.where(min(np_rand_array)==np_rand_array)[0][0]
    a, b = flashLoanCheck.minArray(rand_array)
    assert (a,b) == (max_num, min_idx)