# -*- coding: utf-8 -*-
'''
Created on 2018. 9. 21.
@author: Hyechurn Jang, <hyjang@cisco.com>
'''

from jzlib import *
from pygics import *

class MW11(PlugIn):
    def __prev__(self, req, res): print('MW11 start')
    def __post__(self, req, res, data):
        print('MW11 finish')
        return data
class MW12(PlugIn):
    def __prev__(self, req, res): print('MW12 start')
    def __post__(self, req, res, data):
        print('MW12 finish')
        return data

@rest('GET', 'test1')
@plugin(MW11())
@plugin(MW12())
def test1(req, name=None):
    print('REST::test1 called::%s' % name)
    return {'name' : name}

class MW21(PlugIn):
    def __prev__(self, req, res):
        print(req.args)
        print(req.kargs)
        print('MW21 start')
    def __post__(self, req, res, ret):
        print('MW21 finish')
        return ret
class MW22(PlugIn):
    def __prev__(self, req, res):
        print(req.args)
        print(req.kargs)
        print('MW22 start')
    def __post__(self, req, res, ret):
        print('MW22 finish')
        return ret
    
@rest('GET', 'test2')
@plugin(MW21())
@plugin(MW22())
def test2(req):
    print('REST::test2 called')
    return {'name'}

print('URI::MAP::\n%s' % dumpJson(ENV.URI.MAP, indent=2))
