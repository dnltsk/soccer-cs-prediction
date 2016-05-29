# soccer-cs-prediction
Prediction modelling playground for soccer championship data.

### data source
Data from [Fuﬂballdaten](http://www.fussballdaten.de) and [Transfermarkt](http://www.transfermarkt.co.uk). PostgresDB hosted at [heliohost](http://heliohost.org).

### content
Data contains currently 15 national teams[^1] with its 391 national players and its market values. 68 championship or quali matches from the last 10 years (2006-2016).

Dataset is descriped at [soccer-cs-stats](https://github.com/teeschke/soccer-cs-stats)

[^1]: list of national teams: BELGIUM, CROATIA, CZECH_REPUBLIC, ENGLAND, FRANCE, GERMANY, IRELAND, ITALY, POLAND, RUSSIA, SLOVAKIA, SPAIN, SWEDEN, SWITZERLAND, UKRAINE

### simple lm
Linear model of the team's plain market value on the pitch.

![goals-diff](lm/goals-diff.png "goals-diff")
![goals-home](lm/goals-home.png "goals-home")
![goals-guest](lm/goals-guest.png "goals-guest")


```{r}
new_data <- data.frame(h_complete_value=runif(1, min(matches$h_complete_value), max(matches$h_complete_value)), 
                       g_complete_value=runif(1, min(matches$g_complete_value), max(matches$g_complete_value)))
predicted_goals_diff <- predict(lm.diff, new_data)
predicted_goals_home <- predict(lm.home, new_data)
predicted_goals_guest <- predict(lm.guest, new_data)

cat(new_data$h_complete_value, "vs", new_data$g_complete_value, 
"->", predicted_goals_home, ":", predicted_goals_guest, "(", predicted_goals_diff, ")")

336.1862 vs 252.0455 -> 2.40252 : 1.823657 ( 0.6437858 )
376.0276 vs 105.698 -> 3.207236 : 1.057336 ( 2.068373 )
```