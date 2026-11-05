output "repository_urls" {
  value = {
    for name, repository in aws_ecr_repository.app :
    name => repository.repository_url
  }
}