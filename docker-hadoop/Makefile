DOCKER_NETWORK = hbase
ENV_FILE = hadoop.env
ifdef RELEASE
RELEASE := $(RELEASE)
else
RELEASE := latest
endif

build:
#   https://stackoverflow.com/a/34392052/15104821
	docker build -t pash-base:$(RELEASE) -f ./pash-base/Dockerfile --build-arg RELEASE=$(RELEASE) ..
	docker build -t hadoop-pash-base:$(RELEASE) -f ./base/Dockerfile --build-arg RELEASE=$(RELEASE) ..

	docker build -t hadoop-namenode:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./namenode
	docker build -t hadoop-datanode:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./datanode
	docker build -t hadoop-resourcemanager:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./resourcemanager
	docker build -t hadoop-nodemanager:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./nodemanager
	docker build -t hadoop-historyserver:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./historyserver
	docker build -t hadoop-submit:$(RELEASE) --build-arg RELEASE=$(RELEASE) ./submit

wordcount:
	docker build -t hadoop-wordcount ./submit
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -mkdir -p /input/
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -copyFromLocal -f /opt/hadoop-3.2.2/README.txt /input/
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-wordcount
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -cat /output/*
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -rm -r /output
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -rm -r /input
