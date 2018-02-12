sh.enableSharding('london')
sh.shardCollection('london.postcodes', {Latitude: "hashed"})
