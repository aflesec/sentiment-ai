// Jenkinsfile- Pipeline CI/CD SentimentAI
pipeline {
agent any // s’exécute sur n’importe quel agent disponible
environment {
IMAGE_NAME = ’sentiment-ai’
REGISTRY = ’ghcr.io/VOTRE_PSEUDO’ // remplacez VOTRE_PSEUDO
// IMAGE_TAG = SHA Git court du commit (ex: a3f8c12)
// Chaque build produit une image taguée de façon unique et traçable
IMAGE_TAG = sh(script: ’git rev-parse--short HEAD’, returnStdout:
true).trim()
}
stages {
// Les 4 stages sont définis dans les sections suivantes
}
post {
always {
// Nettoyer les conteneurs de test, qu’il y ait succès ou échec
sh ’docker compose down-v 2>/dev/null || true’
}
success {
echo "Pipeline réussi ! Image : ${REGISTRY}/${IMAGE_NAME}:${
IMAGE_TAG}"
}
failure {
echo ’Pipeline échoué. Consultez les logs ci-dessus.’
}
}
}