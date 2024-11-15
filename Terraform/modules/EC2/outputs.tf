output "app_sg" {
    value = aws_security_group.app_sg.id
}

output "app1" {
    value = aws_instance.app1.id
}

output "app2" {
    value = aws_instance.app2.id
}