/* Get count of actors per movie */
SELECT mid, COUNT(*) AS all_count FROM casts JOIN actor ON actor.id=casts.aid GROUP BY casts.mid

/* Get count of male actors per movie */
SELECT mid, COUNT(*) AS male_count FROM casts JOIN (SELECT * FROM actor WHERE gender='M') AS actor ON actor.id=casts.aid GROUP BY casts.mid ORDER BY mid

SELECT * FROM (
  SELECT mid, COUNT(*) AS count FROM casts JOIN actor ON actor.id=casts.aid GROUP BY casts.mid JOIN (
    SELECT mid, COUNT(*) AS count FROM casts JOIN (SELECT * FROM actor WHERE gender='M') AS actor ON actor.id=casts.aid GROUP BY casts.mid ORDER BY mid
  ) AS male_count ON male_count.mid = mid
)

SELECT * FROM (
  (SELECT casts.mid, COUNT(*) AS COUNT FROM casts JOIN actor ON actor.id=casts.aid GROUP BY casts.mid) AS all_count  JOIN (
    SELECT mid, COUNT(*) AS COUNT FROM casts JOIN (SELECT * FROM actor WHERE gender='M') AS actor ON actor.id=casts.aid GROUP BY casts.mid ORDER BY mid
  ) AS male_count ON male_count.mid = all_count.mid
)

SELECT * FROM (
  (SELECT mid, COUNT(*) AS acount FROM casts JOIN actor ON actor.id=casts.aid GROUP BY casts.mid) AS all_count  JOIN (
    SELECT mid, COUNT(*) AS mcount FROM casts JOIN (SELECT * FROM actor WHERE gender='M') AS actor ON actor.id=casts.aid GROUP BY casts.mid ORDER BY mid
  ) AS male_count ON male_count.mid = all_count.mid
) WHERE mcount=acount

SELECT male_count.mid AS mid, acount, mcount FROM (
  (SELECT mid, COUNT(*) AS acount FROM casts JOIN actor ON actor.id=casts.aid GROUP BY casts.mid) AS all_count  JOIN (
    SELECT mid, COUNT(*) AS mcount FROM casts JOIN (SELECT * FROM actor WHERE gender='M') AS actor ON actor.id=casts.aid GROUP BY casts.mid ORDER BY mid
  ) AS male_count ON male_count.mid = all_count.mid
) WHERE mcount=acount

256630,11
210511,14
147603,21
300229,25
276217,25
254943,28
10920,30
314965,30
238695,33
111813,34
192017,34
207992,36
176712,38
116907,39
109093,40
124110,41
176711,41
17173,43


SELECT name, id, fname, lname FROM movie_director JOIN movie ON movie_director.mid = movie.id JOIN director ON movie_director.did = director.id


/* Get movies with director names */
SELECT name, movie.id AS mid, fname, lname FROM movie_director JOIN movie ON movie_director.mid = movie.id JOIN director ON movie_director.did = director.id


SELECT * FROM movie JOIN (
SELECT mid, COUNT(*) AS all_count FROM casts JOIN actor ON actor.id=casts.aid GROUP BY casts.mid
) AS counts ON counts.mid=movie.id WHERE all_count>10

SELECT * FROM movie JOIN (
SELECT mid, COUNT(*) AS all_count FROM casts JOIN actor ON actor.id=casts.aid GROUP BY casts.mid
) AS counts ON counts.mid=movie.id WHERE all_count>10

/* Get genre count per movie */
SELECT mid, count(*) FROM movie_genre GROUP BY mid

SELECT * FROM movie_director JOIN director_genre ON movie_director.did=director_genre.did


/* Get max prob by movie id */
SELECT movie_maxes.mid, genre, prob FROM movie_director JOIN director_genre ON movie_director.did=director_genre.did JOIN
(SELECT mid, MAX(prob) AS max_prob FROM movie_director JOIN director_genre ON movie_director.did=director_genre.did GROUP BY mid) AS movie_maxes ON movie_director.mid = movie_maxes.mid AND director_genre.prob=movie_maxes.max_prob


SELECT movie_maxes.mid, name, actor_count, genre AS director_genre, prob AS max_prob, movie_genre_count
FROM movie_director 
JOIN director_genre 
ON movie_director.did=director_genre.did 
JOIN (
  SELECT mid, MAX(prob) AS max_prob 
  FROM movie_director 
  JOIN director_genre 
  ON movie_director.did=director_genre.did 
  GROUP BY mid) AS movie_maxes 
ON movie_director.mid = movie_maxes.mid 
AND director_genre.prob=movie_maxes.max_prob 
JOIN (
  SELECT mid, count(*) AS movie_genre_count 
  FROM movie_genre GROUP BY mid) AS genre_counts
ON genre_counts.mid = movie_maxes.mid
RIGHT JOIN (
  SELECT * 
  FROM movie 
  JOIN (
    SELECT mid, COUNT(*) AS actor_count 
    FROM casts 
    JOIN actor 
    ON actor.id=casts.aid 
    GROUP BY casts.mid
  ) AS counts 
  ON counts.mid=movie.id 
  WHERE actor_count>10
)AS movies_with_actor_count
ON movies_with_actor_count.mid=movie_maxes.mid

SELECT aid, fname, lname, last_year - first_year AS active_years FROM 
(SELECT aid, fname, lname, MAX(year) AS last_year, MIN(year) AS first_year FROM casts JOIN movie ON casts.mid=movie.id JOIN actor ON casts.aid=actor.id GROUP BY fname, lname, aid) AS aggregates ORDER BY active_years DESC