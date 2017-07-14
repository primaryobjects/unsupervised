//
// An example of using unsupervised learning in JavaScript to classify and categorize ETF stock and bond funds, using the K-means clustering algorithm.
//
// by Kory Becker
// http://primaryobjects.com
//

var csv = require('fast-csv'),
    clusterfck = require('clusterfck');

var etfs = {};

// Read the etf data.
csv
  .fromPath('data/vanguard-etf-clean.csv', { headers: true })
  .transform(function(obj) {
    return {
      ticker: obj.Ticker,
      assetClass: obj.AssetClass,
      expenseRatio: parseFloat(obj.ExpenseRatio),
      price: parseFloat(obj.Price),
      change1: parseFloat(obj.Change1),
      change2: parseFloat(obj.Change2),
      secYield: parseFloat(obj.SECYield),
      yearToDate: parseFloat(obj.YTD),
      year1: parseFloat(obj.Year1),
      year5: parseFloat(obj.Year5),
      year10: parseFloat(obj.Year10),
      inception: obj.Inception
    };
  })
  .on('data', function(data) {
    // For each row, add the complete object and an array of just the features that we're interested in clustering.
    var features = [ parseFloat(data.yearToDate), parseFloat(data.year1), parseFloat(data.year5), parseFloat(data.year10) ];

    // For a simple id, just sum the feature values.
    var id = features.reduce((a, b) => a + b, 0);

    // Add the data to our collection of etfs.
    etfs[id] = { data: data, features: features };
  })
  .on('end', function() {
    var features = [];

    // Get the array of features from each data row.
    for (var i=0; i < Object.keys(etfs).length; i++) {
      var id = Object.keys(etfs)[i];
      features.push(etfs[id].features);
    }

    // Calculate 5 clusters.
    var clusters = clusterfck.kmeans(features, 5);
    
    // Add cluster index (group) to each original data row by matching on the id.
    clusters.forEach(function(cluster, group) {
      cluster.forEach(function(row) {
        // Sum the values to use as an identifier for each etf row.
        var id = row.reduce((a, b) => a + b, 0);

        // Locate the row in the original data and mark the cluster index (1-based).
        etfs[id].data.group = group + 1;
      });
    });

    // Convert the hash to a sorted array (by cluster group) and write to a csv.
    var etfArr = Object.keys(etfs).map(function(key) { return etfs[key].data; })
    etfArr.sort(function(a, b) { return a.group - b.group });

    // Save output to csv.
    csv.writeToPath('results/train-js.csv', etfArr, { headers: true })
      .on('finish', function() {
        console.log('Results saved to results/train-js.csv');
    });
});