#!/usr/bin/python3

from brownie import *

def main():
    c = multiSwapBorrowCheck.deploy({'from': accounts[0]})
    return c
