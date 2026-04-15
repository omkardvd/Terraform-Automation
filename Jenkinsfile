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
    }

    environment {
        TF_VAR_FILE    = "${params.ENVIRONMENT?.toLowerCase() ?: 'dev'}.tfvars"
        REPO_URL       = 'https://github.com/omkardvd/Terraform-Automation.git'
        GITHUB_API_URL = 'https://api.github.com/repos/omkardvd/Terraform-Automation/branches'
    }

    stages {

        stage('Fetch & Select Branch') {
            steps {
                script {
                    // ── Fetch branches from GitHub API ──────────────────────────
                    def response = sh(
                        script: """
                            curl -s ${GITHUB_API_URL} \
                                 -H "Accept: application/vnd.github.v3+json"
                        """,
                        returnStdout: true
                    ).trim()

                    // ── Parse branch names from JSON ─────────────────────────────
                    def branches = readJSON(text: response).collect { it.name }
                    echo "Available branches: ${branches}"

                    // ── Prompt user to pick a branch ─────────────────────────────
                    def selectedBranch = input(
                        message: 'Select the branch to deploy',
                        parameters: [
                            choice(
                                name: 'BRANCH',
                                choices: branches,
                                description: 'Available branches from GitHub'
                            )
                        ]
                    )

                    env.SELECTED_BRANCH = selectedBranch
                    echo "Selected branch: ${env.SELECTED_BRANCH}"
                }
            }
        }

        stage('Checkout') {
            steps {
                checkout scmGit(
                    branches: [[name: "*/${env.SELECTED_BRANCH}"]],
                    extensions: [],
                    userRemoteConfigs: [[url: "${REPO_URL}"]]
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
                            echo "Executing Plan for ${params.ENVIRONMENT} on branch ${env.SELECTED_BRANCH}..."
                            sh "terraform plan ${varFile}"
                            break

                        case 'apply':
                            if (params.ENVIRONMENT == 'PROD') {
                                input message: "⚠️ Apply changes to PROD from branch '${env.SELECTED_BRANCH}'?", ok: "Yes, Apply"
                            }
                            echo "Executing Apply for ${params.ENVIRONMENT} on branch ${env.SELECTED_BRANCH}..."
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
            echo "✅ Pipeline completed — ENV: ${params.ENVIRONMENT} | ACTION: ${params.ACTION} | BRANCH: ${env.SELECTED_BRANCH}"
        }
        failure {
            echo "❌ Pipeline failed — ENV: ${params.ENVIRONMENT} | ACTION: ${params.ACTION} | BRANCH: ${env.SELECTED_BRANCH}"
        }
    }
}