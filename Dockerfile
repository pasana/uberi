FROM ubuntu:14.04

RUN apt-get update && apt-get install -y apt-transport-https ca-certificates
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 2930ADAE8CAF5059EE73BB4B58712A2291FA4AD5 \
  && echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.6 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.6.list \
  && apt-get update && apt-get install -y mongodb-org
RUN mkdir -p /data/configdb /data/db /data/keyfile /data/admin
RUN chown -R mongodb:mongodb /var/lib/mongodb/.
ADD admin.js /data/admin/
RUN mongod --fork --dbpath /var/lib/mongodb/ --smallfiles --logpath /var/log/mongodb.log --logappend && mongo < /data/admin/admin.js
ADD mongo-keyfile /data/keyfile/
ADD env /	

CMD ["bash"]

