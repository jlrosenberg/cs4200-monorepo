/* 1 */
SELECT name 
FROM movie 
RIGHT JOIN (
  SELECT male_count.mid AS mid, acount, mcount 
  FROM (
    (SELECT mid, COUNT(*) AS acount 
    FROM casts 
    JOIN actor ON actor.id=casts.aid 
    GROUP BY casts.mid) AS all_count  
    JOIN (
      SELECT mid, COUNT(*) AS mcount 
      FROM casts JOIN 
        (SELECT * 
        FROM actor 
        WHERE gender='M') AS actor 
      ON actor.id=casts.aid 
      GROUP BY casts.mid 
      ORDER BY mid
    )AS male_count ON male_count.mid = all_count.mid
  )WHERE mcount=acount) AS counts ON id=counts.mid;

/* 2 */
SELECT movie.id AS mid, name, director.fname AS d_fname, director.lname AS d_lname, COUNT(movie.id) 
FROM movie_director 
JOIN movie ON movie_director.mid = movie.id 
JOIN director ON movie_director.did = director.id 
JOIN casts ON casts.mid = movie.id 
JOIN actor ON actor.id = casts.aid 
WHERE actor.lname= director.lname AND NOT actor.fname = director.fname 
GROUP BY movie.id, director.fname, director.lname;

/* 3 */
SELECT COALESCE(movie_director.mid, movie_maxes.mid, movies_with_actor_count.mid), name, actor_count, genre AS director_genre, prob AS max_prob, movie_genre_count
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
ON genre_counts.mid = movie_director.mid
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
) AS movies_with_actor_count
ON movies_with_actor_count.mid=movie_director.mid

/* 4 */
SELECT id, fname, lname, CASE WHEN mcount=0 THEN 0 ELSE last_year - first_year + 1 END AS active_years
FROM 
  (SELECT actor.id, fname, lname, count(aid) AS mcount, MAX(year) AS last_year, MIN(year) AS first_year 
  FROM casts 
  JOIN movie ON casts.mid=movie.id 
  FULL OUTER JOIN actor ON casts.aid=actor.id 
  GROUP BY fname, lname, actor.id) AS aggregates 
 ORDER BY active_years DESC

/* 5 */
SELECT movie.id, name 
FROM movie 
LEFT JOIN (
  (SELECT COALESCE(movie_director.mid, movie_genre.mid) AS mid, count(*) AS count_same
  FROM movie_director 
  JOIN director_genre ON movie_director.did=director_genre.did 
  FULL OUTER JOIN movie_genre ON movie_genre.genre = director_genre.genre AND movie_genre.mid = movie_director.mid
  WHERE director_genre.genre=movie_genre.genre
  GROUP BY(COALESCE(movie_director.mid, movie_genre.mid))) AS both_genres
  JOIN (SELECT COALESCE(movie_director.mid, movie_genre.mid) AS mid, count(*) AS count_total
        FROM movie_director 
        JOIN director_genre ON movie_director.did=director_genre.did 
        FULL OUTER JOIN movie_genre ON movie_genre.genre = director_genre.genre AND movie_genre.mid = movie_director.mid
        GROUP BY(COALESCE(movie_director.mid, movie_genre.mid))) AS all_genres
  ON all_genres.mid=both_genres.mid) 
ON movie.id=COALESCE(all_genres.mid, both_genres.mid)
WHERE count_same=count_total OR (count_same IS NULL AND count_total IS NULL)
