import os
import time
import operator
from Logger import Logger
import requests
from pymongo import MongoClient


class ThreadedServer:
    def __init__(self):
        self.client = MongoClient("172.18.0.30", 27300)
        self.db = self.client["london"]
        self.log = Logger().logger
        self.log.info('Matching Server started')

    def listen(self):
        while True:
            clients = self.db.clients.find({"status": "new"})
            if self.db.drivers.find({"status": "free"}).count() == 0 and clients.count() > 0:
                self.log.info("No free drivers. Waiting for 5s...")
                time.sleep(5)
                continue
            if clients.count() == 0:
                self.log.info("No orders. Waiting for 1s...")
                time.sleep(1)
                continue
            for client in clients[:10]:
                self.log.info("Searching a car for %s at %s" % (str(client['_id']),
                                                                "%.3f, %.3f"%tuple(client['start']['coordinates'])))
                driver = self.choose_driver(client)
                if not driver:
                    self.log.warning("Can't find a driver for %s"%str(client['_id']))
                    continue

                pid = os.fork()
                if pid == 0:  # child
                    self.procces_order(client, driver)
                    os._exit(0)
                else:  # parent
                    pass

    def choose_driver(self, client):
        drivers = [driver for driver in self.db.drivers.aggregate(
            [{
                "$geoNear": {
                    "near": client['start']['coordinates'],
                    "distanceField": "dist",
                    "spherical": True,
                    "limit": 2,
                    "query": {"status": "free"}
                }
            }])]
        if len(drivers) > 0:
            try:
                filtered_drivers = list(filter(lambda x: x['rate'], drivers))
                good_drivers = list(filter(lambda x: x['rate']>4, filtered_drivers))
                if good_drivers:
                    driver = list(sorted(good_drivers, key=lambda x: x['rate'], reverse=True))[0]
                else:
                    driver = drivers[0]
            except:
                driver = drivers[0]
            self.log.info("Chosen driver %s for client %s"%(str(driver['_id']), str(client['_id'])))
            self.db.clients.update({'_id': client['_id']},
                                   {"$set": {"status": "waiting", "driver": driver['_id']}})
            self.db.drivers.update({'_id': driver['_id']}, {"$set": {"status": "coming", "client": client['_id']}})
            return driver
        return None

    def procces_order(self, client, driver):
        driver_loc = ",".join([str(x) for x in driver['loc']['coordinates']])
        client_start = ",".join([str(x) for x in client['start']['coordinates']])
        client_end = ",".join([str(x) for x in client['end']['coordinates']])
        first_route = self.get_route(driver_loc, client_start)
        self.log.info("Route from %s to %s for driver %s was created"%(driver_loc, client_start, str(driver['_id'])))

        if first_route:
            self.follow_route(driver, first_route)
            trip_route = self.get_route(client_start, client_end)
            if trip_route:
                self.log.info(
                    "Route from %s to %s for driver %s was created" % (client_start, client_end, str(driver['_id'])))
                self.db.clients.update({'_id': client['_id']}, {"$set": {"status": "in trip"}})
                self.db.drivers.update({'_id': driver['_id']}, {"$set": {"status": "in trip"}})
                self.follow_route(driver, trip_route)
            else:
                self.db.clients.update({'_id': client['_id']}, {"$set": {"status": "trip route error"}})
                self.db.drivers.update({'_id': driver['_id']}, {"$set": {"status": "free"}})
                self.log.error("Can't create first route for coming")
        else:
            self.db.clients.update({'_id': client['_id']}, {"$set": {"status": "first route error"}})
            self.db.drivers.update({'_id': driver['_id']}, {"$set": {"status": "free"}})
            self.log.error("Can't create first route for coming")
        self.db.clients.update({'_id': client['_id']}, {"$set": {"status": "done"}})
        self.db.drivers.update({'_id': driver['_id']}, {"$set": {"status": "free"}})
        self.log.info("Order %s closed by %s"%(str(client['_id']), str(driver['_id'])))

    def get_route(self, start, end):
        route = requests.get(
            "https://maps.googleapis.com/maps/api/directions/json?origin=%s&destination=%s&key=AIzaSyBgCmbu2OSW7DFzKdKp0s_HfVhwMmXTYWA" % (
                start, end)).json()
        if route['status'] == 'OK':
            legs = route['routes'][0]['legs']
            if len(legs) == 1 and legs[0]['distance']['value'] < 100:
                return None
        return legs

    def follow_route(self, driver, route):
        for leg in route:
            for step in leg['steps']:
                lng = step['start_location']['lng']
                lat = step['start_location']['lat']
                secs = step['duration']['value']
                delta_lng = (step['end_location']['lng'] - step['start_location']['lng']) / secs
                delta_lat = (step['end_location']['lat'] - step['start_location']['lat']) / secs
                for sec in range(secs):
                    t1 = time.time()
                    lng += delta_lng
                    lat += delta_lat
                    self.log.info("Car %s on %d sec at %.3f, %.3f"%(driver['_id'], sec, lng, lat))
                    self.db.drivers.update({"_id": driver["_id"]}, {"$set": {"loc.coordinates": [lat, lng]}})
                    t2 = time.time()
                    time.sleep(max(1 - (t2 - t1), 0))
                #print("Driver %s finished at %s" % (str(driver['_id']), str(step['end_location'])))


if __name__ == '__main__':
    server = ThreadedServer()
    server.listen()
