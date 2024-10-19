-- comp3311 22T1 Assignment 1
-- Written by WENG XINN CHOW (z5346077)

-- Q1
-- Students enrolled in > 4 distinct programs 
create or replace view Q1_nprograms(student, nprograms)
as 
	select student, count(distinct program) 
	from program_enrolments 
	group by student 
	having count(distinct program) > 4
;

create or replace view Q1(unswid, name)
as
	select unswid, name
	from students s 
	join q1_nprograms np on (s.id = np.student)
	join people p on (s.id = p.id)
;


-- Q2
-- Find the role id for course tutor
create or replace view Q2_ctutor(roleid, role)
as 
	select id, name
	from staff_roles
	where name = 'Course Tutor'

;

-- Count the number of courses tutored by each course tutor
create or replace view Q2_ncourses(staff, ncourses)
as 
	select staff, count(distinct course)
	from course_staff 
	where role = (select roleid from q2_ctutor)
	group by staff
;

create or replace view Q2(unswid, name, course_cnt)
as
	select p.unswid, p.name, nc.ncourses
	from staff s
	join people p on (s.id = p.id)
	join q2_ncourses nc on (s.id = nc.staff)
	where nc.ncourses = (select max(ncourses) from q2_ncourses)
;


-- Q3
-- Subjects offered by school of law
create or replace view Q3_lawsubjs(subject)
as 
	select id
	from subjects
	where offeredby = (select id from orgunits where name = 'School of Law')
;

-- Courses offered by school of law
create or replace view Q3_lawcourses(course, subject)
as 
	select c.id, c.subject
	from courses c
	join q3_lawsubjs ls on (c.subject = ls.subject)
;

-- Distinct students who are enrolled in courses offered by school of law and have mark > 85
create or replace view Q3_students(student)
as 
	select distinct ce.student 
	from course_enrolments ce 
	join q3_lawcourses lc on (ce.course = lc.course)
	where ce.mark > 85
;

create or replace view Q3(unswid, name)
as
	select p.unswid, p.name
	from students s
	join people p on (s.id = p.id)
	join q3_students s2 on (s.id = s2.student)
	where s.stype = 'intl'
;


-- Q4
-- Find id for COMP9020 and COMP9331
create or replace view Q4_subjects(subject, code)
as 
	select id, code
	from subjects 
	where code = 'COMP9020'
	or code = 'COMP9331'
;

-- Pair of the two courses in the same term 
create or replace view Q4_courses(course1, course2)
as 
	select c1.id, c2.id 
	from courses c1 join q4_subjects s1 on (c1.subject = s1.subject), 
	courses c2 join q4_subjects s2 on (c2.subject = s2.subject)
	where c1.term = c2.term
	and c1.id < c2.id
;

-- Students who are enrolled in both courses
create or replace view Q4_students(student,course)
as 
	select student, course 
	from course_enrolments
	where course in (
		(select course1 from q4_courses) 
		union 
		(select course2 from q4_courses)
	)
;

-- Pairs of courses enrolled by each student
create or replace view Q4_stucourses(student, course1, course2)
as 
	select s1.student, s1.course, s2.course
	from q4_students s1, q4_students s2
	where s1.course < s2.course
	and s1.student = s2.student
;

-- Students who are enrolled in both courses in the same term
create or replace view Q4_students2(student)
as 
	select distinct s.student
	from q4_stucourses s
	where (s.course1, s.course2) in (
		(select course1, course2 from q4_stucourses)
		intersect
		(select course1, course2 from q4_courses)
	)
;

create or replace view Q4(unswid, name)
as
	select p.unswid, p.name
	from students s
	join people p on (s.id = p.id)
	join q4_students2 s2 on (s.id = s2.student)
	where s.stype = 'local'
;

-- Q5a
-- Terms from 2009-2012
create or replace view Q5a_terms(termid)
as 
	select id
	from terms 
	where year >= 2009
	and year <= 2012
;

-- COMP3311 courses from 2009-2012
create or replace view Q5a_tcourses(course, term)
as 
	select id, term
	from courses
	where term in (select * from q5a_terms)
	and subject = (select id from subjects where code = 'COMP3311')
;

-- Count the number of students with valid marks for each course
create or replace view Q5a_nstudents(course, nstudents)
as 
	select ce.course, count(ce.student)
	from course_enrolments ce
	join q5a_tcourses tc on (ce.course = tc.course)
	where ce.mark is not null
	group by ce.course
;

-- Count the number of failed students for each course
create or replace view Q5a_nfstudents(course, nstudents)
as 
	select ce.course, count(ce.student)
	from course_enrolments ce
	join q5a_tcourses tc on (ce.course = tc.course)
	where ce.mark is not null
	and ce.mark < 50
	group by ce.course
;

-- Failed rates for each course
create or replace view Q5a_rates(course, rate) 
as 
	select n.course, cast(
		-- Type-cast to decimal
		-- precision: 5 (5 digits), scale: 4 (4 decimal places)
		((nf.nstudents::decimal)/(n.nstudents::decimal)) as decimal(5, 4) 
	)
	from q5a_nstudents n
	join q5a_nfstudents nf on (n.course = nf.course)
;

create or replace view Q5a(term, min_fail_rate)
as
	select t.name, r.rate
	from courses c
	join terms t on (c.term = t.id)
	join q5a_rates r on (c.id = r.course)
	where r.rate = (select min(rate) from q5a_rates)
;


-- Q5b
-- Terms from 2016-2019
create or replace view Q5b_terms(termid)
as 
	select id
	from terms 
	where year >= 2016
	and year <= 2019
;

-- COMP3311 courses from 2016-2019
create or replace view Q5b_tcourses(course, term)
as 
	select id, term
	from courses
	where term in (select * from q5b_terms)
	and subject = (select id from subjects where code = 'COMP3311')
;

-- Count the number of students with valid marks for each course
create or replace view Q5b_nstudents(course, nstudents)
as 
	select ce.course, count(ce.student)
	from course_enrolments ce
	join q5b_tcourses tc on (ce.course = tc.course)
	where ce.mark is not null
	group by ce.course
;

-- Count the number of failed students for each course
create or replace view Q5b_nfstudents(course, nstudents)
as 
	select ce.course, count(ce.student)
	from course_enrolments ce
	join q5b_tcourses tc on (ce.course = tc.course)
	where ce.mark is not null
	and ce.mark < 50
	group by ce.course
;

-- Failed rates for each course
create or replace view Q5b_rates(course, rate) 
as 
	select n.course, cast(
		-- Type-cast to decimal
		-- precision: 5 (5 digits), scale: 4 (4 decimal places)
		((nf.nstudents::decimal)/(n.nstudents::decimal)) as decimal(5, 4) 
		)
	from q5b_nstudents n
	join q5b_nfstudents nf on (n.course = nf.course)
;

create or replace view Q5b(term, min_fail_rate)
as
	select t.name, r.rate
	from courses c
	join terms t on (c.term = t.id)
	join q5b_rates r on (c.id = r.course)
	where r.rate = (select min(rate) from q5b_rates)
;

-- Q6
create or replace function 
	Q6(id integer,code text) returns integer
as $$
	select ce.mark
	from courses c
	join course_enrolments ce on (c.id = ce.course)
	where ce.student = $1
	and c.subject = (select id from subjects where code = $2)
$$ language sql
;


-- Q7
-- Returns all the terms with the specified year and session
create or replace function
	Q7_terms(year integer, session text) returns table(term integer)
as $$
	select id 
	from terms
	where year = $1
	and session = $2
$$ language sql
;	

create or replace function 
	Q7(year integer, session text) returns table (code text)
as $$
	select s.code
	from subjects s
	join courses c on (s.id = c.subject)
	where c.term in (select * from q7_terms($1, $2))
	and s.code ~'^COMP' -- code starts with 'COMP'
	and s.career = 'PG'
$$ language sql
;


-- Q8
-- Returns all courses (with valid marks and grades) enrolled by the student
create or replace function
	Q8_courses(zid integer) returns table(course integer, mark integer, grade text)
as $$
	select ce.course, ce.mark, ce.grade            
	from students s
	join people p on (s.id = p.id)
	join course_enrolments ce on (s.id = ce.student)
	where p.unswid = $1
$$ language sql
;

-- Terms results 
-- Returns a table of terms, marks, grades and uoc for each courses enrolled by the student
create or replace function 
	Q8_tresults(zid integer) returns table(term char(4), mark integer, grade text, uoc integer)
as $$
	select cast(termName(t.id) as char(4)), c2.mark, c2.grade, s.uoc
	from courses c
	join q8_courses($1) c2 on (c.id = c2.course)
	join terms t on (c.term = t.id)
	join subjects s on (c.subject = s.id)
$$ language sql
;

create or replace function
	Q8(zid integer) returns setof TermTranscriptRecord
as $$ 
declare 
    tr record;
    ttr TermTranscriptRecord;
    -- Passing grades
    pgrades text[] := '{"SY", "PT", "PC", "PS", "CR", "DN", "HD", "A", "B", "C", "XE", "T", "PE", "RC", "RS"}';
    termmarks numeric;
    termwam numeric;
    termuoc numeric;
    termuocpassed integer;
    overallwam numeric := 0;
    overallmarks numeric := 0;
    overalluoc numeric := 0;
    overalluocpassed integer := 0;  
    currterm text := '';
begin
    for tr in select * from q8_tresults($1)
    loop
        if (tr.term <> currterm) then
            -- Calculate termwam and termuocpassed after finished looping all records for each term
            if (currterm <> '') then
                -- Avoid zero division
                if (termuoc <> 0) then
                    termwam := round(termmarks / termuoc);
                end if;
                ttr.termwam := termwam;
                ttr.termuocpassed := termuocpassed;
                -- Null termwam if 0
                if (ttr.termwam = 0) then
                    ttr.termwam := null;
                end if;
                -- Null termuocpassed if 0
                if (ttr.termuocpassed = 0) then
                    ttr.termuocpassed := null;
                end if;
                return next ttr;
            end if;
            -- Initialise to 0 for first row of each term
            ttr.term := tr.term;
            currterm := tr.term;
            termmarks := 0;
            termwam := 0;
            termuoc := 0;
            termuocpassed := 0;
        end if;
        -- Calculate marks and uoc for each term
        -- Only include marks and count uoc if valid marks and grades
        if (tr.mark is not null and tr.grade is not null) then
            termmarks := termmarks + (tr.mark * tr.uoc);
            termuoc := termuoc + tr.uoc;
            overallmarks:= overallmarks + (tr.mark * tr.uoc);
            overalluoc := overalluoc + tr.uoc;
        end if;
        -- Only count uoc if grade is valid and passed
        if (tr.grade is not null and tr.grade = any(pgrades)) then 
            termuocpassed := termuocpassed + tr.uoc;
            overalluocpassed := overalluocpassed + tr.uoc;
        end if;
    end loop;
    -- Avoid zero division (empty mark column)
    -- For the last term group
    -- Avoid zero division
    if (termuoc <> 0) then
        termwam := round(termmarks / termuoc);
    end if;
    ttr.termwam := termwam;
    ttr.termuocpassed := termuocpassed;
    -- Null termwam if 0
    if (ttr.termwam = 0) then
        ttr.termwam := null;
    end if;
    -- Null termuocpassed if 0
    if (ttr.termuocpassed = 0) then
        ttr.termuocpassed := null;
    end if;
    -- Avoid zero division
    if (overalluoc <> 0) then
        overallwam := overallmarks / overalluoc;
    end if;
    if ((select count(*) from q8_tresults($1)) <> 0) then
        return next ttr;
        -- Last row for overall 
        ttr.term := 'OVAL';
        -- Null overallwam if 0
        if (overallwam = 0) then
            overallwam := null;
        end if;
        -- Null overalluocpassed if 0
        if (overalluocpassed = 0) then
            overalluocpassed := null;
        end if;
        ttr.termwam := overallwam;
        ttr.termuocpassed := overalluocpassed;
        return next ttr;
    end if;
end;
$$ language plpgsql
;


-- Q9
-- Returns academic object group for the given id
create or replace function
Q9_idgroup(gid integer) returns table(gtype text, gdefby text, negated text, parent text, definition text)
as $$
select gtype, gdefby, negated, parent, definition
from acad_object_groups 
where id = $1
$$ language sql
;

create type EnumObjGroup as (code text);

-- Returns all enumerated objects from group and type specified
create or replace function 
    Q9_enum(gid integer, gtype text) returns setof EnumObjGroup
as $$
begin
    -- For enumerated programs
    if ($2 = 'program') then
        return query
            select cast(p.code as text)
            from program_group_members pgm
                join programs p on (pgm.program = p.id)
                join acad_object_groups aog on (pgm.ao_group = aog.id)
            where aog.id = $1;
    -- For enumerated streams
    elsif ($2 = 'stream') then
        return query
            select cast(s.code as text)
            from stream_group_members sgm
                join streams s on (sgm.stream = s.id)
                join acad_object_groups aog on (sgm.ao_group = aog.id)
            where aog.id = $1;
    -- For enumerated subjects
    else 
        return query
            select cast(s.code as text)
            from subject_group_members sgm
                join subjects s on (sgm.subject = s.id)
                join acad_object_groups aog on (sgm.ao_group = aog.id)
            where aog.id = $1;
    end if;
end;
$$ language plpgsql
;

create type PatternObjGroup as (code text);

-- Return all objects defined by the specified pattern in the group 
create or replace function
    Q9_pattern(gtype text, defintion text) returns setof PatternObjGroup
as $$
declare
    obj PatternObjGroup;
    parts integer;
begin
    -- Has multiple definitions (separated by ',')
    if ($2 like '%,%') then
        parts := length($2) - length(replace($2, ',', '')) + 1;
        if ($1 = 'program') then
            return query
                select * 
                from q9_ppattern($2, parts);
        else
            return query
                select * 
                from q9_spattern($2, parts);
        end if;
    -- Has only one definition 
    else
        if ($1 = 'program') then
            obj.code = $2;
            return next obj;
        else
            return query
                select * 
                from q9_spattern($2, 1);
        end if;
    end if;
end;
$$ language plpgsql
;

-- Returns all programs defined by the specified pattern 
create or replace function
    Q9_ppattern(definition text, parts integer) returns setof PatternObjGroup
as $$
declare
    pp PatternObjGroup;
    p integer;
    currpart text;
begin  
    for p in 1..parts
    loop
        -- Split the definition into parts separated by ','
        -- Record all codes
        currpart := split_part($1, ',', p);
        pp.code := currpart;
        return next pp;
    end loop;
end;
$$ language plpgsql
;

-- Returns all subjects defined by the specified pattern 
create or replace function
    Q9_spattern(definition text, parts integer) returns setof PatternObjGroup
as $$
declare
    p integer;
    currpart text;
    temp text;
begin  
    for p in 1..parts
    loop
        -- Split the definition into parts separated by ','
        -- Record all codes
        if ($1 like '%,%') then
            currpart := split_part($1, ',', p);
        else
            currpart := $1;
        end if;
        -- Pattern starts with '#'
        -- Select from subjects tables -no course filtering needed
        if (currpart like '#%') then  
            -- Extract the levels of the subject group
            temp := trim(both from currpart, '#');
            return query
                select * 
                from q9_getlevels('subjects', temp);
        -- Pattern not starts with '#'
        -- Specified courses (COMP, SENG...)
        else
            -- Starts with '('
            if (currpart like '(%') then
                return query    
                    select * 
                    from q9_getcourses(currpart);
            -- Starts with '{'
            elsif (currpart like '{%') then
                return query 
                    select * 
                    from q9_getcurlycourses(currpart);
            -- Course code only (no special chars)
            else
                return query
                    select * from Q9_codeonly(currpart);
            end if;
        end if;                                        
    end loop;
end;
$$ language plpgsql
;

-- Returns all levels according to the pattern defined in square brackets
create or replace function
    Q9_sbrackets(pattern text) returns text
as $$
declare
    levels text := '';
    start integer;
    ending integer;
    dist integer;
    temp text := '';
    llevel integer;
    hlevel integer;
    level integer;
begin  
    -- Extract substring from position with '[' to ']' (excluding [])
    start := position('[' in $1) + 1;
    ending := position(']' in $1);
    dist := ending - start;
    levels := substring($1 from start for dist);
    -- For levels defined with '-' 
    -- Get all values from the lowest to the highest level
    if (levels like '%-%') then
        llevel := cast(substring($1 from start for 1) as integer);
        hlevel := cast(substring($1 from ending - 1 for 1) as integer);
        for level in llevel..hlevel
        loop 
            temp := temp || cast(level as text);
        end loop;
        levels := temp;
    end if;
    return levels;
end;
$$ language plpgsql
;

-- Returns all subjects with the specified levels
create or replace function
    Q9_getlevels(_table text, pattern text) returns setof PatternObjGroup
as $$
declare 
    levels text[];
begin
    -- For multiple levels
    if ($2 like '%[%]%') then
        levels := regexp_split_to_array(q9_sbrackets($2), '');
        for i in 1..array_length(levels, 1) 
        loop 
            return query
                select * 
                from q9_levelgroup($1, levels[i]);
        end loop;
    -- For single level
    else
        return query
            select * 
            from q9_levelgroup($1, $2);
    end if;
end;
$$ language plpgsql
;

-- Returns all subject codes with the specified levels from the given table
create or replace function
    Q9_levelgroup(_table text, level text) returns setof PatternObjGroup
as $$
begin
    return query
        execute
            'select cast(code as text) from '
            || $1
            || ' where substring(code, ''[0-9]+'') like ' || $2 || '||''%''';
end;
$$ language plpgsql
;

-- Returns all subject codes with the specified within the code pattern '()'
create or replace function
    Q9_getcourses(pattern text) returns setof PatternObjGroup
as $$
declare
    start integer;
    ending integer;
    dist integer;
    courses text;
    levels text := '';
    parts integer;
    currpart text;
    p integer;
begin
    -- Extract substring from position with '(' to ')' (excluding ())
    start := position('(' in $1) + 1;
    ending := position(')' in $1);
    dist := ending - start;
    courses := substring($1 from start for dist);
    parts := length(courses) - length(replace(courses, '|', '')) + 1;
    -- Extract levels of courses (if exists)
    levels := substring($1, '[0-9]+');
    for p in 1..parts
    loop 
        currpart := split_part(courses, '|', p);
        return query
            select code
            from q9_courselevel(currpart, levels);
    end loop;
end;
$$ language plpgsql
;

-- Get all the subjects defined by the given alphabets and numbers (levels) -- if exists
create or replace function
Q9_courselevel(alph text, levels text) returns setof PatternObjGroup
as $$
begin
    -- Levels specified
    if ($2 <> '') then
        return query
            select * 
            from q9_getlevels('q9_courseonly(''' || $1 ||''')', $2);
    -- Only alphabets (no levels )
    else
        return query
            select * 
            from q9_courseonly($1);
    end if;
end;
$$ language plpgsql
;

-- Returns all subject codes with the specified code pattern (in alphabets only)
create or replace function 
Q9_courseonly(pattern text) returns setof PatternObjGroup
as $$
select code 
from subjects 
where code ~$1
$$language sql
;

-- Returns all subject codes in the curly braces (should have complete codes in the braces)
create or replace function
    Q9_getcurlycourses(pattern text) returns setof PatternObjGroup
as $$
declare
    cc PatternObjGroup;
    start integer;
    ending integer;
    dist integer;
    courses text;
    parts integer;
    currpart text;
    p integer;
begin
    -- Extract substring from position with '{' to '}' (excluding {})
    start := position('{' in $1) + 1;
    ending := position('}' in $1);
    dist := ending - start;
    courses := substring($1 from start for dist);
    parts := length(courses) - length(replace(courses, ';', '')) + 1;
    -- Record all existing codes
    for p in 1..parts
    loop 
        currpart := split_part(courses, ';', p);
        cc.code := currpart;
        return next cc;
    end loop;
end;
$$ language plpgsql
;

-- Returns all subjects code defined by code-only patterns (complete code or with options)
create or replace function
    Q9_codeonly(pattern text) returns setof PatternObjGroup
as $$
declare
    co PatternObjGroup;
    start integer;
    ending integer;
    dist integer;
    first text := '';
    second text := '';
    pos integer;
    p integer;
    options text[];
    pattern2 text;
begin
    -- Have multiple options (similar to levels) - contains [] 
    if ($1 like '%[%]%') then
        -- Extract the first half substring (before '[')
        start := 1;
        ending := position('[' in $1);
        dist := ending - start;
        first := substring($1 from start for dist);
        -- Extract the second half substring (after '[')
        start := position(']' in $1) + 1;
        second := substring($1 from start);
        -- Trim '#' if pattern has '#' 
        if (second like '%#%') then
            second :=  trim(both from second, '#');
        end if;
        -- Position to match the patterns (options)
        pos := position('[' in $1);
        options := regexp_split_to_array(q9_sbrackets($1), '');
        for i in 1..array_length(options, 1) 
        loop 
            pattern2 := first || options[i] || second;
            return query
                select * 
                from q9_courseonly(pattern2);
        end loop;
    -- No options
    else
        -- Alphabtes only (select all courses according to the course)
        -- Trim '#' if pattern has '#' 
        if ($1 like '%#%') then
            pattern2 :=  trim(both from $1, '#');
            return query
                select * from q9_courseonly(pattern2);
        -- Complete code
        else
            co.code := $1;
            return next co;
        end if;
    end if;
end;
$$ language plpgsql
;

create type ChildGroup as (id integer, gtype text, gdefby text, negated text, definition text);

-- Returns all child groups of the object group 
create or replace function
Q9_child(pid integer) returns setof ChildGroup
as $$
select id, gtype, gdefby, negated, definition 
from acad_object_groups
where parent = pid
or id = pid;
$$ language sql
;

create or replace function 
	Q9(gid integer) returns setof AcObjRecord
as $$
declare
    acr AcObjRecord;
    gtype text;
    gdefby text;
    negated text;
    def text;
    obj record;
    child record;
begin 
    -- For each child group (and parent itself), returns all subject codes for the group
    for child in select * from q9_child($1)
    loop
        select ig.gtype, ig.gdefby, ig.negated, ig.definition
        into gtype, gdefby, negated, def
        from q9_idgroup(child.id) ig;
        -- Ignore if gdefby = query, negated = true, patterns have FREE/GEN/F= as substring
        -- Returns zero rows (no results)
        if (gdefby = 'query'
            or negated = 'true'
            or def ~ 'FREE'
            or def ~ 'GEN'
            or def ~ 'F=') then
            return;
        end if;
        -- Defined by enumerated
        if (gdefby = 'enumerated') then 
            for obj in select distinct * from q9_enum(child.id, gtype)
            loop
                acr.objtype := gtype;
                acr.objcode := obj.code;
                return next acr;
            end loop;
        -- Defined by pattern (program and subject only )
        else 
            for obj in select distinct * 
            from q9_pattern(gtype, def)
            loop 
                acr.objtype := gtype;
                acr.objcode := obj.code;
                return next acr;
            end loop;
        end if;
    end loop;
end;
$$ language plpgsql
;


-- Q10
create type IdGroup as (id integer);

-- Returns all academic objects groups that have definition contain the given code
create or replace function
	Q10_objgroups(code text) returns setof IdGroup
as $$
	select id 
	from acad_object_groups
	where definition ~code;
	$$ language sql
;

-- Returns all rules under the given object group
create or replace function
	Q10_rules(id integer) returns setof IdGroup
as $$
    select id
    from rules 
    where ao_group = $1
$$ language sql
;

-- Returns all (unfiltered) subjects that have the specified subject as prereq
create or replace function 
    Q10_unfiltered(code text) returns setof text 
as $$
declare
    og record;
begin
    for og in select * from q10_objgroups($1)
    loop
        return query
            select distinct cast(s.code as text)
            from subject_prereqs sp 
            join subjects s on (sp.subject = s.id)
            join q10_rules(og.id) r on (sp.rule = r.id);
    end loop;
end;
$$ language plpgsql
;

create or replace function
	Q10(code text) returns setof text
as $$
begin
    return query 
        select distinct *
        from q10_unfiltered($1);
end;
$$ language plpgsql
;

