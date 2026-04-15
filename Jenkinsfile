pipeline {
    agent any

    environment {
        ENV = "DEV"
        TF_WORKSPACE = "dev"
    }

    stages {

        stage('Checkout') {
            steps {
                echo "📦 Checking out branch: main | ENV: ${ENV}"
                git branch: 'main', url: 'https://github.com/omkardvd/Terraform-Automation.git'
            }
        }

        stage('Terraform Init') {
            steps {
                echo "⚙️ Initialising Terraform — ENV: ${ENV}"
                sh 'terraform init -reconfigure'
            }
        }

        stage('Terraform Plan') {
            steps {
                echo "📊 Running Terraform Plan"
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            when {
                expression { return params.ACTION == 'apply' }
            }
            steps {
                echo "🚀 Applying Terraform changes"
                sh 'terraform apply -auto-approve'
            }
        }
    }

    post {
        success {
            echo """
            ✅ Pipeline SUCCESS
            ───────────────────────────
            ENV      : ${ENV}
            WORKSPACE: ${TF_WORKSPACE}
            ───────────────────────────
            """
        }
        failure {
            echo """
            ❌ Pipeline FAILED
            ───────────────────────────
            ENV      : ${ENV}
            WORKSPACE: ${TF_WORKSPACE}
            ───────────────────────────
            """
        }
    }
}
