pipeline {
    agent any
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['DEV', 'UAT', 'PROD'],
            description: 'Select the target environment'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply'],
            description: 'Select the action to perform'
        )
        string(
            name: 'BRANCH',
            defaultValue: 'main',
            description: 'Enter the branch name to checkout'
        )
    }
    environment {
        TF_VAR_FILE = "${params.ENVIRONMENT?.toLowerCase() ?: 'dev'}.tfvars"
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: "*/${params.BRANCH}"]],
                    extensions: [],
                    userRemoteConfigs: [[url: 'https://github.com/omkardvd/Terraform-Automation.git']]
                )
            }
        }

        stage('Terraform Init') {
            steps {
                sh "terraform init -reconfigure"
            }
        }

        stage('Action') {
            steps {
                script {
                    def varFile = "-var-file=envs/${TF_VAR_FILE}"

                    switch (params.ACTION) {
                        case 'plan':
                            echo "Executing Plan for ${params.ENVIRONMENT}..."
                            sh "terraform plan ${varFile}"
                            break
                        case 'apply':
                            if (params.ENVIRONMENT == 'PROD') {
                                input message: "Are you sure you want to apply changes to PROD?", ok: "Yes, Apply"
                            }
                            echo "Executing Apply for ${params.ENVIRONMENT}..."
                            sh "terraform apply --auto-approve ${varFile}"
                            break
                        default:
                            error 'Unknown action'
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully for ${params.ENVIRONMENT} - ${params.ACTION}"
        }
        failure {
            echo "Pipeline failed for ${params.ENVIRONMENT} - ${params.ACTION}"
        }
    }
}