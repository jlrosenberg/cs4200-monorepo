## PS2


### 1

#### A Similar Queries with Different Query Plans
```SQL
SELECT movies.title FROM movies, ratings WHERE movies.imdb_title_id = ratings.imdb_title_id AND ratings.weighted_average_vote > 5;
```
The query plan is as follows
```
                                       QUERY PLAN                                        
-----------------------------------------------------------------------------------------
 Gather  (cost=1000.45..137624.73 rows=67383 width=18)
   Workers Planned: 2
   ->  Nested Loop  (cost=0.45..129886.43 rows=28076 width=18)
         ->  Parallel Seq Scan on ratings  (cost=0.00..4737.16 rows=28076 width=10)
               Filter: (weighted_average_vote > '5'::double precision)
         ->  Bitmap Heap Scan on movies  (cost=0.45..4.46 rows=1 width=28)
               Recheck Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
               ->  Bitmap Index Scan on movies_pkey  (cost=0.00..0.44 rows=1 width=0)
                     Index Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
```

First, the query processor splits the data into two blocks and scans over them in parallel, filtering down to rows where `weighted_average_vote > 5`. It does this first since it is cheaper to do a basic number comparison than it is to do a join, so by filtering down to only results that will be in the result set before performing the join, there are less rows that the join operation is performed on. Once the parellel seq scan is completed, it performs the join.

```SQL
SELECT movies.title FROM movies, ratings WHERE movies.imdb_title_id = ratings.imdb_title_id AND ratings.weighted_average_vote > 9;
```

The query plan for the second version of this query is as follows

```
                                    QUERY PLAN                                     
-----------------------------------------------------------------------------------
 Nested Loop  (cost=4.17..5747.76 rows=47 width=18)
   ->  Seq Scan on ratings  (cost=0.00..5363.19 rows=47 width=10)
         Filter: (weighted_average_vote > '9'::double precision)
   ->  Bitmap Heap Scan on movies  (cost=4.17..8.18 rows=1 width=28)
         Recheck Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
         ->  Bitmap Index Scan on movies_pkey  (cost=0.00..4.17 rows=1 width=0)
               Index Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
```

This query plan is very similar; The only difference is that instead of using a parallel scan over ratings to filter out values that are not greater than > x, it uses a sequential scan. 

#### B: Finding the crossover point
The query processor switches between the query plans when X=9, which happens to be the query I used above. This is likely because of the size of the result set is much smaller than previous queries (47 rows with a rating > 9  vs 523 rows with a rating > 8). With such a small result set (full order of magnitude smaller, and likely fits on one page), there is no longer a need to parallelize amoung workers.

#### C: Timing of the two queries
Average value over 5 queries for >9: 35.003
Average value over 5 queries for >8: 31.821

While the queries vary in execution time by more than 10% on average, I believe this is statistically irrelevant given the approximate deviation of +/- 6 milliseconds for different executions of the same query.

#### D: Best place to switch plans?
Yes, I do believe that this is the right place to switch plans. Considering the number of rows returned by the queries is different by a full order of magnitude, the fact that larger query ran slightly *faster* than the smaller query indicates that switching to a parallelized scan was the correct thing to do. When I try using an X that returns an even larger result set, the execution time gets longer and longer - if the query processor had not parallelized the scan, it would take *numWorkers longer to execute. 

### 2 
Query:
```SQL
SELECT names.name, ratings.weighted_average_vote, movies.title FROM movie_principals JOIN movies ON movie_principals.imdb_title_id = movies.imdb_title_id JOIN ratings ON movies.imdb_title_id = ratings.imdb_title_id JOIN names ON names.imdb_name_id = movie_principals.imdb_name_id;
```

The query plan for this statement with no indices is as follows
```
 Hash Join  (cost=196292.41..246195.51 rows=835493 width=40)
   Hash Cond: ((movie_principals.imdb_title_id)::text = (movies.imdb_title_id)::text)
   ->  Hash Join  (cost=20924.36..51014.49 rows=835493 width=24)
         Hash Cond: ((movie_principals.imdb_name_id)::text = (names.imdb_name_id)::text)
         ->  Seq Scan on movie_principals  (cost=0.00..16359.93 rows=835493 width=20)
         ->  Hash  (cost=15458.05..15458.05 rows=297705 width=24)
               ->  Seq Scan on names  (cost=0.00..15458.05 rows=297705 width=24)
   ->  Hash  (cost=173539.86..173539.86 rows=85855 width=46)
         ->  Gather  (cost=1000.44..173539.86 rows=85855 width=46)
               Workers Planned: 2
               ->  Nested Loop  (cost=0.44..163954.36 rows=35773 width=46)
                     ->  Parallel Seq Scan on ratings  (cost=0.00..4647.73 rows=35773 width=18)
                     ->  Bitmap Heap Scan on movies  (cost=0.44..4.45 rows=1 width=28)
                           Recheck Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
                           ->  Bitmap Index Scan on movies_pkey  (cost=0.00..0.44 rows=1 width=0)
                                 Index Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
```

Looking at this query plan, it's important to look at the order that the joins are performed in. It joins together the tables in a manner such that the total number of comparisons/joins it needs to do to get the final result set is minimized. By joining together the ratings and the movies first, it keeps the size of the sets it is joining together as small as possible for as long as possible. If the query processor were to join `movie_principals` with `movies` first, every other join would have to be performed on a set that has 850000 rows instead of on a set that has 82000 rows. Performing a join without an index on a set that large is intensive, so it tries to minimize the number of joins on a large dataset by joining the smallest tables first and the largest ones last. 

### Adding 1 index.

The index that I believe would improve the performance of this most would be adding an index (fk)  on `movie_principles.imdb_title_id` to `movies.imdb_title_id`. This is because `movie_principles` is by far the largest table in the database, and therefore the most costly join being performed currently. 

```sql
CREATE INDEX movie_principals_index_movie_title ON movie_principals USING hash (
  imdb_title_id
)
```

After making this change, the query plan was as follows:
```
Hash Join  (cost=196292.41..245404.21 rows=613287 width=40)
   Hash Cond: ((movie_principals.imdb_name_id)::text = (names.imdb_name_id)::text)
   ->  Hash Join  (cost=175368.05..211540.95 rows=613287 width=36)
         Hash Cond: ((movie_principals.imdb_title_id)::text = (movies.imdb_title_id)::text)
         ->  Seq Scan on movie_principals  (cost=0.00..16359.93 rows=835493 width=20)
         ->  Hash  (cost=173539.86..173539.86 rows=85855 width=46)
               ->  Gather  (cost=1000.44..173539.86 rows=85855 width=46)
                     Workers Planned: 2
                     ->  Nested Loop  (cost=0.44..163954.36 rows=35773 width=46)
                           ->  Parallel Seq Scan on ratings  (cost=0.00..4647.73 rows=35773 width=18)
                           ->  Bitmap Heap Scan on movies  (cost=0.44..4.45 rows=1 width=28)
                                 Recheck Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
                                 ->  Bitmap Index Scan on movies_pkey  (cost=0.00..0.44 rows=1 width=0)
                                       Index Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
   ->  Hash  (cost=15458.05..15458.05 rows=297705 width=24)
         ->  Seq Scan on names  (cost=0.00..15458.05 rows=297705 width=24)
```

Unfortunately, the query time was only slightly better than it was before; It appeared to be about 8% faster when I ran the query 5 times before adding the index and 5 times after.

It is worth noting that the query plan actually changed pretty significantly - Instead of doing the join between `movies` and `movie_principals` last, it actually did it second to last, and did the join between `names` and `movie_principals` last. 

I believe that the reason I did not see more improvement is because even though the index sped up the join for `movies` and `movie_principals`, we still had to do a really large join afterwards with `movie_principals` and `names` (over 850000 rows). I think that adding an index there as well will have a substantial impact on the query time as well. 


### 4 Using a different DBMS

#### CockroachDB 
I chose to try out CockroachDB for this because I've heard good things about it in conjunction with modern microservice and distributed system architectures. Unfortunately, it seems as though from a pure performance perspective when running a single local instance of cockroachDB, it's worse than postgres for every query I thought to try (not by a huge margin, but enough to really mess up this assignment). I believe this is because cockroachDB is moreso designed to be a scalable, distributed, easy solution, and offers features such as built in sharding and multi-region availability - and is less focused on pure performance of raw queries, instead focusing on performance at large scale.

##### The Query
```
SELECT movies.title FROM movies, ratings WHERE (movies.imdb_title_id = ratings.imdb_title_id) AND (ratings.weighted_average_vote > 9)
```
Query Plan in cockroach DB (click link to see diagram, the `EXPLAIN ANALYZE` keywords in cockroach db generate this link to an interactive query plan diagram)
```https://cockroachdb.github.io/distsqlplan/decode.html#eJycku9v2j4Qxt9__4rTvQJ9PeqEMTFLlWAr1dgodIC0nwi58Y1acuLMdli7iv99SkK70tF23bv4uXt8eT6-K_TfDQocfDwd9Ydj6I_7o0-fB9A4Gs7ms_ejJswGo8HrOaR2rcm3gg6G4Hg6OdkqDJwMOlt5-PBmMB1AY9uoU3W2rLqXWsHhddeu3oT--Aga17UfpFfngdRSrsnJFS3XNhB8LThvE7xsIsPMKhrLlDyKLxjhgmHubELeW1dKV1XDUF2g4Ax1lhehlBcME-sIxRVWk1HgXJ4ZmpJU5A44MlQUpDbVtbnTqXSXvToIMpzlMvMCniHDSREE9CLWi5HhmQzJOXmwRchLvfscGYYiN7e1TrfTQYaeDCVBr3W4FBC1eDnTB2kMBJ2SgKjbbUW8k3pcbBjW7u2v-yBXhCLasH-LF-2Pt4W-m-9Ym0BOQC--wd7iQojj0aQ_7z4GII7_BNB-cTc935O-Hbf4g-nje9P_Dl1k1ilypHYCL0rnYy17EJ6QW9FbqzNyB_EuQkPfQqMX_d88dOXCVp83bPaBif6SS7lAdEFJEbTNrtm0up0oLd8plRewpiRYp3-SgpRS6y5BGmMTGUgJiNsc3ulX90JsP2WFpuRzm3m6C3PvzbwkSGpF9Yt4W7iETp1NqjH1cVL5KkGRD3U1rg_DrCpVO37bHD3BHN81xw-a2ztmvlls_vsVAAD__-Z0pMg=```

For this query, it had an average execution time of 200ms. By comparison, postgres had a query time of ~30ms on average for the same query. Performance wise, postgres blows cockroachDB out of the water. 
```
                                    QUERY PLAN                                     
-----------------------------------------------------------------------------------
 Nested Loop  (cost=4.17..5747.76 rows=47 width=18)
   ->  Seq Scan on ratings  (cost=0.00..5363.19 rows=47 width=10)
         Filter: (weighted_average_vote > '9'::double precision)
   ->  Bitmap Heap Scan on movies  (cost=4.17..8.18 rows=1 width=28)
         Recheck Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
         ->  Bitmap Index Scan on movies_pkey  (cost=0.00..4.17 rows=1 width=0)
               Index Cond: ((imdb_title_id)::text = (ratings.imdb_title_id)::text)
```
(postgres query plan above)

It looks like the join operation just took longer in CockroachDB. I am unsure why this is the case. I suspect it may actually have something to do with the amount of memory allocated for pages/buffer. This is something I plan on investigating more on my own time,since I was planning on using CockroachDB in some personal projects after reading up about it but now I am less inclined to do so from a performance perspective.

If I had time to try using Redis or Memcached for this, I would, but the deadline is in 20 minutes, so I don't think I have time to get that set up. I will probably try this anyways tomorrow, and if the results from that are better than the ones from cockroachDB I will email in my additional findings.