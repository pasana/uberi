sudo docker build -t ubumon .
docker network create --subnet=172.18.0.0/16 UberiNet

#----config servers----
sudo docker run -d --name configsvr10 --net UberiNet --ip 172.18.0.10 ubumon mongod --configsvr --replSet mongors1cnf --port 27200 --bind_ip 172.18.0.10
sudo docker run -d --name configsvr11 --net UberiNet --ip 172.18.0.11 ubumon mongod --configsvr --replSet mongors1cnf --port 27210 --bind_ip 172.18.0.11
sudo docker run -d --name configsvr12 --net UberiNet --ip 172.18.0.12 ubumon mongod --configsvr --replSet mongors1cnf --port 27220 --bind_ip 172.18.0.12

sleep 5

sudo docker exec -it configsvr10 bash -c "echo 'rs.initiate({_id: \"mongors1cnf\",configsvr: true, members: [{ _id : 0, host : \"172.18.0.10:27200\" },{ _id : 1, host : \"172.18.0.11:27210\" }, { _id : 2, host : \"172.18.0.12:27220\" }]})' | mongo 172.18.0.10:27200"

#----routers----
sudo docker run -d --name router0 --net UberiNet --ip 172.18.0.30 ubumon mongos --configdb mongors1cnf/172.18.0.10:27200,172.18.0.11:27210,172.18.0.12:27220 --port 27300 --bind_ip 172.18.0.30
sudo docker run -d --name router1 --net UberiNet --ip 172.18.0.31 ubumon mongos --configdb mongors1cnf/172.18.0.10:27200,172.18.0.11:27210,172.18.0.12:27220 --port 27301 --bind_ip 172.18.0.31
sudo docker run -d --name router2 --net UberiNet --ip 172.18.0.32 ubumon mongos --configdb mongors1cnf/172.18.0.10:27200,172.18.0.11:27210,172.18.0.12:27220 --port 27302 --bind_ip 172.18.0.32

#----shard 0----
sudo docker run -d --name shard00 --net UberiNet --ip 172.18.0.100 ubumon mongod --shardsvr --replSet rs0 --port 27100 --bind_ip 172.18.0.100
sudo docker run -d --name shard01 --net UberiNet --ip 172.18.0.101 ubumon mongod --shardsvr --replSet rs0 --port 27101 --bind_ip 172.18.0.101
sudo docker run -d --name shard02 --net UberiNet --ip 172.18.0.102 ubumon mongod --shardsvr --replSet rs0 --port 27102 --bind_ip 172.18.0.102

sleep 5

sudo docker exec -it shard00 bash -c "echo 'rs.initiate({_id : \"rs0\", members: [{ _id : 0, host : \"172.18.0.100:27100\" },{ _id : 1, host : \"172.18.0.101:27101\" },{ _id : 2, host : \"172.18.0.102:27102\" }]})' | mongo 172.18.0.100:27100"

sleep 5

sudo docker exec -it router0 bash -c "echo 'sh.addShard(\"rs0/172.18.0.100:27100\")' | mongo 172.18.0.30:27300"

#----shard 1----
sudo docker run -d --name shard10 --net UberiNet --ip 172.18.0.110 ubumon mongod --shardsvr --replSet rs1 --port 27110 --bind_ip 172.18.0.110
sudo docker run -d --name shard11 --net UberiNet --ip 172.18.0.111 ubumon mongod --shardsvr --replSet rs1 --port 27111 --bind_ip 172.18.0.111
sudo docker run -d --name shard12 --net UberiNet --ip 172.18.0.112 ubumon mongod --shardsvr --replSet rs1 --port 27112 --bind_ip 172.18.0.112

sleep 5

sudo docker exec -it shard10 bash -c "echo 'rs.initiate({_id : \"rs1\", members: [{ _id : 0, host : \"172.18.0.110:27110\" },{ _id : 1, host : \"172.18.0.111:27111\" },{ _id : 2, host : \"172.18.0.112:27112\" }]})' | mongo 172.18.0.110:27110"

sleep 5

sudo docker exec -it router0 bash -c "echo 'sh.addShard(\"rs1/172.18.0.110:27110\")' | mongo 172.18.0.30:27300"

#----shard 2----
sudo docker run -d --name shard20 --net UberiNet --ip 172.18.0.120 ubumon mongod --shardsvr --replSet rs2 --port 27120 --bind_ip 172.18.0.120
sudo docker run -d --name shard21 --net UberiNet --ip 172.18.0.121 ubumon mongod --shardsvr --replSet rs2 --port 27121 --bind_ip 172.18.0.121
sudo docker run -d --name shard22 --net UberiNet --ip 172.18.0.122 ubumon mongod --shardsvr --replSet rs2 --port 27122 --bind_ip 172.18.0.122

sleep 5

sudo docker exec -it shard20 bash -c "echo 'rs.initiate({_id : \"rs2\", members: [{ _id : 0, host : \"172.18.0.120:27120\" },{ _id : 1, host : \"172.18.0.121:27121\" },{ _id : 2, host : \"172.18.0.122:27122\" }]})' | mongo 172.18.0.120:27120"

sleep 5

sudo docker exec -it router0 bash -c "echo 'sh.addShard(\"rs2/172.18.0.120:27120\")' | mongo 172.18.0.30:27300"

#----shard 3----
sudo docker run -d --name shard30 --net UberiNet --ip 172.18.0.130 ubumon mongod --shardsvr --replSet rs3 --port 27130 --bind_ip 172.18.0.130
sudo docker run -d --name shard31 --net UberiNet --ip 172.18.0.131 ubumon mongod --shardsvr --replSet rs3 --port 27131 --bind_ip 172.18.0.131
sudo docker run -d --name shard32 --net UberiNet --ip 172.18.0.132 ubumon mongod --shardsvr --replSet rs3 --port 27132 --bind_ip 172.18.0.132

sleep 5

sudo docker exec -it shard30 bash -c "echo 'rs.initiate({_id : \"rs3\", members: [{ _id : 0, host : \"172.18.0.130:27130\" },{ _id : 1, host : \"172.18.0.131:27131\" },{ _id : 2, host : \"172.18.0.132:27132\" }]})' | mongo 172.18.0.130:27130"

sleep 5

sudo docker exec -it router0 bash -c "echo 'sh.addShard(\"rs3/172.18.0.130:27130\")' | mongo 172.18.0.30:27300"

sleep 5

mongo 172.18.0.30:27300 < enableSharding.js

mongoimport --host 172.18.0.30 --port 27300 -d london -c postcodes --type csv --file London\ postcodes.csv --headerline

mongo 172.18.0.30:27300 < mongoInit.js
