#!/bin/bash

	echo "Enter PAT Token"
	read -r PAT

	echo "Enter Organization name"
	read -r OrganizationName

	echo "Enter Project ID"
	read -r projectId

	echo "Enter New Repository name To Create in Azure"
	read -r RepoName

	echo "Enter GIT URL To Import Code To Azure Repo"
	read -r GITURL

	echo "Enter Folder Name where Pipeline To be Created"
	read -r FolderName

	echo "Enter CI Pipeline Name"
	read -r PipelineName

#########################################Create Repo Stage###############################################################

	"Repo_Creation_Status=$(curl --write-out "%{http_code}\n" -X POST \
        -u  :"$PAT"  "https://dev.azure.com/""${OrganizationName}""/""${projectId}""/_apis/git/repositories?api-version=6.1-preview.1" \
        -H  "Accept: application/json" \
        -H  "Content-Type: application/json" \
        -d '{
				"name": "'"$RepoName"'",
				"project":
							{
                                "id": "'"$projectId"'"
                            }
            }' --output Repooutput.txt --silent)"


########################################Import Code from GIT Stage#######################################################

    "Import_Status=$(curl --write-out "%{http_code}\n" -X POST \
        -u  :"$PAT"  "https://dev.azure.com/""${OrganizationName}""/""${projectId}""/_apis/git/repositories/""${RepoName}""/importRequests?api-version=5.0-preview.1" \
        -H  "Accept: application/json" \
        -H  "Content-Type: application/json" \
        -d '{
                "parameters":
							{
								"gitSource":
											{
												"url": "'"$GITURL"'"
											}
                            }
			}' --output ImportOutput.txt --silent)"


#########################################Create Pipeline Stage#############################################################

	RepoID=$(jq -r '.id' RepoOutput.txt)  #Get RepoID for pipeline creation

	"Create_Pipeline=$(curl --write-out "%{http_code}\n" -X POST -L \
		-u  :"$PAT" "https://dev.azure.com/""${OrganizationName}""/""${projectId}""/_apis/pipelines?api-version=6.0-preview.1" \
		-H "Content-Type: application/json" \
		-H  "Accept: application/json" \
		-d '{
						"folder": "'"$FolderName"'",
						"name": "'"$PipelineName"'",
						"configuration": {
											"type": "yaml",
											"path": "azure-pipelines.yml",
											"repository": {
												"id": "'"$RepoID"'",
												"name": "'"$RepoName"'",
												"type": "azureReposGit"
														}
										}
					}' --output PipeOutput.txt --silent)"


#####################################Trigger Pipeline Stage#################################################################

	DefId=$(jq -r '.id' PipeOutput.txt)  #Get definition ID

	"Trigger_Pipeline=$(curl --write-out "%{http_code}\n" -X POST -L \
		-u  :"$PAT" "https://dev.azure.com/""${OrganizationName}""/""${projectId}""/_apis/pipelines/""${DefId}""/runs?api-version=6.0-preview.1" \
		-H  "Content-Type: application/json" \
		-H  "Accept: application/json" \
		-d '{
			"resources": {
			"repositories": {
            "self": {
                "refName": "refs/heads/master"
					}
							}
						}' --output Triggeroutput.txt --silent)"
			echo "Output: $(Trigger_Pipeline)"
