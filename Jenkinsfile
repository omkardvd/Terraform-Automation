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

    stages {

        // ─────────────────────────────────────────
        // STAGE 1 — Checkout
        // ─────────────────────────────────────────
        stage('Checkout') {
            steps {
                script {
                    // ✅ FIX 1: env vars with params resolved INSIDE script block
                    //    not in top-level environment{} block — params are null
                    //    on first run when evaluated at pipeline load time
                    env.ENV_LOWER    = params.ENVIRONMENT.toLowerCase()
                    env.TF_VAR_FILE  = "envs/${env.ENV_LOWER}.tfvars"
                    env.TF_WORKSPACE = env.ENV_LOWER

                    echo "📦 Checking out branch: ${params.BRANCH} | ENV: ${params.ENVIRONMENT}"
                }
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

                    // ✅ FIX 2: workspace select/new split into two safe sh calls
                    //    using returnStatus to avoid pipeline abort on non-zero exit
                    def wsExists = sh(
                        script: "terraform workspace select ${env.TF_WORKSPACE}",
                        returnStatus: true
                    )
                    if (wsExists != 0) {
                        sh "terraform workspace new ${env.TF_WORKSPACE}"
                    }

                    echo "✅ Workspace set to: ${env.TF_WORKSPACE}"
                }
            }
        }

        // ─────────────────────────────────────────
        // STAGE 3 — Action (plan / apply / destroy)
        // ─────────────────────────────────────────
        stage('Action') {
            steps {
                script {
                    // ✅ FIX 3: envVar uses double quotes not single quotes
                    //    single quotes inside sh string causes shell parsing issues
                    def varFile = "-var-file=${env.TF_VAR_FILE}"
                    def envVar  = "-var=\"environment=${env.ENV_LOWER}\""

                    switch (params.ACTION) {

                        case 'plan':
                            echo "📋 Running Plan — ENV: ${params.ENVIRONMENT} | BRANCH: ${params.BRANCH}"
                            sh "terraform plan ${varFile} ${envVar}"
                            break

                        case 'apply':
                            if (params.ENVIRONMENT in ['UAT', 'PROD']) {
                                input(
                                    message: "⚠️ Confirm APPLY to ${params.ENVIRONMENT} from branch '${params.BRANCH}'?",
                                    ok: "Yes, Apply"
                                )
                            }
                            echo "🚀 Running Apply — ENV: ${params.ENVIRONMENT} | BRANCH: ${params.BRANCH}"
                            sh "terraform apply --auto-approve ${varFile} ${envVar}"
                            break

                        case 'destroy':
                            input(
                                message: "🔴 DANGER: Confirm DESTROY on ${params.ENVIRONMENT} from branch '${params.BRANCH}'?",
                                ok: "Yes, Destroy"
                            )
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
            WORKSPACE: ${env.TF_WORKSPACE}
            TFVARS   : ${env.TF_VAR_FILE}
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
            WORKSPACE: ${env.TF_WORKSPACE ?: 'N/A'}
            ───────────────────────────
            """
        }
        aborted {
            echo "⛔ Pipeline ABORTED — ENV: ${params.ENVIRONMENT} | ACTION: ${params.ACTION} | BRANCH: ${params.BRANCH}"
        }
    }
}
