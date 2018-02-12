use london

db.postcodes.find().forEach(function(doc) {doc.loc = { type: "Point", coordinates: [doc.Latitude, doc.Longitude]};  db.postcodes.save(doc);});

db.postcodes.createIndex( { loc : "2dsphere" } )
db.clients.createIndex( { start : "2dsphere" } )
db.clients.createIndex( { end : "2dsphere" } )
db.drivers.createIndex( { loc : "2dsphere" } )

db.system.js.save(
   {
     _id: "generateOrders",
     value: function(usrPerMin, usrNum) {
         var sleep_time = 60000/usrPerMin;
         for (i=1; i<=usrNum; i++) {
             db.clients.insert({
              start: db.postcodes.aggregate([{$sample: {size: 1}}]).toArray()[0]['loc'],
              end: db.postcodes.aggregate([{$sample: {size: 1}}]).toArray()[0]['loc'],
              created: new Date(),
              status: "new"});
              sleep(sleep_time);
         }
      }
   }
)


db.system.js.save(
   {
     _id: "newDrivers",
     value: function(Num) {
         for (i=1; i<=Num; i++) {
             db.drivers.insert({
              loc: db.postcodes.aggregate([{$sample: {size: 1}}]).toArray()[0]['loc'],
              rate: 0,
              status: "free"});
         }
      }
   }
)

db.system.js.save(
   {
     _id: "GiveRate",
     value: function() {
         while(true) {
             db.clients.find({status: "done"}).forEach(function(doc) {
                 driver = db.drivers.findOne({'_id': doc.driver});
                 var rate = Math.round(_rand()*10 % 5);
                 if (rate>0 & _rand()*10>5) {
                     doc.rate = rate;
                 }
                 doc.status = "rated";
                 db.clients.save(doc);
                 db.drivers.save(driver);
             });
            rates = db.clients.aggregate(
               [
                 {
                   $group:
                     {
                       _id: "$driver",
                       avgRate: { $avg: "$rate"}
                     }
                 }
               ]
            ).toArray()

            rates.forEach(
               function(x)
               { 
                 db.drivers.update({_id: x._id},{$set:{rate: x.avgRate}}); 
               }
            )
         }
      }
   })


db.loadServerScripts();
newDrivers(10);
