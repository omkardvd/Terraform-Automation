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
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select the Terraform action to perform'
        )
        string(
            name: 'BRANCH',
            defaultValue: 'main',
            description: 'Enter the branch name to checkout'
        )
    }

    environment {
        ENV_LOWER    = "${params.ENVIRONMENT?.toLowerCase() ?: 'dev'}"
        TF_VAR_FILE  = "envs/${params.ENVIRONMENT?.toLowerCase() ?: 'dev'}.tfvars"
        TF_WORKSPACE = "${params.ENVIRONMENT?.toLowerCase() ?: 'dev'}"
    }

    stages {

        // ─────────────────────────────────────────
        // STAGE 1 — Checkout
        // ─────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "📦 Checking out branch: ${params.BRANCH} for ENV: ${params.ENVIRONMENT}"
                checkout scmGit(
                    branches: [[name: "*/${params.BRANCH}"]],
                    extensions: [],
                    userRemoteConfigs: [[
                        url: 'https://github.com/omkardvd/Terraform-Automation.git'
                    ]]
                )
            }
        }

        // ─────────────────────────────────────────
        // STAGE 2 — Terraform Init + Workspace
        // ─────────────────────────────────────────
        stage('Terraform Init') {
            steps {
                script {
                    echo "⚙️ Initialising Terraform — ENV: ${params.ENVIRONMENT}"
                    sh "terraform init -reconfigure"

                    // Create or select workspace per environment
                    sh """
                        terraform workspace select ${TF_WORKSPACE} || \
                        terraform workspace new    ${TF_WORKSPACE}
                    """
                    echo "✅ Workspace set to: ${TF_WORKSPACE}"
                }
            }
        }

        // ─────────────────────────────────────────
        // STAGE 3 — Action (plan / apply / destroy)
        // ─────────────────────────────────────────
        stage('Action') {
            steps {
                script {
                    def varFile = "-var-file=${TF_VAR_FILE}"
                    def envVar  = "-var='environment=${ENV_LOWER}'"

                    switch (params.ACTION) {

                        case 'plan':
                            echo "📋 Running Plan — ENV: ${params.ENVIRONMENT} | BRANCH: ${params.BRANCH}"
                            sh "terraform plan ${varFile} ${envVar}"
                            break

                        case 'apply':
                            // Manual approval for UAT and PROD
                            if (params.ENVIRONMENT in ['UAT', 'PROD']) {
                                input message: "⚠️ Confirm APPLY to ${params.ENVIRONMENT} from branch '${params.BRANCH}'?",
                                      ok: "Yes, Apply"
                            }
                            echo "🚀 Running Apply — ENV: ${params.ENVIRONMENT} | BRANCH: ${params.BRANCH}"
                            sh "terraform apply --auto-approve ${varFile} ${envVar}"
                            break

                        case 'destroy':
                            // Strict manual approval for ALL environments
                            input message: "🔴 DANGER: Confirm DESTROY on ${params.ENVIRONMENT} from branch '${params.BRANCH}'?",
                                  ok: "Yes, Destroy"
                            echo "💣 Running Destroy — ENV: ${params.ENVIRONMENT} | BRANCH: ${params.BRANCH}"
                            sh "terraform destroy --auto-approve ${varFile} ${envVar}"
                            break

                        default:
                            error "❌ Unknown action: ${params.ACTION}"
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────
    // POST — Summary
    // ─────────────────────────────────────────
    post {
        success {
            echo """
            ✅ Pipeline SUCCEEDED
            ───────────────────────────
            ENV      : ${params.ENVIRONMENT}
            ACTION   : ${params.ACTION}
            BRANCH   : ${params.BRANCH}
            WORKSPACE: ${TF_WORKSPACE}
            TFVARS   : ${TF_VAR_FILE}
            ───────────────────────────
            """
        }
        failure {
            echo """
            ❌ Pipeline FAILED
            ───────────────────────────
            ENV      : ${params.ENVIRONMENT}
            ACTION   : ${params.ACTION}
            BRANCH   : ${params.BRANCH}
            WORKSPACE: ${TF_WORKSPACE}
            ───────────────────────────
            """
        }
        aborted {
            echo "⛔ Pipeline ABORTED — ENV: ${params.ENVIRONMENT} | ACTION: ${params.ACTION} | BRANCH: ${params.BRANCH}"
        }
    }
}
