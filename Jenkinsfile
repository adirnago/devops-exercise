pipeline {
    agent any

    parameters {
        choice(
            name: 'TF_ACTION',
            choices: ['plan', 'apply', 'destroy'],
            description: 'Terraform action to run'
        )
        choice(
            name: 'CLUSTER',
            choices: ['cluster-a', 'cluster-b'],
            description: 'Which cluster to target'
        )
        string(
            name: 'WEB_SERVER_COUNT',
            defaultValue: '2',
            description: 'Number of web servers'
        )
        string(
            name: 'WEB_SERVER_VERSION',
            defaultValue: '1.0.0',
            description: 'Version of web servers'
        )
    }

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
        AWS_DEFAULT_REGION    = 'us-east-1'
        TF_IN_AUTOMATION      = 'true'
    }

    options {
        timestamps()
        timeout(time: 60, unit: 'MINUTES')
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
                sh 'terraform version'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init -upgrade'
            }
        }

        stage('Select Workspace') {
            steps {
                sh """
                    terraform workspace select ${params.CLUSTER} || \
                    terraform workspace new ${params.CLUSTER}
                """
            }
        }

        stage('Terraform Plan') {
            steps {
                sh """
                    terraform plan \
                        -var="cluster_name=${params.CLUSTER}" \
                        -var="web_server_count=${params.WEB_SERVER_COUNT}" \
                        -var="web_server_version=${params.WEB_SERVER_VERSION}" \
                        -out=tfplan
                """
            }
        }

        stage('Approval') {
            when {
                expression { params.TF_ACTION in ['apply', 'destroy'] }
            }
            steps {
                input message: "Approve ${params.TF_ACTION} for ${params.CLUSTER}?",
                      ok: "Yes, ${params.TF_ACTION}!"
            }
        }

        stage('Terraform Apply') {
            when {
                expression { params.TF_ACTION == 'apply' }
            }
            steps {
                sh 'terraform apply -auto-approve tfplan'
            }
        }

        stage('Terraform Destroy') {
            when {
                expression { params.TF_ACTION == 'destroy' }
            }
            steps {
                sh """
                    terraform destroy \
                        -var="cluster_name=${params.CLUSTER}" \
                        -var="web_server_count=${params.WEB_SERVER_COUNT}" \
                        -var="web_server_version=${params.WEB_SERVER_VERSION}" \
                        -auto-approve
                """
            }
        }
    }

    post {
        success {
            echo "✅ ${params.TF_ACTION} completed successfully for ${params.CLUSTER}"
        }
        failure {
            echo "❌ Pipeline failed for ${params.CLUSTER}"
        }
        always {
            cleanWs()
        }
    }
}
