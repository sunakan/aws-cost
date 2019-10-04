bash:
	docker-compose run --rm app bash

build:
	docker-compose build

test:
	circleci config process .circleci/config.yml > .circleci/config-2.0.yml
	circleci local execute -c .circleci/config-2.0.yml --job hello_job
# Orbは2.0では無理(shellを全コピして持ってくる？ => いつか)
#circleci local execute -c .circleci/config-2.0.yml -e SLACK_WEBHOOK=${SLACK_WEBHOOK} --job slack_test
