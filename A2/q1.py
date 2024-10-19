# COMP3311 22T1 Ass2 ... print num_of_movies, name of top N people with most movie directed
# By WENG XINN CHOW (z5346077) on 17.04.2022

import sys
import psycopg2

# define any local helper functions here

def string_to_int(s, usage):
	"""
	Convert the given string to int type and return the number.
	If inconvertable, print error message and exit.
	"""
	try:
		num = int(s)
	except:
		print(usage)
		exit(1)
	else:
		return num

# set up some globals

usage = "Usage: q1.py [N]"
db = None

# process command-line args

argc = len(sys.argv)
# No N is specified in the input, set to default = 10
if argc < 2:
	N = 10
# N is specified
else:
	N = string_to_int(sys.argv[1], usage)

# If N < 1, print the message and exit
if N < 1:
	print(usage)
	exit(1)

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	# ... add your code here ...
	cur = db.cursor()
	
	# Top N directors directed the most movies
	qry = """
	select * 
	from q1_directors(%s)
	;
	"""
	cur.execute(qry, [N])
	# Print each tuple in the list from qry
	for t in cur.fetchall():
		print(t[0], t[1])
	
	cur.close()
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()
