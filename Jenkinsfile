pipeline {
    agent any

    parameters {
        choice(name: 'ENV', choices: ['DEV', 'UAT', 'PROD'], description: 'Select Environment')
        choice(name: 'ACTION', choices: ['plan', 'apply'], description: 'Terraform Action')
        string(name: 'BRANCH',defaultValue: 'main',description: 'Enter the branch name to checkout')
    }

    environment {
        TF_WORKSPACE = "${params.ENV.toLowerCase()}"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📦 Checking out branch: main | ENV: ${params.ENV}"
                git branch: 'main', url: 'https://github.com/omkardvd/Terraform-Automation.git'
            }
        }

        stage('Terraform Init') {
            steps {
                echo "⚙️ Initialising Terraform — ENV: ${params.ENV}"
                sh 'terraform init -reconfigure'
            }
        }

        stage('Terraform Plan') {
            when {
                expression { params.ACTION == 'plan' }
            }
            steps {
                echo "📊 Running Terraform Plan for ${params.ENV}"
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.ACTION == 'apply' }
            }
            steps {
                echo "🚀 Applying Terraform for ${params.ENV}"
                sh 'terraform apply -auto-approve'
            }
        }
    }

    post {
        success {
            echo """
            ✅ Pipeline SUCCESS
            ───────────────────────────
            ENV      : ${params.ENV}
            ACTION   : ${params.ACTION}
            WORKSPACE: ${TF_WORKSPACE}
            ───────────────────────────
            """
        }
        failure {
            echo """
            ❌ Pipeline FAILED
            ───────────────────────────
            ENV      : ${params.ENV}
            ACTION   : ${params.ACTION}
            WORKSPACE: ${TF_WORKSPACE}
            ───────────────────────────
            """
        }
    }
}
