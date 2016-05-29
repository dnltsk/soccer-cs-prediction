require("properties")
require("RPostgreSQL")
require("ggplot2")
require("Cairo")

#
# see https://susanejohnston.wordpress.com/2012/08/09/a-quick-and-easy-function-to-plot-lm-results-in-r/
#
ggplotRegression <- function (fit) {
  ggplot(fit$model, aes_string(x = names(fit$model)[2], y = names(fit$model)[1])) + 
    geom_point() +
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

lm.diff  <- lm(diff_goals ~ h_complete_value + g_complete_value, data = matches.small)
lm.home  <- lm(home_goals ~ h_complete_value + g_complete_value, data = matches.small)
lm.guest <- lm(guest_goals ~ h_complete_value + g_complete_value, data = matches.small)

lm.diff  <- poly(diff_goals ~ h_complete_value + g_complete_value, data = matches.small, 2)
lm.home  <- lm(home_goals ~ h_complete_value + g_complete_value, data = matches.small)
lm.guest <- lm(guest_goals ~ h_complete_value + g_complete_value, data = matches.small)

ggplotRegression(lm.diff)
ggplotRegression(lm.home)
ggplotRegression(lm.guest)

ggplot(data.frame(actual=(jitter(matches.small$diff_goals, factor=.5)), 
                  predicted=jitter(predict(lm.diff), factor=.5)),
       aes(actual, predicted)) + 
  geom_point() + geom_smooth(lm.diff) + ggtitle("actual vs. predicted - GOALS DIFF") +
  theme(plot.title = element_text(lineheight=1, face="bold"))

ggplot(data.frame(actual=(jitter(matches.small$home_goals, factor=.5)), 
                  predicted=jitter(predict(lm.home), factor=.5)),
       aes(actual, predicted)) + 
  geom_point() + geom_smooth() + ggtitle("actual vs. predicted - GOALS HOME") +
  theme(plot.title = element_text(lineheight=1, face="bold"))

ggplot(data.frame(actual=(jitter(matches.small$guest_goals, factor=.5)), 
                  predicted=jitter(predict(lm.guest), factor=.5)),
       aes(actual, predicted)) + 
  geom_point() + geom_smooth() + ggtitle("actual vs. predicted - GOALS GUEST") +
  theme(plot.title = element_text(lineheight=1, face="bold"))

predict(lm.diff, data.frame(h_complete_value=200, g_complete_value=300))
predict(lm.home, data.frame(h_complete_value=200, g_complete_value=300))
predict(lm.guest, data.frame(h_complete_value=200, g_complete_value=300))
