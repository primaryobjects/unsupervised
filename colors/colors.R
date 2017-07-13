packages <- c('flexclust')
if (length(setdiff(packages, rownames(installed.packages()))) > 0) {
  install.packages(setdiff(packages, rownames(installed.packages())))  
}
library(flexclust)

rgb2Num <- function(data) {
  # Maps RGB colors to a single value.
  result <- sapply(1:nrow(data), function(row) {
    color <- data[row,]
    (color$red * 256 * 256) + (color$green * 256) + color$blue
  })
  
  result
}

generateColors <- function(n) {
  # Generate a set of random colors.
  colors <- as.data.frame(t(sapply(1:n, function(i) {
    parts <- sample(0:255, 3)
    c(red = parts[1], green = parts[2], blue = parts[3], hex = rgb(parts[1], parts[2], parts[3], maxColorValue = 255))
  })), stringsAsFactors = F)

  # Convert to numeric values.
  colors$red <- as.numeric(colors$red)
  colors$green <- as.numeric(colors$green)
  colors$blue <- as.numeric(colors$blue)
  
  # Map each color to an x/y-coordinate for easy plotting.
  colors$x <- 1:nrow(colors)
  colors$y <- rgb2Num(colors)

  colors
}

predictColor <- function(model, centroids, data) {
  # Predict the assigned color by mapping the color to a cluster.
  data$group <- predict(model, newdata=data[,1:3])
  
  # Assign the label of the cluster.
  data$label <- sapply(1:nrow(data), function(row) {
    centroids[centroids$group == data[row, 'group'], ]$label
  })
  
  data
}

# Initialize a random seed for reproducibility.
set.seed(1234)

# Generate a set of random colors.
train <- generateColors(100)

# Plot the colors - the more data, the more apparent the gradient will be.
plot(x=train$x, y=train$y, col=train$hex, pch=19, cex=2, main='Colors', xlab='', ylab='2D Color', yaxt='n', xaxt='n')

# Run kmeans clustering on the data.
fit <- kmeans(train[,1:3], 3, nstart = 20)
train$group <- fit$cluster

# Convert centroid rgb values for plotting (align x to center of plot).
centroids <- as.data.frame(list(x = nrow(train) / 2, y = rgb2Num(as.data.frame(fit$centers)), group = 1:nrow(fit$centers)))

# Get red/green/blue for which cooresponds to which centroid.
centroids$label <- colnames(fit$centers)[apply(fit$centers, 1, which.max)]

# Plot the centroids on the graph.
points(x=centroids$x, y=centroids$y, cex=4, pch=4, lwd=3, col=centroids$label)

# Plot group number next to each centroid.
text(x=centroids$x, y=centroids$y, labels=centroids$group, cex=1, pos=3, font=2)

# Plot assigned group next to each point.
text(x=1:nrow(train), y=train$y, labels=train$group, cex=0.7, pos=3)

# Plot data, this time with the cluster, mapping each color to a group.
plot(x=train$x, y=train$group, col=train$hex, pch=19, cex=2, main='Colors', xlab='', ylab='2D Color', yaxt='n', xaxt='n')
text(x=train$x, y=train$group, labels=train$group, cex=0.7, pos=3)

# Predict on new data.
fit2 <- as.kcca(fit, data=train[,1:3])

# Generate new colors.
set.seed(Sys.time())
test <- generateColors(3)

test <- predictColor(fit2, centroids, test)

# Plot the predictions.
plot(x=test$x, y=test$y, col=test$hex, pch=19, cex=2, main='Colors', xlab='', ylab='2D Color', yaxt='n', xaxt='n')

# Label the colors with their prediction.
text(x=test$x, y=test$y, labels=test$label, cex=0.7, pos=3)
