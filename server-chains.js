var express = require('express');
var app = express();
var MongoClient = require('mongodb').MongoClient;
var url = 'mongodb://172.18.0.30:27300/';
var fs = require('fs');

MongoClient.connect(url, function (err, db) {
    app.route('/map').get(function (req, res) {
        fs.readFile('./map.html', function (err, html) {
            if (err) {
                throw err; 
            }       
            res.writeHeader(200, {"Content-Type": "text/html"});  
            res.write(html);  
            res.end();
        });
    });
    app.route('/drivers').get(function (req, res) {
        db.db('london').collection('drivers').find().map(function (item) {
            return {
                Longitude: item.loc.coordinates[1], Latitude:
                    item.loc.coordinates[0]
            };
        }).toArray(function (err, docs) {
            res.jsonp(docs);
        });
    });


    var server = app.listen(3000, function () {
        console.log('Server running at http://127.0.0.1:3000/');
    });

});

