# exploring-european-soccer-database
Exploring the European soccer database using PostgreSQL

The European soccer database is a database of 11 European leagues over 8 seasons.
The database contains 7 tables with various information about leagues, countries, players, teams, matches...etc.

I used a subset of the dataset, I only used 5 tables, and I cut down one of them (the match table) to just a handful of columns.
You can find the dataset here: https://www.kaggle.com/hugomathien/soccer

The dataset file is .sqlite, I used R to extract the tables and saved them as csv files,
I then used Excel and Power Query to adjust the date formats, and to reduce the "match" table to the desired columns,
I then used pgAdmin 4 to construct the database and the tables,
I used pgAdmin 4 and VScode with postgreSQL extension in writing and excuting the queries.
