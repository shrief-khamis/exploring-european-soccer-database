library(RSQLite)

#connecting to the database
my_db <- dbConnect(SQLite(), dbname="database.sqlite")

#extracting tables as dataframes
country <- as.data.frame(tbl(my_db, sql("SELECT * FROM Country")))
match <- as.data.frame(tbl(my_db, sql("SELECT * FROM Match")))
player <- as.data.frame(tbl(my_db, sql("SELECT * FROM Player")))
team <- as.data.frame(tbl(my_db, sql("SELECT * FROM Team")))
league <- as.data.frame(tbl(my_db, sql("SELECT * FROM League")))

#exporting the dataframes to csv files
write.csv(country,"country.csv", row.names = FALSE)
write.csv(match,"match.csv", row.names = FALSE)
write.csv(player,"player.csv", row.names = FALSE)
write.csv(team,"team.csv", row.names = FALSE)
write.csv(league,"league.csv", row.names = FALSE)
