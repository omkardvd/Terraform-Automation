pipeline {
    agent any

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['DEV', 'UAT', 'PROD'],
            description: 'Select the target environment (DEV / UAT / PROD)'
        )
        choice(
            name: 'ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Select the Terraform action to perform'
        )
    }

    environment {
        REPO_URL       = 'https://github.com/omkardvd/Terraform-Automation.git'
        GITHUB_API_URL = 'https://api.github.com/repos/omkardvd/Terraform-Automation/branches'
        ENV_LOWER      = "${params.ENVIRONMENT?.toLowerCase() ?: 'dev'}"
        TF_VAR_FILE    = "envs/${ENV_LOWER}.tfvars"
        TF_WORKSPACE   = "${ENV_LOWER}"
    }

    stages {

        // ─────────────────────────────────────────────
        // STAGE 1 — Fetch branches & filter by ENV
        // ─────────────────────────────────────────────
        stage('Fetch & Select Branch') {
            steps {
                script {
                    echo "🔍 Fetching branches for environment: ${params.ENVIRONMENT}"

                    // ── Fetch all branches from GitHub API ────────────────────
                    def response = sh(
                        script: """
                            curl -s "${GITHUB_API_URL}" \
                                 -H "Accept: application/vnd.github.v3+json"
                        """,
                        returnStdout: true
                    ).trim()

                    // ── Parse JSON using Groovy (no plugin needed) ────────────
                    def jsonSlurper = new groovy.json.JsonSlurper()
                    def jsonData    = jsonSlurper.parseText(response)
                    def allBranches = jsonData.collect { it.name }
                    echo "All available branches: ${allBranches}"

                    // ── Filter branches by selected environment prefix ─────────
                    // Convention: dev/*, uat/*, prod/* OR exact match dev/uat/prod
                    def envPrefix   = env.ENV_LOWER
                    def envBranches = allBranches.findAll {
                        it.startsWith("${envPrefix}/") || it == envPrefix
                    }

                    // Fallback: show all branches if no env-specific ones found
                    def branchList = envBranches ?: allBranches
                    echo "Branches available for ${params.ENVIRONMENT}: ${branchList}"

                    // ── Prompt user to select branch ──────────────────────────
                    def selectedBranch = input(
                        message: "Select a branch for ${params.ENVIRONMENT} deployment",
                        parameters: [
                            choice(
                                name: 'BRANCH',
                                choices: branchList,
                                description: "Branches filtered for ${params.ENVIRONMENT} environment"
                            )
                        ]
                    )

                    env.SELECTED_BRANCH = selectedBranch
                    echo "✅ Selected branch: ${env.SELECTED_BRANCH}"
                }
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 2 — Checkout selected branch
        // ─────────────────────────────────────────────
        stage('Checkout') {
            steps {
                echo "📦 Checking out branch: ${env.SELECTED_BRANCH} | ENV: ${params.ENVIRONMENT}"
                checkout scmGit(
                    branches: [[name: "*/${env.SELECTED_BRANCH}"]],
                    extensions: [],
                    userRemoteConfigs: [[url: "${REPO_URL}"]]
                )
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 3 — Validate tfvars file exists
        // ─────────────────────────────────────────────
        stage('Validate Config') {
            steps {
                script {
                    echo "🔎 Validating config for ENV: ${params.ENVIRONMENT}"

                    def tfvarsExists = fileExists("${TF_VAR_FILE}")
                    if (!tfvarsExists) {
                        error "❌ Missing tfvars: ${TF_VAR_FILE}. Please create it before running."
                    }
                    echo "✅ Found tfvars: ${TF_VAR_FILE}"
                }
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 4 — Terraform Init + Workspace
        // ─────────────────────────────────────────────
        stage('Terraform Init') {
            steps {
                script {
                    echo "⚙️ Initialising Terraform for ENV: ${params.ENVIRONMENT}"
                    sh "terraform init -reconfigure"

                    // Create or select workspace per environment
                    sh """
                        terraform workspace select ${TF_WORKSPACE} || \
                        terraform workspace new ${TF_WORKSPACE}
                    """
                    echo "✅ Terraform workspace: ${TF_WORKSPACE}"
                }
            }
        }

        // ─────────────────────────────────────────────
        // STAGE 5 — Terraform Action (plan/apply/destroy)
        // ─────────────────────────────────────────────
        stage('Terraform Action') {
            steps {
                script {
                    def varFile = "-var-file=${TF_VAR_FILE}"
                    def envTag  = "-var='environment=${env.ENV_LOWER}'"

                    switch (params.ACTION) {

                        case 'plan':
                            echo "📋 terraform plan — ENV: ${params.ENVIRONMENT} | BRANCH: ${env.SELECTED_BRANCH}"
                            sh "terraform plan ${varFile} ${envTag}"
                            break

                        case 'apply':
                            if (params.ENVIRONMENT in ['UAT', 'PROD']) {
                                input message: "⚠️ Confirm APPLY to ${params.ENVIRONMENT} from '${env.SELECTED_BRANCH}'?", ok: "Yes, Apply"
                            }
                            echo "🚀 terraform apply — ENV: ${params.ENVIRONMENT} | BRANCH: ${env.SELECTED_BRANCH}"
                            sh "terraform apply --auto-approve ${varFile} ${envTag}"
                            break

                        case 'destroy':
                            input message: "🔴 DANGER: Confirm DESTROY on ${params.ENVIRONMENT} from '${env.SELECTED_BRANCH}'?", ok: "Yes, Destroy"
                            echo "💣 terraform destroy — ENV: ${params.ENVIRONMENT} | BRANCH: ${env.SELECTED_BRANCH}"
                            sh "terraform destroy --auto-approve ${varFile} ${envTag}"
                            break

                        default:
                            error "❌ Unknown action: ${params.ACTION}"
                    }
                }
            }
        }
    }

    // ─────────────────────────────────────────────
    // POST — Build summary
    // ─────────────────────────────────────────────
    post {
        success {
            echo """
            ✅ Pipeline SUCCEEDED
            ───────────────────────────
            ENV      : ${params.ENVIRONMENT}
            ACTION   : ${params.ACTION}
            BRANCH   : ${env.SELECTED_BRANCH}
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
            BRANCH   : ${env.SELECTED_BRANCH ?: 'N/A'}
            WORKSPACE: ${env.TF_WORKSPACE}
            ───────────────────────────
            """
        }
        aborted {
            echo "⛔ Pipeline ABORTED — ENV: ${params.ENVIRONMENT} | ACTION: ${params.ACTION}"
        }
    }
}
