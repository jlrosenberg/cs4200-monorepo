import { Client } from "pg";
import { create } from "ts-node";
import fs from "fs";
import readline from "readline";
import stream, { Stream } from "stream";

import format from "pg-format";
import { isReturnStatement, nodeModuleNameResolver } from "typescript";

const BATCH_SIZE = 20000;

const client = new Client({
  database: "imdb",
  port: 5432,
});

const createAndImportNames = async () => {
  await client.query(`CREATE TABLE names (
    nconst varchar(256) PRIMARY KEY,
    primaryName text,
    birthYear integer,
    deathYear integer,
    primaryProfession text,
    knownForTitles text
   );`);
  console.log("Created names table");
  await client.query(
    `COPY names(nconst, primaryName, birthYear, deathYear, primaryProfession, knownForTitles) FROM '/Users/josh/Documents/code/cs4200-monorepo/ps3/name.basics.tsv' DELIMITER E'\t' CSV HEADER NULL '\N';`
  );

  console.log("Imported names");
};

const readMovieNames = async () => {
  const instream = fs.createReadStream(
    "/Users/josh/Documents/code/cs4200-monorepo/ps3/title.basics.tsv"
  );
  const rl = readline.createInterface(instream, null);

  let rowsToInsert: Array<Array<string>> = [];

  rl.on("line", async (line) => {
    // const fixedNulls = line.replaceAll('\N', "NULL");
    const lineValues = line.split("\t");
    const dataToInsert = [];
    lineValues.forEach((l) => {
      if (l.includes(`\N`)) {
        // console.log("ITS NULL");
        dataToInsert.push(null);
      } else {
        dataToInsert.push(l);
      }
    });
    const genresString = dataToInsert.pop();
    dataToInsert.push(`{${genresString}}`);
    rowsToInsert.push(dataToInsert);

    if (rowsToInsert.length >= BATCH_SIZE) {
      let query1 = format(
        "INSERT INTO titles (tconst, titleType, primaryTitle, originalTitle, isAdult, startYear, endYear, runtimeMinutes, genres) VALUES %L",
        rowsToInsert
      );
      rowsToInsert = [];

      // console.log(query1);
      let res = await client.query(query1).catch((e) => {
        console.error(e);
      });
      console.log(res);
      console.log("Query executed");
    }
  });
};

const readAkas = async () => {
  const instream = fs.createReadStream(
    "/Users/josh/Documents/code/cs4200-monorepo/ps3/title.akas.tsv"
  );
  const rl = readline.createInterface(instream, null);

  let rowsToInsert: Array<Array<string>> = [];
  let count = 0;
  let first = true;

  rl.on("line", async (line) => {
    // const fixedNulls = line.replaceAll('\N', "NULL");
    if (first) {
      first = !first;
      return;
    }
    const lineValues = line.split("\t");
    const dataToInsert = [];
    lineValues.forEach((l) => {
      if (l.includes(`\N`)) {
        // console.log("ITS NULL");
        dataToInsert.push(null);
      } else {
        dataToInsert.push(l);
      }
    });
    const str1 = dataToInsert.pop();
    const arr1 = dataToInsert.pop();
    const arr2 = dataToInsert.pop();
    dataToInsert.push(`{${arr2}}`);
    dataToInsert.push(`{${arr1}}`);
    dataToInsert.push(str1);

    rowsToInsert.push(dataToInsert);

    if (rowsToInsert.length >= BATCH_SIZE) {
      let query1 = format(
        "INSERT INTO akas (tconst, ordering, title, region, language, types, attributes, isOriginalTitle) VALUES %L",
        rowsToInsert
      );
      rowsToInsert = [];
      // console.log(query1);
      let res = await client.query(query1).catch((e) => {
        console.error(e);
      });
      // console.log(res);
      console.log(`Query executed ${count}`);
      count++;
    }
  });
};

const readCrew = async () => {
  const instream = fs.createReadStream(
    "/Users/josh/Documents/code/cs4200-monorepo/ps3/title.crew.tsv"
  );
  const rl = readline.createInterface(instream, null);

  let writersRowsToInsert: Array<Array<string>> = [];
  let directorsRowsToInsert: Array<Array<string>> = [];

  let count = 0;
  let first = true;

  rl.on("line", async (line) => {
    // const fixedNulls = line.replaceAll('\N', "NULL");
    if (first) {
      first = !first;
      return;
    }
    const lineValues = line.split("\t");
    const dataToInsert = [];
    lineValues.forEach((l) => {
      if (l.includes(`\N`)) {
        // console.log("ITS NULL");
        dataToInsert.push(null);
      } else {
        dataToInsert.push(l);
      }
    });
    const writers = dataToInsert.pop();
    const directors = dataToInsert.pop();
    const tconst = dataToInsert[0];

    if (!(writers === null)) {
      writers.split(",").forEach((writer) => {
        writersRowsToInsert.push([tconst, writer]);
      });
    }

    if (!(directors === null)) {
      directors.split(",").forEach((director) => {
        directorsRowsToInsert.push([tconst, director]);
      });
    }

    // rowsToInsert.push(dataToInsert);

    if (directorsRowsToInsert.length >= BATCH_SIZE) {
      let query1 = format(
        "INSERT INTO directors (tconst, nconst) VALUES %L",
        directorsRowsToInsert
      );
      directorsRowsToInsert = [];
      // console.log(query1);
      let res = await client.query(query1).catch((e) => {
        console.error(e);
      });
      // console.log(res);
      console.log(`Director Query executed ${count}`);
      count++;
    }

    if (writersRowsToInsert.length >= BATCH_SIZE) {
      let query1 = format(
        "INSERT INTO writers (tconst, nconst) VALUES %L",
        writersRowsToInsert
      );
      writersRowsToInsert = [];
      // console.log(query1);
      let res = await client.query(query1).catch((e) => {
        console.error(e);
      });
      // console.log(res);
      console.log(`Writer Query executed ${count}`);
      count++;
    }
  });
};

const readPrincipals = async () => {
  const instream = fs.createReadStream(
    "/Users/josh/Documents/code/cs4200-monorepo/ps3/title.principals.tsv"
  );
  const rl = readline.createInterface(instream, null);

  let rowsToInsert: Array<Array<string>> = [];
  let count = 0;
  let first = true;

  rl.on("line", async (line) => {
    // const fixedNulls = line.replaceAll('\N', "NULL");
    if (first) {
      first = !first;
      return;
    }
    const lineValues = line.split("\t");
    const dataToInsert = [];
    lineValues.forEach((l) => {
      if (l.includes(`\N`)) {
        // console.log("ITS NULL");
        dataToInsert.push(null);
      } else {
        dataToInsert.push(l);
      }
    });

    rowsToInsert.push(dataToInsert);

    if (rowsToInsert.length >= BATCH_SIZE) {
      let query1 = format(
        "INSERT INTO principals (tconst, ordering, nconst, category, job, characters) VALUES %L",
        rowsToInsert
      );
      rowsToInsert = [];
      // console.log(query1);
      let res = await client.query(query1).catch((e) => {
        console.error(e);
      });
      // console.log(res);
      console.log(`Query executed ${count}`);
      count++;
    }
  });
};

const run = async () => {
  await client.connect();
  // await createAndImportNames();
  // const res = await client.query("SELECT * FROM names LIMIT 10"
  // await readMovieNames();
  await readCrew();
  // console.log(res.rows); // Hello world!
  // await client.end();
};

run();
