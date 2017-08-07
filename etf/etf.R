#
# An example of using unsupervised learning in R to classify and categorize ETF stock and bond funds, using the K-means clustering algorithm.
#
# by Kory Becker
# http://primaryobjects.com
#

packages <- c('flexclust', 'caTools')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}
library(flexclust)
library(caTools)

# Read the data set. Source: https://investor.vanguard.com/mutual-funds/list#/etf/name/month-end-returns
data <- read.csv2('data/vanguard-etf.tsv', header=T, sep='\t', stringsAsFactors=F)

# Convert the percentage string columns into numeric values.
data[,3] <- as.numeric(sub("%", "", data[,3]))
data[,4] <- as.numeric(sub('$', '', as.character(data[,4]), fixed=TRUE))
data[,5] <- as.numeric(sub('$', '', as.character(data[,5]), fixed=TRUE))
data[,6] <- as.numeric(sub("%", "", data[,6]))
data[,7] <- as.numeric(sub("%B", "", data[,7]))
data[,8] <- as.numeric(sub("%", "", data[,8]))
data[,9] <- as.numeric(sub("%", "", data[,9]))
data[,10] <- as.numeric(sub("%", "", data[,10]))
data[,11] <- as.numeric(sub("%", "", data[,11]))

# Replace NA with 0.
data[is.na(data)] <- 0

# Save a copy of the cleansed data.
write.csv(data, file='data/vanguard-etf-clean.csv')

# Initialize a random seed for reproducibility.
set.seed(123)

# Split a train and test set.
splitData <- sample.split(data$Ticker, SplitRatio = .75)
train <- subset(data, splitData == TRUE)
test <- subset(data, splitData == FALSE)

# Run kmeans clustering on the data.
fit <- kmeans(train[,8:11], 5, nstart = 20)
train$group <- fit$cluster

# Display the funds, sorted by their assigned group.
train[order(train$group),]

# Manually label the clusters with names (guessed by looking at the resulting clusters).
centroids <- as.data.frame(fit$centers)
centroids$group <- 1:nrow(centroids)
centroids$label <- c('Stock', 'StockBigGain', 'Bond', 'SmallMidLargeCap', 'International')

# Set assigned label on training data.
train$label <- centroids$label[train$group]

# Save the result to a csv file.
write.csv(train[order(train$group),], file='results/train.csv')

# Predict on new data.
fit2 <- as.kcca(fit, data=train[,8:11])

# Predict the assigned color by mapping the color to a cluster.
test$group <- predict(fit2, newdata=test[,8:11])

# Assign the label of the cluster.
test$label <- sapply(1:nrow(test), function(row) {
  centroids[centroids$group == test[row, 'group'], ]$label
})

# Save the result to a csv file.
write.csv(test[order(test$group),], file='results/test.csv')
