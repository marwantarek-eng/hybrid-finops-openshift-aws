resource "aws_db_instance" "postgres" {
  instance_class    = "db.t3.micro"
  allocated_storage = 20
  engine            = "postgres"
  username          = var.db_username
  password          = random_password.password.result
  engine_version  = "15"
  db_name= "finopsdb"

  db_subnet_group_name = module.vpc.database_subnet_group_name
  vpc_security_group_ids = [module.security_group.id]
  publicly_accessible = true
  skip_final_snapshot = true
  deletion_protection = false

  tags = {
    Name        = "finops-postgres-db"
    Environment = "dev"
  }

}

