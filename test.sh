#!/usr/bin/env bash
TEST_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
source $TEST_DIR/config.sh
source $TEST_DIR/bash-utilities/utils.sh

echo "testing datastore..."
curl -X GET "http://127.0.0.1/api/3/action/datastore_search?resource_id=_table_metadata"
input_two_choice "Do you see a JSON page without errors as output to previous command?" y n


echo "testing datapusher..."
curl 0.0.0.0:8800
input_two_choice "Do you see smth like \"help: Get help at: http://ckan-service-provider.readthedocs.org\"?" y n
