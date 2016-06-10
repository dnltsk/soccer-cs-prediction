require("properties")
require("RPostgreSQL")
require("ggplot2")
require("Cairo")

setwd("/projects/soccer-cs-prediction/lm/")

dbConfig <- read.properties("../db-config.properties")
drv <- dbDriver("PostgreSQL")
con <- dbConnect(drv, dbname=dbConfig$dbname,host=dbConfig$host,port=dbConfig$port,user=dbConfig$user,password=dbConfig$pass) 

generalSelectStmt <- paste(readLines("../general-select-stmt.sql"), collapse="\n")
matches <- dbGetQuery(con, generalSelectStmt)

#
# interpred both game perspectived as a single game!!!
#
matches.switched <- data.frame(id = -1 * matches$id, 
                               date = matches$date,
                               home = matches$guest,
                               guest = matches$home,
                               home_goals = matches$guest_goals,
                               guest_goals = matches$home_goals,
                               diff_goals = -1 * matches$diff_goals,
                               h_complete_value = matches$g_complete_value,
                               g_complete_value = matches$h_complete_value,
                               h_keeper_value = matches$g_keeper_value,
                               h_defense_value = matches$g_defense_value,
                               h_midfield_value = matches$g_midfield_value,
                               h_offense_value = matches$g_offense_value,
                               g_keeper_value = matches$h_keeper_value,
                               g_defense_value = matches$h_defense_value,
                               g_midfield_value = matches$h_midfield_value,
                               g_offense_value = matches$h_offense_value)
matches <- rbind(matches, matches.switched)

team.lm.diff  <- lm(diff_goals ~ h_complete_value + g_complete_value, data = matches)
team.lm.home  <- lm(home_goals ~ h_complete_value + g_complete_value, data = matches)
team.lm.guest <- lm(guest_goals ~ h_complete_value + g_complete_value, data = matches)

#plot(team.lm.diff)
#plot(team.lm.home)
#plot(team.lm.guest)

#
# comparisson of actual vs predicted match results
#
Cairo(file="goals.png", bg="white", type="png", units="in", width=500/72, height=500/72, dpi=72)
  ggplot(data.frame(actual=jitter(matches$home_goals, factor=.6), 
                    predicted=jitter(round(predict(team.lm.home)), factor=.6)),
         aes(actual, predicted)) + 
    geom_point() + #stat_smooth(method = "lm", col = "red") +
    theme(plot.title = element_text(lineheight=1, face="bold")) +
    ggtitle("Linear Model: GOALS - actual vs. predicted")
dev.off()

#
# export lm
#
saveRDS(team.lm.home, file = "team.lm.home.rda")
saveRDS(team.lm.guest, file = "team.lm.guest.rda")
saveRDS(team.lm.diff, file = "team.lm.diff.rda")

#
# sample queries
#
new_data <- data.frame(h_complete_value=runif(5, min(matches$h_complete_value), max(matches$h_complete_value)), 
                            g_complete_value=runif(5, min(matches$g_complete_value), max(matches$g_complete_value)),
                            h_keeper_value=runif(5, min(matches$h_keeper_value), max(matches$h_keeper_value)), 
                            g_keeper_value=runif(5, min(matches$g_keeper_value), max(matches$g_keeper_value)))
new_data$predicted_goals_home_team <- predict(team.lm.home, new_data)
new_data$predicted_goals_guest_team <- predict(team.lm.guest, new_data)
new_data$predicted_goals_diff_team <- predict(team.lm.diff, new_data)

new_data

#cleanup
dbDisconnect(con)
