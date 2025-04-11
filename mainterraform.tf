# --- Proveedor AWS ---
provider "aws" {
  region = "us-east-1"
}

# --- VPC ---
resource "aws_vpc" "VPC_Actividad_3" {
  cidr_block = "10.10.0.0/20"

  tags = {
    Name = "VPC-Actividad_3"
  }
}

# --- Subred pública ---
resource "aws_subnet" "subred_publica_actividad_3" {
  vpc_id                  = aws_vpc.VPC_Actividad_3.id
  cidr_block              = "10.10.0.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "subred_publica_actividad_3"
  }
}

# --- Internet Gateway ---
resource "aws_internet_gateway" "IGW_Actividad_3" {
  vpc_id = aws_vpc.VPC_Actividad_3.id

  tags = {
    Name = "IGW_Actividad_3"
  }
}

# --- Tabla de ruteo pública ---
resource "aws_route_table" "tabla_rutas_publica_actividad_3" {
  vpc_id = aws_vpc.VPC_Actividad_3.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW_Actividad_3.id
  }

  tags = {
    Name = "Tabla-Rutas-Publica-Actividad_3"
  }
}

# --- Asociación tabla de rutas a subred pública ---
resource "aws_route_table_association" "asociacion_ruta_publica" {
  subnet_id      = aws_subnet.subred_publica_actividad_3.id
  route_table_id = aws_route_table.tabla_rutas_publica_actividad_3.id
}

# --- Security Group: Linux-Jump-Server ---
resource "aws_security_group" "linux_jump_sg" {
  name        = "sg_jump_linux"
  description = "Grupo de seguridad para el servidor Linux Jump"
  vpc_id      = aws_vpc.VPC_Actividad_3.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Security Group: Linux-Web Server ---
resource "aws_security_group" "linux_web_sg_1" {
  name        = "sg_web_linux_1"
  description = "Grupo de seguridad para los servidores Linux Web"
  vpc_id      = aws_vpc.VPC_Actividad_3.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.linux_jump_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- Instancia Linux Jump Server ---
resource "aws_instance" "linux_jump_server" {
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subred_publica_actividad_3.id
  vpc_security_group_ids = [aws_security_group.linux_jump_sg.id]
  key_name               = "vockey"

  tags = {
    Name = "Jump-Server-Linux"
  }
}

# --- Instancias Linux Web Server ---
resource "aws_instance" "linux_web_server" {
  count                  = 3
  ami                    = "ami-0c02fb55956c7d316"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.subred_publica_actividad_3.id
  vpc_security_group_ids = [aws_security_group.linux_web_sg_1.id]
  key_name               = "vockey"

  tags = {
    Name = "Linux-Web-Server-${count.index + 1}"
  }
}

# --- Outputs ---
output "linux_web_servers" {
  value       = [for s in aws_instance.linux_web_server : s.tags["Name"]]
  description = "Nombres de los servidores Linux Web"
}

output "linux_jump_server" {
  value       = aws_instance.linux_jump_server.tags["Name"]
  description = "Nombre del servidor Jump Server Linux"
}