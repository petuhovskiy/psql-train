.PHONY: up

up:
	docker-compose up -d

rm:
	docker-compose down -v

run:
	docker-compose exec db psql -U postgres

term:
	docker-compose exec db /bin/bash
