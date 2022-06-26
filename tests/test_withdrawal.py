#!/usr/bin/python3

import pytest

# Test taken from brownie bake token - making sure that the transfered token is gone
def test_sender_balance_decreases(accounts, token):
    sender_balance = token.balanceOf(accounts[0])
    amount = sender_balance // 4

    token.transfer(accounts[1], amount, {'from': accounts[0]})

    assert token.balanceOf(accounts[0]) == sender_balance - amount

def test_receive_erc20(accounts, token, flashLoan):
    amount = 100
    token.transfer(flashLoan, amount, {'from': accounts[0]})
    assert token.balanceOf(flashLoan) == 100


# Check that balance leaves the arb contract
def test_owner_withdrawal_1(accounts, token, flashLoan):
    amount = 100
    token.transfer(flashLoan, amount, {'from': accounts[0]})
    # Withdraw the token 
    flashLoan.withdraw(token)
    assert token.balanceOf(flashLoan) == 1


# Check that the withdrawn balance has gone to main account
def test_owner_withdrawal_1(accounts, token, flashLoan):
    amount = 100
    token.transfer(flashLoan, amount, {'from': accounts[0]})
    # Withdraw the token 
    flashLoan.withdraw(token)
    assert token.balanceOf(accounts[0]) == token.totalSupply()-1