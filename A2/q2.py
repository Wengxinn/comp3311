# COMP3311 22T1 Ass2 ... print info about different releases for Movie
# By WENG XINN CHOW (z5346077) on 17.04.2022

import sys
import psycopg2

# define any local helper functions here

# set up some globals

usage = "Usage: q2.py 'PartialMovieTitle'"
db = None

# process command-line args

argc = len(sys.argv)
# If pattern is not given, print the message and exit
if argc < 2:
	print(usage)
	exit(1)

pattern = sys.argv[1]

# manipulate database

try:
	db = psycopg2.connect("dbname=imdb")
	# ... add your code here ...
	cur = db.cursor()
	
	# Movies whose title match the pattern
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
		print(f"No movie matching '{pattern}'")
	# Single match
	elif nmatches == 1:
		mid, title, year, rating = matches[0]
		# Aliases of the movie ordered by ordering
		qry = """
		select * 
		from q2_aliases(%s)
		;
		"""
		cur.execute(qry, [mid])
		aliases = cur.fetchall()
		# No alias
		if len(aliases) < 1:
			print(f"{title} ({year}) has no alternative releases")
		# Have >= 1 alias
		else: 
			print(f"{title} ({year}) was also released as")
			for a in aliases:
				l_title, region, language, extra_info = a
				# Both region and language exist
				if region and language:
					region = region.strip()
					language = language.strip()
					print(f"'{l_title}' (region: {region}, language: {language})")
				# Region exist only
				elif region: 
					region = region.strip()
					print(f"'{l_title}' (region: {region})")
				# Language exist only
				elif language: 
					language = language.strip()
					print(f"'{l_title}' (language: {language})")
				# Both region and language don't exist. Extra info exists
				elif extra_info: 
					print(f"'{l_title}' ({extra_info})")
				# Neither region, language or extra 
				else: 
					print(f"'{l_title}'")
	# Multiple matches
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
