PLUGIN_NAME=docker-volume-profitbricks

all: clean docker rootfs create

clean:
	@echo "### rm ./plugin"
	@rm -rf ./plugin

docker:
	@echo "### docker build: builder image"
	@docker build -q -t builder -f Dockerfile.dev .
	@echo "### extract docker-volume-profitbricks"
	@docker create --name tmp builder
	@docker cp tmp:/go/bin/docker-volume-profitbricks .
	@docker rm -vf tmp
	@docker rmi builder
	@echo "### docker build: rootfs image with docker-volume-profitbricks"
	@docker build -q -t ${PLUGIN_NAME}:rootfs .

rootfs:
	@echo "### create rootfs directory in ./plugin/rootfs"
	@mkdir -p ./plugin/rootfs
	@docker create --name tmp ${PLUGIN_NAME}:rootfs
	@docker export tmp | tar -x -C ./plugin/rootfs
	@echo "### copy config.json to ./plugin/"
	@cp config.json ./plugin/
	@docker rm -vf tmp

create:
	@echo "### remove existing plugin ${PLUGIN_NAME} if exists"
	@docker plugin rm -f ${PLUGIN_NAME} || true
	@echo "### create new plugin ${PLUGIN_NAME} from ./plugin"
	@docker plugin create ${PLUGIN_NAME} ./plugin

enable:
	@echo "### enable plugin ${PLUGIN_NAME}"
	@docker plugin enable ${PLUGIN_NAME}

push:  clean docker rootfs create enable
	@echo "### push plugin ${PLUGIN_NAME}"
	@docker plugin push ${PLUGIN_NAME}
