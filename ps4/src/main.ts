import { sample1 } from "./sampleInput";
import { Client } from "pg";
import { subset } from "./subset";
var hash = require("object-hash");

const QUERY = `select * from principals join names on principals.nconst=names.nconst limit 2500;`;
const DATABASE = `imdb`;
const PORT = 5432;

let powerset: Map<number, Array<string[]>>;

const client = new Client({
  database: DATABASE,
  port: PORT,
});

/**
 * Represents a Functional Dependency.
 *
 * For example, the FD
 *  `ABC -> E`
 * would translate to:
 *  `{keys: ["A", "B", "C"], value: "E"}`
 *
 */
interface FD {
  keys: Array<string>;
  value: string;
}

/**
 * Checks if a given FD is "trivial", i.e. if we have already
 * confirmed the FD `A -> C`, then the FD `AB -> C` is trivial
 * because A unioned with anything will be a valid FD in
 * relationsip to C - it's not minimal
 * @param fdToCheck The FD to check for triviality
 * @param existingFDs The array of already existing/confirmed FDs.
 */
const isRedundantFD = (fdToCheck: FD, existingFDs: Array<FD>): boolean => {
  let isRedundant = false;
  // FIXME if we have performance issues, convert this to a classic for loop and break if we find redundancy

  for (let i = 0; i < existingFDs.length; i++) {
    const existingFD = existingFDs[i];

    if (isRedundant) {
      true;
    }

    if (
      isSubset(existingFD.keys, fdToCheck.keys) &&
      fdToCheck.value === existingFD.value
    ) {
      isRedundant = true;
    }
  }
  return isRedundant;
};

/**
 * Checks if the given FD applies to the provided set of data.
 * @param fd The FD to check
 * @param data The dataset to check the FD on
 */
const doesFDHold = (
  fd: FD,
  data: Array<any>,
  confirmedFDs: Array<FD>
): boolean => {
  const map = new Map<string, any>();

  for (let i = 0; i < data.length; i++) {
    const row = data[i];
    const keys = fd.keys.map((key) => row[key]);
    const hashedKeys = hash(keys);

    const value = hash(row[fd.value]);
    if (map.has(hashedKeys)) {
      if (map.get(hashedKeys) !== value) {
        return false;
      }
    } else {
      map.set(hashedKeys, value);
    }
  }

  return true;
};

/**
 * Generates an array of possible FDs for the provided size and
 * fieldset - they may not hold up against actual data.
 * @param fields The array of fieldnames on a table
 * @param size The keysize to use for the generated FDs.
 */
const generatePotentialFDs = (
  fields: Array<string>,
  size: number
): Array<FD> => {
  const output: Array<FD> = [];

  if (!powerset) {
    powerset = generatePowerset(fields);
  }
  const keySets = powerset.get(size) as string[][];

  keySets.forEach((keys) => {
    fields
      .filter((field) => !keys.includes(field))
      .map((value) => {
        output.push({ keys, value });
      });
  });

  return output;
};

/**
 * Determines if a passed in array/set of values is a proper subset of a 2nd array/set.
 *
 * @param setToCheck The set of values to check
 * @param superset The superset to compare the potential subset to
 */
const isSubset = (
  setToCheck: Array<string>,
  superset: Array<string>
): boolean => {
  return setToCheck.every((value) => superset.includes(value));
};

const generatePowerset = (
  columns: Array<string>
): Map<number, Array<string[]>> => {
  const output = new Map<number, Array<string[]>>();
  columns
    .reduce(
      (subsets: any, value: any) =>
        subsets.concat(subsets.map((set: string) => [value, ...(set as any)])),
      [[]]
    )
    .forEach((set: Array<string>) => {
      if (!output.has(set.length)) {
        output.set(set.length, []);
      }

      output.get(set.length)?.push(set);
    });

  return output;
};

/**
 * Given an FD, pretty formats it for printing
 * @param fd FD to format
 */
const formatFD = (fd: FD): string => {
  return `${fd.keys} -> ${fd.value}`;
};

const main = async (): Promise<void> => {
  await client.connect();
  const res = await client.query(QUERY);

  // string field names from the db query
  let fields = res.fields.map((field) => field.name);

  const index = fields.indexOf("isAdult");
  if (index > -1) {
    fields.splice(index, 1);
  }
  const rows = res.rows;

  const confirmedFDs: Array<FD> = [];

  for (let i = 1; i < fields.length - 1; i++) {
    console.log(i);
    const potentialFDs = generatePotentialFDs(fields, i);

    potentialFDs.forEach((potentialFD) => {
      // console.log(formatFD(potentialFD));
      if (
        !isRedundantFD(potentialFD, confirmedFDs) &&
        doesFDHold(potentialFD, rows, confirmedFDs)
      ) {
        console.log(formatFD(potentialFD));
        confirmedFDs.push(potentialFD);
      }
    });
  }
  console.log(confirmedFDs.map(formatFD));

  // close down db connection
  await client.end();
};

main();
