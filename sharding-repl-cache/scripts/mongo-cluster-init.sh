#!/bin/bash

# Инициализация конфигурационного сервера (config server)
echo "Initializing config server (configSrv)..."
docker compose exec -T configSrv mongosh --port 27010 --quiet <<EOF
rs.initiate(
  {
    _id : "config_server",
    configsvr: true,  
    members: [
      { _id : 0, host : "configSrv:27010" }  
    ]
  }
);
exit();
EOF
echo "Config server initialized."

# Инициализация первого шарда (shard01)
echo "Initializing shard01..."
docker compose exec -T shard01_1 mongosh --port 27011 --quiet <<EOF
rs.initiate(
    {
      _id : "shard01",  
      members: [
        { _id : 0, host : "shard01_1:27011" },  
        { _id : 1, host : "shard01_2:27012" },
        { _id : 2, host : "shard01_3:27013" },        
      ]
    }
);
exit();
EOF
echo "Shard01 initialized."

# Инициализация второго шарда (shard02)
echo "Initializing shard02..."
docker compose exec -T shard02_1 mongosh --port 27021 --quiet <<EOF
rs.initiate(
    {
      _id : "shard02",  
      members: [
        { _id : 0, host : "shard02_1:27021" }, 
        { _id : 1, host : "shard02_2:27022" },
        { _id : 2, host : "shard02_3:27023" },        
      ]
    }
);
exit();
EOF
echo "Shard02 initialized."

# Ожидание инициализации шардов
echo "Waiting for shards to initialize..."
sleep 60  # Пауза для завершения инициализации шардов

# Инициализация маршрутизатора (mongos) и настройка шардирования
echo "Initializing mongos router and setting up sharding..."
docker compose exec -T mongos_router mongosh --port 27007 --quiet <<EOF
// Добавление шардов в кластер
sh.addShard("shard01/shard01_1:27011,shard01_2:27012,shard01_3:27013");
sh.addShard("shard02/shard02_1:27021,shard02_2:27022,shard02_3:27023");

// Проверка состояния шардов
sh.status();

// Включение шардирования для базы данных "somedb"
sh.enableSharding("somedb");

// Шардирование коллекции "helloDoc" по полю "name" с использованием хэширования
sh.shardCollection("somedb.helloDoc", { "name" : "hashed" });

// Вставка тестовых данных
use somedb;
for (var i = 0; i < 1000; i++) {
  db.helloDoc.insert({ age: i, name: "ly" + i });
}

// Проверка количества документов в коллекции
db.helloDoc.countDocuments();

exit();
EOF
echo "Mongos router initialized and sharding setup complete."