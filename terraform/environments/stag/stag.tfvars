environment = "stag"
cluster_name = "bankingapp-stag-eks"
vpc_cidr = "10.0.0.0/16"
node_instance_type = "t3.medium"
node_desired_capacity = 2
node_min_size = 1
node_max_size = 3
db_instance_class = "db.t3.micro"