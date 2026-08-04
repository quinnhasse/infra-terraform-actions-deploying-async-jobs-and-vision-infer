# policy/public_access.rego
# Blocks resources that would be publicly accessible.
#
# Rules:
#   - aws_db_instance:  publicly_accessible must be false
#   - aws_ecs_service:  assign_public_ip must be false on network_configuration

package terraform.public_access

import rego.v1

# RDS must not be publicly accessible.
violations contains msg if {
    some change in input.resource_changes
    change.type == "aws_db_instance"
    change.change.actions != ["delete"]
    change.change.after.publicly_accessible == true
    msg := sprintf("aws_db_instance %q must have publicly_accessible = false", [change.address])
}

# ECS tasks must not get public IPs.
violations contains msg if {
    some change in input.resource_changes
    change.type == "aws_ecs_service"
    change.change.actions != ["delete"]
    some nc in change.change.after.network_configuration
    nc.assign_public_ip == true
    msg := sprintf("aws_ecs_service %q must have assign_public_ip = false", [change.address])
}

deny contains msg if {
    some msg in violations
}
