package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestVersion(t *testing.T) {
	expectedSubstring := "Go version: go1.22.0"
	versionStr := GetVersion()
	assert.Contains(t, versionStr, expectedSubstring, "GetVersion() should contain the expected substring")
}
