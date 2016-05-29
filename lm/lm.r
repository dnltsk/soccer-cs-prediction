require("properties")
require("RPostgreSQL")
require("ggplot2")
require("Cairo")

#
# see https://susanejohnston.wordpress.com/2012/08/09/a-quick-and-easy-function-to-plot-lm-results-in-r/
#
ggplotRegression <- function (fit) {
  ggplot(fit$model, aes_string(x = names(fit$model)[2], y = names(fit$model)[1])) + 
    geom_jitter(width = 0.25, height = 0.25) +
    stat_smooth(method = "lm", col = "red") +
    labs(title = paste("Adj R2 = ",signif(summary(fit)$adj.r.squared, 5),
                       "Intercept =",signif(fit$coef[[1]],5 ),
                       " Slope =",signif(fit$coef[[2]], 5),
                       " P =",signif(summary(fit)$coef[2,4], 5)))
}

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

lm.diff  <- lm(diff_goals ~ h_complete_value + g_complete_value, data = matches)
lm.home  <- lm(home_goals ~ h_complete_value + g_complete_value, data = matches)
lm.guest <- lm(guest_goals ~ h_complete_value + g_complete_value, data = matches)

#plot(lm.diff)
#plot(lm.home)
#plot(lm.guest)

#
# comparisson of actual vs predicted match results
#
Cairo(file="goals-diff.png", bg="white", type="png", units="in", width=500/72, height=500/72, dpi=72)
  ggplot(data.frame(actual=jitter(matches$diff_goals, factor=.25), 
                    predicted=jitter(predict(lm.diff), factor=.25)),
         aes(actual, predicted)) + 
    geom_point() + stat_smooth(method = "lm", col = "red") + 
    theme(plot.title = element_text(lineheight=1, face="bold")) +
    ggtitle("actual vs. predicted - GOALS DIFF (home - guest)")
dev.off()

Cairo(file="goals-home.png", bg="white", type="png", units="in", width=500/72, height=500/72, dpi=72)
  ggplot(data.frame(actual=jitter(matches$home_goals, factor=.25), 
                    predicted=jitter(predict(lm.home), factor=.25)),
         aes(actual, predicted)) + 
    geom_point() + stat_smooth(method = "lm", col = "red") +
    theme(plot.title = element_text(lineheight=1, face="bold")) +
    ggtitle("actual vs. predicted - GOALS HOME")
dev.off()

Cairo(file="goals-guest.png", bg="white", type="png", units="in", width=500/72, height=500/72, dpi=72)
  ggplot(data.frame(actual=jitter(matches$guest_goals, factor=.25), 
                    predicted=jitter(predict(lm.guest), factor=.25)),
         aes(actual, predicted)) + 
    geom_point() + stat_smooth(method = "lm", col = "red") + 
    theme(plot.title = element_text(lineheight=1, face="bold")) +
    ggtitle("actual vs. predicted - GOALS GUEST")
dev.off()

#
# sample queries
#
new_data <- data.frame(h_complete_value=runif(5, min(matches$h_complete_value), max(matches$h_complete_value)), 
                       g_complete_value=runif(5, min(matches$g_complete_value), max(matches$g_complete_value)))
new_data$predicted_goals_home <- predict(lm.home, new_data)
new_data$predicted_goals_guest <- predict(lm.guest, new_data)
new_data$predicted_goals_diff <- predict(lm.diff, new_data)

new_data

#cleanup
dbDisconnect(con)
