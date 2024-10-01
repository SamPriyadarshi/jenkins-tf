pipeline {
    agent any

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
                            // Capture the output of git diff and check if it's empty
                            def gitDiffOutput = sh(returnStdout: true, script: "git --no-pager diff --name-only ${env.GIT_COMMIT} ${commonAncestor} -- '*.tf'").trim()
                            if (gitDiffOutput) {  // Only proceed if there's output
                                tf_plan_dirs = sh(returnStdout: true, script: "echo '${gitDiffOutput}' | xargs dirname | sort | uniq").trim().split('\n')
                            }
                        } else {
                            // For merges to main, compare the merge commit's parents
                            def mergeCommitParents = sh(returnStdout: true, script: "git rev-list --parents ${env.GIT_COMMIT} -n 1").trim().split()
                            def parent1 = mergeCommitParents[0]
                            def parent2 = mergeCommitParents[1]
                            // Capture the output of git diff and check if it's empty
                            def gitDiffOutput = sh(returnStdout: true, script: "git --no-pager diff --name-only ${parent1} ${parent2} -- '*.tf'").trim()
                            if (gitDiffOutput) {  // Only proceed if there's output
                                tf_plan_dirs = sh(returnStdout: true, script: "echo '${gitDiffOutput}' | xargs dirname | sort | uniq").trim().split('\n')
                            }
                        }
                    }

                    // Handle empty tf_plan_dirs
                    if (tf_plan_dirs == null) {
                        echo "No Terraform files changed."
                        env.TF_PLAN_DIRS = "" // Set to empty string
                    } else {
                        env.TF_PLAN_DIRS = tf_plan_dirs.join(',')
                        echo "Terraform Plans changed by this PR/Merge are: ${env.TF_PLAN_DIRS}"
                    }
                }
            }
        }

        stage('Terraform Plan') {
            when {
                expression { env.BRANCH_NAME != 'main' && env.TF_PLAN_DIRS?.trim() } // Run for Merge Requests
            }
            steps {
                script {
                    for (dir in env.TF_PLAN_DIRS.tokenize(',')) {
                        dir = dir.trim()
                        if (dir) {
                            echo "Running Terraform plan for directory: ${dir}"
                            sh "cd ${dir}"
                            dir(dir) {
                                echo "inside dir"
                                echo ${dir}
                            }
                        }
                    }
                }
            }
        }

        stage('Terraform Apply') {
            when {
                expression { env.BRANCH_NAME == 'main' && env.TF_PLAN_DIRS?.trim() } // Run after merge to main
            }
            steps {
                script {
                    for (dir in env.TF_PLAN_DIRS.tokenize(',')) {
                        dir = dir.trim()
                        if (dir) {
                            echo "Running Terraform apply for directory: ${dir}"
                            dir(dir) {
                                sh 'terraform init -reconfigure'
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
