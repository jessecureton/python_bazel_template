package main

import (
	"strings"
	"testing"
)

func TestVersion(t *testing.T) {
	expectedSubstring := "Go version: go1.22.0"
	versionStr := GetVersion()
	if !strings.Contains(versionStr, expectedSubstring) {
		t.Errorf("GetVersion() = %v, want substring %v", versionStr, expectedSubstring)
	}
}
