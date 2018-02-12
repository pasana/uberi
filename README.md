# uberi

Requirements:
  * JS: 
    - express 
    - mongodb
  * Python: 
    - MongoClient

Data from: https://www.doogal.co.uk/london_postcodes.php

For the first time:
`sudo ./init.sh`

Start with
`sudo ./run.sh`

Add new drivers:
  ```
  mongo 172.18.0.30:27300
  
  use london;
  db.loadServerScripts();
  newDrivers(10);
  ```

Generate more orders:

  ```
  mongo 172.18.0.30:27300
  
  use london;
  db.loadServerScripts();
  generateOrders(usrPerMin, usrNum);
  ```
