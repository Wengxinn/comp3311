# COMP3311 22T1 Ass2 ... get Name's biography/filmography
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

def years_display(byear, year):
	"""
	Return the output for years according to the validity of birth and death years.
	"""
	if not byear:
		return "???"
	elif not dyear:
		return f"{byear}-"
	else:
		return f"{byear}-{dyear}"

# set up some globals

usage = "Usage: q4.py 'NamePattern' [Year]"
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

	# People who born in the given year, whose name match the pattern
	if year:
		qry = """
		select * 
		from q4_people(%s)
		where birth_year = %s
		;
		"""
		cur.execute(qry, [pattern, year])
	# People whose name match the pattern (no year is given)
	else: 
		qry = """
		select * 
		from q4_people(%s)
		;
		"""
		cur.execute(qry, [pattern])
	matches = cur.fetchall()
	nmatches = len(matches)

	# No match
	if nmatches < 1:
		if year: 
			print(f"No name matching '{pattern}' {year}")
		else: 
			print(f"No name matching '{pattern}'")
	# Single match
	elif nmatches == 1:
		nid, name, byear, dyear = matches[0]
		years = years_display(byear, dyear)
		print(f"Filmography for {name} ({years})")
		print("===============")
		# Personal rating (avg) of all movies the person have been a principal in
		qry = """
		select * 
		from q4_avgrating(%s)
		;
		"""
		cur.execute(qry, [nid])
		avg_ = cur.fetchall()
		# The sql query returned value is a tuple with decimal (in a table)
		# Valid average rating
		if avg_[0][0]:
			avg = avg_[0][0]
		# Invalid average rating: no movie is found
		else: 
			avg = 0
		print(f"Personal Rating: {avg}")

		# Top 3 genres of all movies the person have been a principal in 
		qry = """
		select * 
		from q4_genres(%s)
		;
		"""
		cur.execute(qry, [nid])
		genres = cur.fetchall()
		print("Top 3 Genres:")
		for g in genres:
			genre, nmovies = g
			print(f" {genre}")

		# List of all movies the person have been a principal in 
		qry = """
		select * 
		from q4_movies(%s)
		;
		"""
		cur.execute(qry, [nid])
		movies = cur.fetchall()
		print("===============")
		for m in movies:
			mid, title, year = m
			print(f"{title} ({year})")
			# All acting roles the person played in the movie
			qry = """
			select * 
			from q4_aroles(%s, %s)
			;
			"""
			cur.execute(qry, [nid, mid])
			aroles = cur.fetchall()
			for a in aroles:
				print(f" playing {a[0]}")

			# All production crew roles the person had in the movie
			qry = """
			select * 
			from q4_croles(%s, %s)
			;
			"""
			cur.execute(qry, [nid, mid])
			croles = cur.fetchall()
			for c in croles:
				# Capitalise the role and replace '_' with ' '
				role = c[0].replace("_", " ")
				print(f" as {role.capitalize()}")
	# Multiple matches
	else:
		if year: 
			print(f"Names matching '{pattern}' {year}")
		else: 
			print(f"Names matching '{pattern}'")
		print("===============")
		for m in matches:
			nid, name, byear, dyear = m
			years = years_display(byear, dyear)
			print(f"{name} ({years})")

	cur.close()
except psycopg2.Error as err:
	print("DB error: ", err)
finally:
	if db:
		db.close()

