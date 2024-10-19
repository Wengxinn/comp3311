-- COMP3311 22T1 Ass2 ... extra database definitions
-- add any views or functions you need to this file
-- By WENG XINN CHOW (z5346077) on 17.04.2022

-- Returns top N directors directed the most movies
-- ordered by the number of movies directed (from largest to smallest)
-- and their names (in alphabetically order) if having same number of movies directed
create or replace function 
    q1_directors(N integer) returns table(nmovies integer, name text)
as $$
    select count(cr.movie_id), n.name
	from names n
	    join crew_roles cr on (n.id = cr.name_id)
	where cr.role = 'director'
	group by n.name
	order by
		count(cr.movie_id) desc,
		n.name asc
	limit $1
$$ language sql
;

-- Returns id, title, year, rating of movies whose title match the pattern specified
-- ordered by rating (from highest to lowest)
-- then year of release (from earliest to latest)
-- then title (in alphabetical order)
create or replace function 
    q2_movies(pattern text) returns table(id integer, title text, year yeartype, rating double precision)
as $$
    select id, title, start_year, rating
    from movies
    where title ~*$1
    order by 
        rating desc, 
        start_year asc, 
        title asc
$$ language sql
;

-- Returns title, region, language, extra info of all aliases of the specified movie
-- ordered by ordering
create or replace function
    q2_aliases(id integer) returns table(local_title text, region character(4), 
    language character(4), extra_info text) 
as $$
    select a.local_title, a.region, a.language, a.extra_info
    from movies m 
        join aliases a on (m.id = a.movie_id)
    where m.id = $1
    order by 
        a.ordering
$$ language sql 
;

-- Returns all actors and their played roles in the given movie
-- ordered by ordering and role name (in alphabetical order) if ordering is equal
create or replace function 
    q3_actors(id integer) returns table(name text, role text)
as $$
    select n.name, a.played
    from principals p
        join names n on (p.name_id = n.id)
        join acting_roles a on (p.name_id = a.name_id and p.movie_id = a.movie_id)
    where p.movie_id = $1
    order by
        p.ordering, 
        a.played
$$ language sql
;

-- Returns all crew members and their roles in the given movie
-- ordered by ordering and role name (in alphabetical order) if ordering is equal
create or replace function 
    q3_crews(id integer) returns table(name text, role text)
as $$
    select n.name, c.role
    from principals p
        join names n on (p.name_id = n.id)
        join crew_roles c on (p.name_id = c.name_id and p.movie_id = c.movie_id)
    where p.movie_id = $1
    order by
        p.ordering, 
        c.role
$$ language sql
;

-- Returns all people whose name matches the specified pattern
-- order by names (in alphabetical order)
-- then by birth year (in chronological order)
-- and their name_id (ascending) if they have the same name and birth year
create or replace function 
    q4_people(pattern text) returns table(id integer, name text, birth_year yeartype, 
    death_year yeartype)
as $$
    select id, name, birth_year, death_year
    from names
    where name ~*$1
    order by 
        name, 
        birth_year, 
        id
$$ language sql
;      

-- Returns the average rating of all movies the person have been a principal in
create or replace function
    q4_avgrating(id integer) returns table(avg decimal)
as $$
    select round(avg(m.rating)::decimal, 1)
    from principals p
        join names n on (p.name_id = n.id)
        join movies m on (p.movie_id = m.id)
    where p.name_id = $1
$$ language sql
;

-- Returns top 3 genres of movies the person have been a principal in 
-- The genres are order by the number of movies (descending)
-- then the genre name (in alphabetical order)
create or replace function
    q4_genres(id integer) returns table(genre text, nmovies integer)
as $$
    select m.genre, count(m.movie_id)
    from principals p
        join movie_genres m on (p.movie_id = m.movie_id)
    where p.name_id = $1
    group by m.genre
    order by 
        count(m.movie_id) desc, 
        genre asc
    limit 3
$$ language sql
;

-- Returns all movies that the person have been a principal in
-- ordered by start year (in chronological order)
-- and title (in alphabetical order) if there are multiple years in a given year
create or replace function
    q4_movies(id integer) returns table(id integer, title text, year yeartype)
as $$ 
    select m.id, m.title, m.start_year
    from principals p
        join names n on (p.name_id = n.id)
        join movies m on (p.movie_id = m.id)
    where p.name_id = $1
    order by 
        m.start_year,
        m.title 
$$ language sql
;

-- Returns all the acting roles that the person played in the specified movie
-- ordered by the role name (in alphabetical order)
create or replace function
    q4_aroles(name_id integer, movie_id integer) returns table(role text)
as $$
    select a.played
    from principals p
        join acting_roles a on (p.movie_id = a.movie_id and p.name_id = a.name_id)
    where p.name_id = $1
        and p.movie_id = $2
    order by 
        a.played
$$ language sql
;

-- Returns all production crew roles that the person had in the specified movie
-- ordered by the role name (in alphabetical order)
create or replace function
    q4_croles(name_id integer, movie_id integer) returns table(role text)
as $$
    select c.role
    from principals p
        join crew_roles c on (p.movie_id = c.movie_id and p.name_id = c.name_id)
    where p.name_id = $1
        and p.movie_id = $2
    order by 
        c.role
$$ language sql
;
