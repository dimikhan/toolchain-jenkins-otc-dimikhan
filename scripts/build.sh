#!/bin/bash

CF_ACCESS_TOKEN="bearer ..."
CF_REFRESH_TOKEN="..."
CF_ORG_NAME="Szymon.Brandys@pl.ibm.com"
CF_SPACE_NAME="dev"

UPT_TYPE=jenkins
UPT_NAME=jenkins_node_cache

whoami
rm -rf *

GIT_CONFIG='{"ConfigVersion": 3,"Target":"https://api.stage1.ng.bluemix.net","APIVersion":"2.44.0","AuthorizationEndpoint":"https://login.stage1.ng.bluemix.net/UAALoginServerWAR","LoggregatorEndPoint":"wss://loggregator.stage1.ng.bluemix.net:443","DopplerEndPoint":"wss://doppler.stage1.ng.bluemix.net:443","UaaEndpoint":"https://uaa.stage1.ng.bluemix.net","RoutingAPIEndpoint":"https://api.stage1.ng.bluemix.net/routing","AccessToken":"'$CF_ACCESS_TOKEN'","SSHOAuthClient":"ssh-proxy","RefreshToken":"'$CF_REFRESH_TOKEN'"}'

cd /home/jenkins/.cf
rm -f config.json

echo $GIT_CONFIG > /home/jenkins/.cf/config.json
cf target -o $CF_ORG_NAME -s $CF_SPACE_NAME

cat > get_repo.py <<EOF
import os, sys, json

uptType=sys.argv[1]
uptName=sys.argv[2]

toolchainIds = os.popen("cf otc toolchains | tail -n +4 | awk '{print \$2}'").read()

def printRepositoryDetails(servicesJson):
    for service in servicesJson:
        if (service["service_id"] == "githubpublic"
                or service["service_id"] == "github"):
            print "repo_url: " + service["parameters"]["repo_url"]
            sys.stderr.write("\nrepo_url: " + service["parameters"]["repo_url"])
            print "token_url: " + service["parameters"]["token_url"]
            sys.stderr.write("\nrepo_url: " + service["parameters"]["repo_url"])

for toolchainId in toolchainIds.splitlines():
    sys.stderr.write("\nChecking toolchain " + toolchainId)
    servicesJson = json.loads(os.popen('cf otc toolchain ' + toolchainId + ' services --json | tail -n +2').read())
    for service in servicesJson:
        if (service["service_id"] == "userprovided"
                and service["parameters"]["type"] == uptType
                and service["parameters"]["name"] == uptName):
            printRepositoryDetails(servicesJson)
            quit()
      
EOF

python get_repo.py $UPT_TYPE $UPT_NAME > repo.txt


GIT_REPO_URL=`grep repo_url repo.txt | awk '{print \$2}'`
GIT_TOKEN_URL=`grep token_url repo.txt | awk '{print \$2}'`

cat > get_git_auth_token.py <<EOF
import os, sys, json

gitTokenUrl=sys.argv[1]
cfAuthToken=sys.argv[2]
print(json.loads(os.popen('curl -s ' + gitTokenUrl + ' -H "Authorization: ' + cfAuthToken + '"').read())["access_token"])
EOF

GIT_AUTH_TOKEN=`python get_git_auth_token.py "$GIT_TOKEN_URL" "$CF_ACCESS_TOKEN"`

git clone `echo $GIT_REPO_URL | sed 's_'"https://"'_'"https://$GIT_AUTH_TOKEN@"'_'`

GIT_FOLDER_NAME=`echo $GIT_REPO_URL | awk -F "/" '{print $(NF)}' | sed s/.git//`
GIT_APP_NAME=$GIT_FOLDER_NAME'_12345'
cd $GIT_FOLDER_NAME
cf push $GIT_APP_NAME
cf app $GIT_APP_NAME

# clean cf credentials
cd /home/jenkins/.cf
rm -f config.json
