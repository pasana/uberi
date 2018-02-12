echo "Script starts"

intexit() {
    # Kill all subprocesses (all processes in the current process group)
    #kill -HUP -$$
    pkill -P $pid #-e
    pkill -P $$ #-e
}

hupexit() {
    # HUP'd (probably by intexit)
    echo
    echo "Interrupted"
    exit
}

trap hupexit HUP
trap intexit INT

sudo docker start configsvr10 configsvr11 configsvr12 router0 router1 router2 shard00 shard01 shard02 shard10 shard11 shard12 shard20 shard21 shard22 shard30 shard31 shard32
sleep 5
(mongo 172.18.0.30:27300 < giveRate.js)&
(python3 OrderProcessingServer.py) & pid=$!
(node server-chains.js)&
(firefox http://127.0.0.1:3000/map)&
(mongo 172.18.0.30:27300 < generateOrders.js)&

wait

echo "Script ends"

