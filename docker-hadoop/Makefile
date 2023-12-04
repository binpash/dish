DOCKER_NETWORK = hbase
ENV_FILE = hadoop.env
ifdef RELEASE
RELEASE := $(RELEASE)
else
RELEASE := latest
endif

build:
	docker build -t pash-base:$(RELEASE) ./pash-base --build-arg RELEASE=$(RELEASE)
	docker build -t hadoop-pash-base:$(RELEASE) ./base --build-arg RELEASE=$(RELEASE)

	docker build -t hadoop-namenode:$(RELEASE) ./namenode --build-arg RELEASE=$(RELEASE)
	docker build -t hadoop-datanode:$(RELEASE) ./datanode --build-arg RELEASE=$(RELEASE)
	docker build -t hadoop-resourcemanager:$(RELEASE) ./resourcemanager --build-arg RELEASE=$(RELEASE)
	docker build -t hadoop-nodemanager:$(RELEASE) ./nodemanager --build-arg RELEASE=$(RELEASE)
	docker build -t hadoop-historyserver:$(RELEASE) ./historyserver --build-arg RELEASE=$(RELEASE)
	docker build -t hadoop-submit:$(RELEASE) ./submit --build-arg RELEASE=$(RELEASE)

wordcount:
	docker build -t hadoop-wordcount ./submit
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -mkdir -p /input/
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -copyFromLocal -f /opt/hadoop-3.2.2/README.txt /input/
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-wordcount
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -cat /output/*
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -rm -r /output
	docker run --network ${DOCKER_NETWORK} --env-file ${ENV_FILE} hadoop-base:$(RELEASE) hdfs dfs -rm -r /input
