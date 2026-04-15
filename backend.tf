terraform {
  backend "s3" {
    bucket = "amezon-s3-odc"
    key = "main"
    region = "us-east-1"
    dynamodb_table = "my-dynamodb-table"
  }
}
