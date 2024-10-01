pipeline {
    agent any

    environment {
        TF_PLAN_DIRS = ""
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    // Determine the branch name
                    if (env.CHANGE_BRANCH) {
                        env.BRANCH_NAME = env.CHANGE_BRANCH
                    } else if (env.GIT_BRANCH) {
                        env.BRANCH_NAME = env.GIT_BRANCH
                    } else {
                        env.BRANCH_NAME = env.GITHUB_REF.replace('refs/heads/', '')
                    }

                    echo "Building branch: ${env.BRANCH_NAME}"
                }                
            }
        }

        stage('Find Changed Terraform Directories') {
            steps {
                script {
                    def tf_plan_dirs = []

                    if (env.BUILD_REASON == 'Manual') {
                        // Find all directories with *.tf files (for manual triggers)
                        tf_plan_dirs = findFiles(glob: '**/*.tf').collect {
                            it.path.split('/')[0..-2].join('/')
                        }.unique()
                    } else {
                        if (env.BRANCH_NAME != 'main') {
                            // For Merge Requests, compare with the target branch
                            sh "git checkout main"
                            sh "git checkout ${env.BRANCH_NAME}"
                            def commonAncestor = sh(returnStdout: true, script: "git merge-base main ${env.BRANCH_NAME}").trim()
                            tf_plan_dirs = sh(returnStdout: true, script: "git --no-pager diff --name-only ${env.GIT_COMMIT} ${commonAncestor} -- '*.tf' | xargs dirname | sort | uniq").trim().split('\n')
                        } else {
                            // For merges to main, compare the merge commit's parents
                            def mergeCommitParents = sh(returnStdout: true, script: "git rev-list --parents ${env.GIT_COMMIT} -n 1").trim().split()
                            def parent1 = mergeCommitParents[0]
                            def parent2 = mergeCommitParents[1]
                            tf_plan_dirs = sh(returnStdout: true, script: "git --no-pager diff --name-only ${parent1} ${parent2} -- '*.tf' | xargs dirname | sort | uniq").trim().split('\n')
                        }
                    }

                    env.TF_PLAN_DIRS = tf_plan_dirs.join(',')
                    echo "Terraform Plans changed by this PR/Merge are: ${env.TF_PLAN_DIRS}"
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { env.BRANCH_NAME != 'main' } // Run for Merge Requests
            }
            steps {
                script {
                    for (dir in env.TF_PLAN_DIRS.tokenize(',')) {
                        dir = dir.trim()
                        if (dir) {
                            echo "Running Terraform plan for directory: ${dir}"
                            dir(dir) {
                                container('terraform') {
                                    sh 'terraform init'
                                    sh 'terraform validate'
                                    sh 'terraform plan'
                                }
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { env.BRANCH_NAME == 'main' } // Run after merge to main
            }
            steps {
                script {
                    for (dir in env.TF_PLAN_DIRS.tokenize(',')) {
                        dir = dir.trim()
                        if (dir) {
                            echo "Running Terraform apply for directory: ${dir}"
                            dir(dir) {
                                container('terraform') {
                                    sh 'terraform init'
                                    sh 'terraform plan'
                                    sh 'terraform apply -auto-approve' 
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
