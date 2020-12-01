CREATE TABLE movies (
  imdb_title_id VARCHAR(256) PRIMARY KEY,
  title TEXT,
  original_title TEXT,
  year_published INTEGER,
  date_published TEXT,
  genre TEXT,
  duration INTEGER,
  country TEXT,
  language TEXT,
  director TEXT,
  writer TEXT,
  production_company TEXT,
  actors TEXT,
  description TEXT,
  avg_vote FLOAT8,
  votes INTEGER,
  budget TEXT,
  usa_gross_income TEXT,
  worldwide_gross_income TEXT,
  metascore FLOAT8,
  reviews_from_users TEXT,
  reviews_from_critics TEXT
);

COPY movies(imdb_title_id,
title,
original_title,
year_published,
date_published,
genre,
duration,
country,
language,
director,
writer,
production_company,
actors,
description,
avg_vote,
votes,
budget,
usa_gross_income,
worldwide_gross_income,
metascore,
reviews_from_users,
reviews_from_critics) FROM '/Users/josh/Downloads/moviesnew/IMDbmovies.csv' DELIMITER ',' CSV HEADER;


CREATE TABLE names(
  imdb_name_id VARCHAR(256) PRIMARY KEY,
  name TEXT,
  birth_name TEXT,
  height INTEGER,
  bio TEXT,
  birth_details TEXT,
  date_of_birth TEXT,
  place_of_birth TEXT,
  death_details TEXT,
  date_of_death TEXT,
  place_of_death TEXT,
  reason_of_death TEXT,
  spouses_string TEXT,
  spouses TEXT,
  divorces TEXT,
  spouses_with_children TEXT,
  children TEXT
);

COPY names(imdb_name_id,name,birth_name,height,bio,birth_details,date_of_birth,place_of_birth,death_details,date_of_death,place_of_death,reason_of_death,spouses_string,spouses,divorces,spouses_with_children,children) FROM '/Users/josh/Downloads/moviesnew/IMDbnames.csv' DELIMITER ',' CSV HEADER;


CREATE TABLE ratings(
  imdb_title_id VARCHAR(256) PRIMARY KEY,
  weighted_average_vote FLOAT8,
  total_votes FLOAT8,
  mean_vote FLOAT8,
  median_vote FLOAT8,
  votes_10 FLOAT8, 
  votes_9 FLOAT8, 
  votes_8 FLOAT8, 
  votes_7 FLOAT8, 
  votes_6 FLOAT8, 
  votes_5 FLOAT8, 
  votes_4 FLOAT8, 
  votes_3 FLOAT8, 
  votes_2 FLOAT8, 
  votes_1 FLOAT8, 
  allgenders_0age_avg_vote FLOAT8, 
  allgenders_0age_votes FLOAT8, 
  allgenders_18age_avg_vote FLOAT8, 
  allgenders_18age_votes FLOAT8, 
  allgenders_30age_avg_vote FLOAT8, 
  allgenders_30age_votes FLOAT8, 
  allgenders_45age_avg_vote FLOAT8, 
  allgenders_45age_votes FLOAT8, 
  males_allages_avg_vote FLOAT8,
  males_allages_votes FLOAT8, 
  males_0age_avg_vote FLOAT8, 
  males_0age_votes FLOAT8, 
  males_18age_avg_vote FLOAT8,
  males_18age_votes FLOAT8, 
  males_30age_avg_vote FLOAT8, 
  males_30age_votes FLOAT8, 
  males_45age_avg_vote FLOAT8, 
  males_45age_votes FLOAT8, 
  females_allages_avg_vote FLOAT8, 
  females_allages_votes FLOAT8, 
  females_0age_avg_vote FLOAT8, 
  females_0age_votes FLOAT8, 
  females_18age_avg_vote FLOAT8, 
  females_18age_votes FLOAT8, 
  females_30age_avg_vote FLOAT8, 
  females_30age_votes FLOAT8, 
  females_45age_avg_vote FLOAT8, 
  females_45age_votes FLOAT8, 
  top1000_voters_rating FLOAT8, 
  top1000_voters_votes FLOAT8, 
  us_voters_rating FLOAT8, 
  us_voters_votes FLOAT8, 
  non_us_voters_rating FLOAT8, 
  non_us_voters_votes FLOAT8
);

COPY ratings(imdb_title_id,weighted_average_vote,total_votes,mean_vote,median_vote,votes_10,votes_9,votes_8,votes_7,votes_6,votes_5,votes_4,votes_3,votes_2,votes_1,allgenders_0age_avg_vote,allgenders_0age_votes,allgenders_18age_avg_vote,allgenders_18age_votes,allgenders_30age_avg_vote,allgenders_30age_votes,allgenders_45age_avg_vote,allgenders_45age_votes,males_allages_avg_vote,males_allages_votes,males_0age_avg_vote,males_0age_votes,males_18age_avg_vote,males_18age_votes,males_30age_avg_vote,males_30age_votes,males_45age_avg_vote,males_45age_votes,females_allages_avg_vote,females_allages_votes,females_0age_avg_vote,females_0age_votes,females_18age_avg_vote,females_18age_votes,females_30age_avg_vote,females_30age_votes,females_45age_avg_vote,females_45age_votes,top1000_voters_rating,top1000_voters_votes,us_voters_rating,us_voters_votes,non_us_voters_rating,non_us_voters_votes) FROM '/Users/josh/Downloads/moviesnew/IMDbratings.csv' DELIMITER ',' CSV HEADER;

CREATE table movie_principals(
  id SERIAL PRIMARY KEY,
  imdb_title_id VARCHAR(256),
  ordering INTEGER,
  imdb_name_id VARCHAR(256),
  category TEXT,
  job TEXT,
  characters TEXT
);

COPY movie_principals(imdb_title_id,ordering,imdb_name_id,category,job,characters) FROM '/Users/josh/Downloads/moviesnew/IMDbtitle_principals.csv' DELIMITER ',' CSV HEADER;

SELECT movies.title FROM movies, ratings WHERE movies.imdb_title_id = ratings.imdb_title_id AND ratings.weighted_average_vote > 5;

EXPLAIN SELECT names.name, ratings.weighted_average_vote, movies.title FROM movie_principals JOIN movies ON movies.imdb_title_id = movie_principals.imdb_title_id JOIN ratings ON movies.imdb_title_id = ratings.imdb_title_id JOIN names ON names.imdb_name_id = movie_principals.imdb_name_id;

ALTER TABLE movie_principals
ADD FOREIGN KEY (imdb_title_id)
REFERENCES movies(imdb_title_id);

CREATE INDEX movie_principals_index_movie_title ON movie_principals USING hash (
  imdb_title_id
)

CREATE INDEX test3 ON movie_principals(
  imdb_name_id
);