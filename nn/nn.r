#
# WORK IN PROGRESS!!!
# 

#
# Inspired from http://www.r-bloggers.com/using-neural-networks-for-credit-scoring-a-simple-example/
#
install.packages("neuralnet")
require("neuralnet")

perc <- NROW(matches.nums)*0.75
trainset <- matches.nums[1:perc, ]
testset <- matches.nums[(perc+1):NROW(matches.nums), ]

# train
nn <- neuralnet(diff_goals ~ h_keeper_value + h_defense_value + h_midfield_value + h_offense_value + g_keeper_value + g_defense_value + g_midfield_value + g_offense_value,
                data=trainset, hidden=8, lifesign = "minimal", linear.output = FALSE, threshold = 0.1)
plot(nn)

# test
temp_test <- testset[, c("h_keeper_value", "h_defense_value", "h_midfield_value", "h_offense_value", "g_keeper_value", "g_defense_value", "g_midfield_value", "g_offense_value")]
test_result <- compute(nn, temp_test)

#report
results <- data.frame(actual = testset$diff_goals, 
                      prediction = test_result$net.result)
results
plot(results)