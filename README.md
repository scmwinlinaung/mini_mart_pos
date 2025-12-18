
-- docker
docker-compose up -d postgres

-- drop database

docker exec -i mini_mart_pos_db psql -U postgres -d postgres -c "DROP DATABASE mini_mart_pos;"

-- create database

docker exec -i mini_mart_pos_db psql -U postgres -d postgres -c "create DATABASE mini_mart_pos;"


-- create schema

docker exec -i mini_mart_pos_db psql -U postgres -d mini_mart_pos < /Users/winlinaung/Freelance_Prj/mini_mart_pos/schema.sql