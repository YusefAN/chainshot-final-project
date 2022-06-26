#!/usr/bin/python3

import pytest

def test_owner(flashLoan, accounts):
    assert flashLoan.owner()==accounts[0]
