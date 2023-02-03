nodeversion=$(shell node -v | cut -c2-3)
nodepm=yarn
SHELL=/bin/bash
#nodepm=yarn

.PHONY: world check genver init git modify submodules-build submodules-scripts submodules packages hexo cimod ci clean substash

world: hexo

check:
	@if [ -z $(nodeversion) ]; then\
		echo -e "\033[41;37m[CHECK  ]\033[0m Node.js was not detected.\n\033[32m[CHECK  ]\033[0m Install Node.js v18 or v19 first." && exit 2;\
	elif [ $(nodeversion) = "18" ]; then\
		echo -e "\033[32m[CHECK  ]\033[0m Node.js 18($(shell node -v)) detected";\
	elif [ $(nodeversion) = "19" ]; then\
		echo -e "\033[32m[CHECK  ]\033[0m Node.js 19($(shell node -v)) detected.";\
	else\
		echo -e "\033[41;37m[CHECK  ]\033[0m Unsupported Node.js version detected.\n\033[32m[CHECK  ]\033[0m You are using $(shell node -v) but the program requires v18 or v19.\n\033[32m[CHECK  ]\033[0m Upgrade/Downgrade Node.js to v18/v19, or use nvm to select version." && exit 2;\
	fi

genver: git
	@echo -e "\033[32m[GENVER ]\033[0m Generating build info...\c"
	@cp themes/Anatolo_patches/genver.default themes/Anatolo_patches/genver
	@sed -i 's/HEAD/$(shell git rev-parse HEAD)/g' themes/Anatolo_patches/genver
	@sed -i 's/user/$(shell whoami)/g' themes/Anatolo_patches/genver
	@sed -i 's/host/$(shell hostnamectl hostname)/g' themes/Anatolo_patches/genver
	@sed -i 's/kver/$(shell uname -r)/g' themes/Anatolo_patches/genver
	@sed -i 's/cn-date/$(shell TZ=Asia/Shanghai date "+%Y-%m-%d")/g' themes/Anatolo_patches/genver
	@echo -e "ok"

init: check
	@echo -e "\033[32m[GIT    ]\033[0m Updating submodules... " && git submodule update --init --recursive

git: init
	@if [ $(shell git rev-parse --abbrev-ref HEAD) = "master" ]; then\
		echo -e "\033[32m[GIT    ]\033[0m \c" && git pull --ff-only;\
	else\
		echo -e "\033[32m[GIT    ]\033[0m Not using branch master. Skip.";\
	fi

modify: git substash
	@echo -e "\033[32m[MODIFY ]\033[0m themes/Anatolo/_config.yml" && cp themes/Anatolo_patches/_config.yml themes/Anatolo/_config.yml
	@echo -e "\033[32m[MODIFY ]\033[0m themes/Anatolo/layout/partial/footer.pug" && cp themes/Anatolo_patches/layout/partial/footer.pug themes/Anatolo/layout/partial/footer.pug
	@echo -e "\033[32m[MODIFY ]\033[0m themes/Anatolo/source/images/moe.png" && cp themes/Anatolo_patches/source/images/moe.png themes/Anatolo/source/images/moe.png

submodules-build: packages modify

submodules-scripts: submodules-build genver
	@echo -e "\033[32m[GENVER ]\033[0m Writing build info and query string into source...\c"
	# @cat themes/Anatolo_patches/genver >> themes/Anatolo/layout/partial/script.ejs
	@echo -e "ok"
	@cat themes/Anatolo_patches/genver

submodules: submodules-scripts

packages: init
	@echo -e "\033[32m[PACKAGE]\033[0m Yang-Blog: $(nodepm) install" && $(nodepm) install
	@echo -e "\033[32m[PACKAGE]\033[0m submodules: $(nodepm) install" && cd themes/Anatolo/ && $(nodepm) install

hexo: submodules
	@echo -e "\033[32m[HEXO   ]\033[0m \c"
	node_modules/hexo/bin/hexo generate

cimod: genver
	@echo -e "\033[32m[GENVER ]\033[0m Generating build info for CI...\c"
	@sed -i 's/default/CI/g' themes/Anatolo_patches/genver
	@echo -e "ok"

ci: cimod hexo

clean: 
	@echo -e "\033[32m[CLEAN  ]\033[0m node_modules/" && rm -rf node_modules/
	# @echo -e "\033[32m[CLEAN  ]\033[0m themes/Anatolo/" && rm -rf themes/Anatolo/
	@echo -e "\033[32m[CLEAN  ]\033[0m public/" && rm -rf public/
	@echo -e "\033[32m[CLEAN  ]\033[0m themes/Anatolo_patches/genver" && rm -rf themes/Anatolo_patches/genver

substash: 
	@echo -e "\033[32m[S-STASH]\033[0m \c" && cd themes/Anatolo && git stash