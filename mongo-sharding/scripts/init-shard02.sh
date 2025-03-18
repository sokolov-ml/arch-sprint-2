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
EOF