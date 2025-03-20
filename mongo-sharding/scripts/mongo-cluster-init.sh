docker compose exec -T configSrv mongosh --port 27017 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
       configsvr: true,
    members: [
      { _id : 0, host : "configSrv:27017" }
    ]
  }
);
exit();
EOF

docker compose exec -T shard01 mongosh --port 27018 --quiet <<EOF
rs.initiate(
    {
      _id : "shard01",
      members: [
        { _id : 0, host : "shard01:27018" },
       // { _id : 1, host : "shard02:27019" }
      ]
    }
);
exit();
EOF

docker compose exec -T shard02 mongosh --port 27019 --quiet <<EOF
rs.initiate(
    {
      _id : "shard02",
      members: [
       // { _id : 0, host : "shard01:27018" },
        { _id : 1, host : "shard02:27019" }
      ]
    }
);
exit();
EOF


docker compose exec -T mongos_router mongosh --port 27020 --quiet <<EOF
sh.addShard( "shard01/shard01:27018");
sh.addShard( "shard02/shard02:27019");
sh.enableSharding("somedb");
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )
use somedb
for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})
db.helloDoc.countDocuments() 
exit();
EOF
