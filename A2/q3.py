# COMP3311 22T1 Ass2 ... print info about cast and crew for Movie
# By WENG XINN CHOW (z5346077) on 17.04.2022

import sys
import psycopg2

# define any local helper functions here
def string_to_year(s, usage):
	"""
	Convert the given string to year in int type and return the year.
	If inconvertable, print error message and exit.
	"""
	try:
		year = int(s)
	except:
		print(usage)
		exit(1)
	else:
		return year

# set up some globals

usage = "Usage: q3.py 'MovieTitlePattern' [Year]"
db = None
year = None

# process command-line args

argc = len(sys.argv)
# If the pattern is not given, print the message and exit
if argc < 2:
	print(usage)
	exit(1)

pattern = sys.argv[1]
# Year is given
if argc > 2:
	year = string_to_year(sys.argv[2], usage)

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	# ... add your code here ...
	cur = db.cursor()
	
	# Movies whose pattern match the pattern and released in the given year
	if year:
		qry = """
		select * 
		from q2_movies(%s)
		where year = %s
		;
		"""
		cur.execute(qry, [pattern, year])
	# Movies whose pattern match the pattern (year is not given)
	else:
		qry = """
		select * 
		from q2_movies(%s)
		;
		"""
		cur.execute(qry, [pattern])
	matches = cur.fetchall()
	nmatches = len(matches)

	# No match
	if nmatches < 1:
		# Year is given
		if year: 
			print(f"No movie matching '{pattern}' {year}")
		# Year is not given
		else: 
			print(f"No movie matching '{pattern}'")
	# Single match
	elif nmatches == 1:
		mid, title, year, rating = matches[0]
		print(f"{title} ({year})")
		print("===============")
		# Actors played in the movie
		qry = """
		select * 
		from q3_actors(%s)
		;
		"""
		cur.execute(qry, [mid])
		actors = cur.fetchall()
		print("Starring")
		for a in actors:
			name, role = a
			print(f" {name} as {role}")

		# Crew members in the movie
		qry = """
		select * 
		from q3_crews(%s)
		;
		"""
		cur.execute(qry, [mid])
		crews = cur.fetchall()
		print("and with")
		for a in crews:
			name, role = a
			# Capitalise role and replace '_' with ' '
			role = role.replace("_", " ")
			print(f" {name}: {role.capitalize()}")
	# Multiple matches
	else:
		if year: 
			print(f"Movies matching '{pattern}' {year}")
		else: 
			print(f"Movies matching '{pattern}'")
		print("===============")
		for m in matches:
			mid, title, year, rating = m
			print(f"{rating} {title} ({year})")
                   
	cur.close()
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()
