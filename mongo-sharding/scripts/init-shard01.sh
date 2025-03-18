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
EOF