package tests

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

func TestVPCModule(t *testing.T) {
	t.Parallel()

	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: "../examples/vpc-simple",
		Vars: map[string]interface{}{},
	})

	defer terraform.Destroy(t, terraformOptions)
	terraform.InitAndApply(t, terraformOptions)

	// Verify outputs
	vpcID := terraform.Output(t, terraformOptions, "vpc_id")
	assert.NotEmpty(t, vpcID, "VPC ID should not be empty")

	publicSubnets := terraform.OutputList(t, terraformOptions, "public_subnets")
	assert.Equal(t, 2, len(publicSubnets), "Should have 2 public subnets")

	privateSubnets := terraform.OutputList(t, terraformOptions, "private_subnets")
	assert.Equal(t, 2, len(privateSubnets), "Should have 2 private subnets")
}
