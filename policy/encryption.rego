# policy/encryption.rego
# Enforces encryption at rest for storage resources.
#
# Rules:
#   - aws_db_instance:                   storage_encrypted must be true
#   - aws_elasticache_replication_group: at_rest_encryption_enabled must be true
#   - aws_secretsmanager_secret:         always encrypted by default — no check needed

package terraform.encryption

import rego.v1

# RDS: storage_encrypted = true
violations contains msg if {
    some change in input.resource_changes
    change.type == "aws_db_instance"
    change.change.actions != ["delete"]
    not change.change.after.storage_encrypted == true
    msg := sprintf("aws_db_instance %q must have storage_encrypted = true", [change.address])
}

# ElastiCache: at_rest_encryption_enabled = true
violations contains msg if {
    some change in input.resource_changes
    change.type == "aws_elasticache_replication_group"
    change.change.actions != ["delete"]
    not change.change.after.at_rest_encryption_enabled == true
    msg := sprintf(
        "aws_elasticache_replication_group %q must have at_rest_encryption_enabled = true",
        [change.address],
    )
}

deny contains msg if {
    some msg in violations
}
