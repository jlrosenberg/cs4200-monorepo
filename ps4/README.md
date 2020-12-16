## Tane Implementation

This is an implementation of the Tane Algorithm, an efficient method of identifying functional dependencies in a table.

##### What are functional dependencies?

A functional dependency (FD) is a relationship between two attributes. For any relation R, attribute Y is functionally dependent on attribute X, if for every valid instance of X, that value of X uniquely determines the value of Y

### Installation Instructions

To install all necessary dependencies, run `npm install` in this directory.

### Database Configuration

For this assignment, I used the already existing imdb database from ps3 for data. To generate large and more complex tables, I did several joins to get >20 attributes.

### Running the Script

To run the script, use the command `npm start`

### Additional Resources

Paper on Tane Algorithm. [here](https://dm-gatech.github.io/CS8803-Fall2018-DML-Papers/tane.pdf)
