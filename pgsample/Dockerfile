FROM postgres:latest

RUN apt-get update && apt-get install -y wget unzip && rm -rf /var/lib/apt/lists/*

RUN wget https://edu.postgrespro.ru/demo-small-20161013.zip \
    && unzip demo-small-20161013.zip \
    && rm -rf demo-small-20161013.zip

RUN sed -i 's/DROP DATABASE/DROP DATABASE IF EXISTS/g' demo_small.sql \
    && sed -i 's/CREATE SCHEMA/CREATE SCHEMA IF NOT EXISTS/g' demo_small.sql \
    && mv demo_small.sql docker-entrypoint-initdb.d/
