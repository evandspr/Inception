COMPOSE	= docker compose -f srcs/docker-compose.yml
DATA	= /home/edesprez/data

GREEN	= \033[32m
RED	= \033[31m
RESET	= \033[0m

all: up

check:
	@for f in db_password db_root_password credentials; do \
		if [ ! -f secrets/$$f.txt ]; then \
			echo "$(RED)Missing secrets/$$f.txt (see DEV_DOC.md)$(RESET)"; exit 1; \
		fi; \
	done

up: check
	@mkdir -p $(DATA)/mariadb $(DATA)/wordpress
	@$(COMPOSE) up -d --build
	@echo "$(GREEN)✧ Inception is running: https://edesprez.42.fr ✧$(RESET)"

down:
	@$(COMPOSE) down

stop:
	@$(COMPOSE) stop

start:
	@$(COMPOSE) start

logs:
	@$(COMPOSE) logs -f

ps:
	@$(COMPOSE) ps

clean:
	@$(COMPOSE) down --rmi all -v
	@echo "$(RED)🗑️ clean done 🗑️$(RESET)"

fclean: clean
	@sudo rm -rf $(DATA)
	@echo "$(RED)🗑️ fclean done 🗑️$(RESET)"

re: fclean all

.PHONY: all check up down stop start logs ps clean fclean re
