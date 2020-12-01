CREATE TABLE names (nconst varchar(256) PRIMARY KEY,
                                                primaryName text, birthYear integer, deathYear integer, primaryProfession text, knownForTitles text);

COPY names(nconst, primaryName, birthYear, deathYear, primaryProfession, knownForTitles)
FROM '/Users/josh/Documents/code/cs4200-monorepo/ps3/name.basics.tsv'
DELIMITER E'\t' CSV HEADER NULL '\N';


CREATE TABLE titles(tconst VARCHAR(256) PRIMARY KEY,
                                                titleType VARCHAR(256),
                                                          primaryTitle text, originalTitle text, isAdult boolean, startYear integer, endYear integer, runtimeMinutes integer, genres text[]);

COPY titles
FROM '/Users/josh/Documents/code/cs4200-monorepo/ps3/title.basics.tsv'
DELIMITER E'\t' CSV HEADER NULL '\N';


CREATE TABLE ratings(tconst VARCHAR(256) PRIMARY KEY,
                                                 averageRating float8,
                                                 numVotes integer);

COPY ratings
FROM '/Users/josh/Documents/code/cs4200-monorepo/ps3/title.ratings.tsv'
DELIMITER E'\t' CSV HEADER NULL '\N';


CREATE TABLE ratings(tconst VARCHAR(256) PRIMARY KEY,
                                                 averageRating float8,
                                                 numVotes integer);

COPY ratings
FROM '/Users/josh/Documents/code/cs4200-monorepo/ps3/title.ratings.tsv'
DELIMITER E'\t' CSV HEADER NULL '\N';


CREATE TABLE akas(tconst VARCHAR(256),
                         ordering integer, title text, region text, language text, types text[], attributes text[], isOriginalTitle boolean);


CREATE TABLE crews(tconst VARCHAR(256) PRIMARY KEY,
                                               directors varchar(256)[], writers varchar(256)[])
CREATE TABLE principals(tconst varchar(256),
                               ordering integer, nconst varchar(256),
                                                        category text, job text, characters text);


CREATE TABLE directors(tconst varchar(256),
                              nconst varchar(256),
                                     PRIMARY KEY(tconst, nconst));


CREATE TABLE writers(tconst varchar(256),
                            nconst varchar(256),
                                   PRIMARY KEY(tconst, nconst));

COPY principals
FROM '/Users/josh/Documents/code/cs4200-monorepo/ps3/title.principals.tsv'
DELIMITER E'\t' CSV HEADER NULL '\N';


UPDATE crews
SET directors=NULL
WHERE directors='{NULL}';


select array_to_json(array_agg(json_strip_nulls(row_to_json(t))))
from
  (select nconst as _id,
          primaryName as name,
          birthYear,
          deathYear
   from names) t;


select array_to_json(array_agg(json_strip_nulls(row_to_json(t))))
from
  (select titles.tconst as _id,
          titleType as type,
          primaryTitle as title,
          startYear,
          endYear,
          originalTitle,
          runtimeMinutes as runtime,
          genres,
          averageRating as avgRating,
          numVotes,

     (select array_to_json(array_agg(row_to_json(d)))
      from
        (select directors.nconst as _id,
                primaryName as name,
                birthYear,
                deathYear
         from directors
         left join names on directors.nconst = names.nconst
         where tconst = titles.tconst ) d) as directors,

     (select array_to_json(array_agg(row_to_json(d)))
      from
        (select writers.nconst as _id,
                primaryName as name,
                birthYear,
                deathYear
         from writers
         left join names on writers.nconst = names.nconst
         where tconst = titles.tconst ) d) as writers,

     (select array_to_json(array_agg(row_to_json(d)))
      from
        (select principals.nconst as _id,
                primaryName as name,
                birthYear,
                deathYear
         from principals
         left join names on principals.nconst = names.nconst
         where tconst = titles.tconst
           and principals.category='producer') d) as producers,

     (select array_to_json(array_agg(row_to_json(d)))
      from
        (select principals.nconst as _id,
                primaryName as name,
                birthYear,
                deathYear,
                characters as roles
         from principals
         left join names on principals.nconst = names.nconst
         where tconst = titles.tconst
           and (principals.category='actor'
                or principals.category='actress')) d) as actors
   from titles
   left join ratings on titles.tconst = ratings.tconst
   where isAdult=false
   limit 1) t;

copy
  (select array_to_json(array_agg(json_strip_nulls(row_to_json(t))))
   from
     (select titles.tconst as _id,
             titleType as type,
             primaryTitle as title,
             startYear,
             endYear,
             originalTitle,
             runtimeMinutes as runtime,
             genres,
             averageRating as avgRating,
             numVotes,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select directors.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from directors
            left join names on directors.nconst = names.nconst
            where tconst = titles.tconst ) d) as directors,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select writers.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from writers
            left join names on writers.nconst = names.nconst
            where tconst = titles.tconst ) d) as writers,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select principals.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from principals
            left join names on principals.nconst = names.nconst
            where tconst = titles.tconst
              and principals.category='producer') d) as producers,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select principals.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from principals
            left join names on principals.nconst = names.nconst
            where tconst = titles.tconst
              and (principals.category='actor'
                   or principals.category='actress')) d) as actors
      from titles
      left join ratings on titles.tconst = ratings.tconst
      where isAdult=false) t) TO '/tmp/movies.json';


create index directors_nconst ON directors(nconst);

copy
  (select (json_strip_nulls(row_to_json(t)))
   from
     (select titles.tconst as _id,
             titleType as type,
             primaryTitle as title,
             startYear,
             endYear,
             originalTitle,
             runtimeMinutes as runtime,
             genres,
             averageRating as avgRating,
             numVotes,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select directors.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from directors
            left join names on directors.nconst = names.nconst
            where tconst = titles.tconst ) d) as directors,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select writers.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from writers
            left join names on writers.nconst = names.nconst
            where tconst = titles.tconst ) d) as writers,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select principals.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from principals
            left join names on principals.nconst = names.nconst
            where tconst = titles.tconst
              and principals.category='producer') d) as producers,

        (select array_to_json(array_agg(row_to_json(d)))
         from
           (select principals.nconst as _id,
                   primaryName as name,
                   birthYear,
                   deathYear
            from principals
            left join names on principals.nconst = names.nconst
            where tconst = titles.tconst
              and (principals.category='actor'
                   or principals.category='actress')) d) as actors
      from titles
      left join ratings on titles.tconst = ratings.tconst
      where isAdult=false) t) TO '/tmp/movies.json';


alter table principals add primary key (tconst,
                                        ordering);