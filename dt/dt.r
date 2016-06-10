require("properties")
require("RPostgreSQL")
require("ggplot2")
require("Cairo")
require("rpart")
require("rpart.plot")

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

setwd("/projects/soccer-cs-prediction/dt/")

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

matches.norm <- data.frame(goals = matches$home_goals,
                           h_complete_value = ((matches$h_complete_value - min(matches$h_complete_value)) / (max(matches$h_complete_value) - min(matches$h_complete_value))),
                           g_complete_value = ((matches$g_complete_value - min(matches$g_complete_value)) / (max(matches$g_complete_value) - min(matches$g_complete_value))),
                           h_keeper_value = ((matches$h_keeper_value - min(matches$h_keeper_value)) / (max(matches$h_keeper_value) - min(matches$h_keeper_value))),
                           h_defense_value = ((matches$h_defense_value - min(matches$h_defense_value)) / (max(matches$h_defense_value) - min(matches$h_defense_value))),
                           h_midfield_value = ((matches$h_midfield_value - min(matches$h_midfield_value)) / (max(matches$h_midfield_value) - min(matches$h_midfield_value))),
                           h_offense_value = ((matches$h_offense_value - min(matches$h_offense_value)) / (max(matches$h_offense_value) - min(matches$h_offense_value))),
                           g_keeper_value = ((matches$g_keeper_value - min(matches$g_keeper_value)) / (max(matches$g_keeper_value) - min(matches$g_keeper_value))),
                           g_defense_value = ((matches$g_defense_value - min(matches$g_defense_value)) / (max(matches$g_defense_value) - min(matches$g_defense_value))),
                           g_midfield_value = ((matches$g_midfield_value - min(matches$g_midfield_value)) / (max(matches$g_midfield_value) - min(matches$g_midfield_value))),
                           g_offense_value = ((matches$g_offense_value - min(matches$g_offense_value)) / (max(matches$g_offense_value) - min(matches$g_offense_value))))

matches.prep <- data.frame(goals = matches.norm$goals,
                           hmid_min_gmid = matches.norm$h_midfield_value - matches.norm$g_midfield_value,
                           hoff_min_gdef = matches.norm$h_offense_value - matches.norm$g_defense_value,
                           keeper = matches.norm$g_keeper_value)

matches.prep <- data.frame(goals = matches$home_goals,
                           hmid_min_gmid = matches$h_midfield_value - matches$g_midfield_value,
                           hmid_min_gdef = matches$h_midfield_value - matches$g_defense_value,
                           hoff_min_gdef = matches$h_offense_value - matches$g_defense_value,
                           keeper = matches$g_keeper_value)

dt.fit <- rpart(goals ~ hmid_min_gmid + hoff_min_gdef + keeper, 
             data=matches.prep, method="class")
plot(dt.fit)
printcp(dt.fit) # display the results
plotcp(dt.fit) # visualize cross-validation results
summary(dt.fit) # detailed summary of splits
plot(dt.fit, uniform=TRUE,
     main="Classification Tree for Kyphosis")
text(dt.fit, use.n=F, all=F, cex=.8)

pfit<- prune(dt.fit, cp=   dt.fit$cptable[which.min(dt.fit$cptable[,"xerror"]),"CP"])
plot(pfit, uniform=TRUE,
     main="Pruned Classification Tree for Kyphosis")
text(pfit, use.n=TRUE, all=TRUE, cex=.8)

predict(dt.fit, type = "vector") # level numbers
predict(dt.fit, type = "class")  # factor
predict(dt.fit, type = "matrix")

#
# comparisson of actual vs predicted match results
#
## DIFF


## GOALS HOME

Cairo(file="tree.png", bg="white", type="png", units="in", width=500/72, height=400/72, dpi=72)
  prp(dt.fit, main="classification tree")   
dev.off()
  
Cairo(file="goals.png", bg="white", type="png", units="in", width=500/72, height=500/72, dpi=72)
  ggplot(data.frame(actual=jitter(matches$home_goals, factor=.6), 
                    predicted=jitter(as.numeric(predict(dt.fit, data=matches, type = "class"))-1, factor=.6)),
         aes(actual, predicted)) + 
    geom_point() + #stat_smooth(method = "lm", col = "red") +
    theme(plot.title = element_text(lineheight=1, face="bold")) +
    ggtitle("Decision Tree: GOALS actual vs. predicted")
dev.off()

#
# export model
#
saveRDS(dt.fit, file = "dt.fit.rda")
