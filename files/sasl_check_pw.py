#!/usr/bin/env python
import os
import sys
import anydbm

db_path = sys.argv[1]
user = sys.argv[2]
domain = sys.argv[3]
password = os.environ["userPassword"]

seq = (user, domain, "userPassword")
key = chr(0).join( seq )

db = anydbm.open(db_path)
if db.has_key(key) and db[key] == password:
    print "matched"
else:
    print "does not match"
db.close()
