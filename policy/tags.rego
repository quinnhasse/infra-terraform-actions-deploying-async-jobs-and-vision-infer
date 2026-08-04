# policy/tags.rego
# Enforces that every AWS resource managed by Terraform carries the required tags.
#
# Required tags:
#   - Environment  (staging | prod)
#   - ManagedBy    (terraform)
#   - Service      (any non-empty string)

package terraform.tags

import rego.v1

required_tags := {"Environment", "ManagedBy", "Service"}

# Collect all resource changes from the plan.
resource_changes := input.resource_changes

# Identify resources missing one or more required tags.
violations contains msg if {
    some change in resource_changes
    change.change.actions != ["delete"]   # deletes don't need tag checks
    not change.type == "data"
    tags := object.get(change.change.after, "tags", {})
    missing := required_tags - {k | tags[k]}
    count(missing) > 0
    msg := sprintf(
        "resource %q (%s) is missing required tags: %v",
        [change.address, change.type, missing],
    )
}

# Deny if any violation exists.
deny contains msg if {
    some msg in violations
}
