pipeline {
    agent any
        environment {
        USR_VAR_BRANCH_NAME_SOURCE = "${BRANCH_NAME}" // Using Jenkins built-in variable
        USR_VAR_BRANCH_NAME_TARGET = 'main' // Hardcoded value
        USR_VAR_COMMIT_ID = "${GIT_COMMIT}" // Using Jenkins built-in variable
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Find Changed Terraform Directories') {
            steps {
                script {
                    def tf_plan_dirs = [] 

                    if (env.BUILD_REASON == 'Manual') {
                        // Find all directories with *.tf files
                        tf_plan_dirs = findFiles(glob: '**/*.tf').collect { 
                            it.path.split('/')[0..-2].join('/')  // Extract directory path
                        }.unique() 
                    } else {
                        if (env.USR_VAR_BRANCH_NAME_SOURCE == env.USR_VAR_BRANCH_NAME_TARGET) {
                            // Get parent commits of the merge commit
                            def mergeCommitParents = sh(returnStdout: true, script: "git rev-list --parents ${env.USR_VAR_COMMIT_ID} -n 1").trim().split()
                            def parent1 = mergeCommitParents[0]
                            def parent2 = mergeCommitParents[1]

                            // Find changed directories by comparing parent commits
                            tf_plan_dirs = sh(returnStdout: true, script: "git --no-pager diff --name-only ${parent1} ${parent2} -- '*.tf' | xargs dirname | sort | uniq").trim().split('\n')
                        } else {
                            // Find common ancestor and compare with current commit
                            sh "git checkout ${env.USR_VAR_BRANCH_NAME_TARGET}"
                            sh "git checkout ${env.USR_VAR_BRANCH_NAME_SOURCE}"
                            def commonAncestor = sh(returnStdout: true, script: "git merge-base ${env.USR_VAR_BRANCH_NAME_TARGET} ${env.USR_VAR_BRANCH_NAME_SOURCE}").trim()
                            tf_plan_dirs = sh(returnStdout: true, script: "git --no-pager diff --name-only ${env.USR_VAR_COMMIT_ID} ${commonAncestor} -- '*.tf' | xargs dirname | sort | uniq").trim().split('\n')
                        }
                    }

                    echo "Terraform Plans changed by this PR are: ${tf_plan_dirs.join(', ')}"
                }
            }
        }

        // Add stages for Terraform Plan/Apply based on tf_plan_dirs
    }
}
