package handlers

import (
	"encoding/json"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/JorgeSaicoski/ledger-service/internal/models"
	"github.com/JorgeSaicoski/ledger-service/mocks"
	"github.com/stretchr/testify/assert"
	"go.uber.org/mock/gomock"
)

func TestCreateTransaction_Success(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	jsonBody := `{"user_id": "user123", "amount": 10050, "currency": "usd"}`

	// Create request
	req := httptest.NewRequest("POST", "/transactions", strings.NewReader(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	// Create response recorder
	w := httptest.NewRecorder()

	// Expected Request Model
	expectedReq := models.Transaction{
		UserID:   "user123",
		Amount:   10050,
		Currency: "usd",
	}

	// Mock repository Create to return transaction ID
	expectedTransactionID := "transaction-123"
	mockRepo.EXPECT().
		Create(gomock.Any(), expectedReq).
		Return(expectedTransactionID, nil)

	// Make request
	handler.CreateTransaction(w, req)

	// Verify response
	if w.Code != 201 {
		t.Errorf("Expected status code 201, got %d", w.Code)
	}
	assert.Equal(t, expectedTransactionID, w.Body.String())

	err := json.NewDecoder(w.Body).Decode(&expectedTransactionID)
	assert.NoError(t, err, "Expected transaction ID to be returned in response body")
	assert.Equal(t, expectedTransactionID, w.Body.String())

}

func TestCreateTransaction_MissingUserID(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	jsonBody := `{"amount": 10050, "currency": "usd"}`

	req := httptest.NewRequest("POST", "/transactions", strings.NewReader(jsonBody))

	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()

	handler.CreateTransaction(w, req)

	assert.Equal(t, 400, w.Code)
	// Test that missing user_id returns 400
}

func TestCreateTransaction_MissingAmount(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Test that missing amount returns 400
}

func TestCreateTransaction_MissingCurrency(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Test that missing currency returns 400
}

func TestCreateTransaction_InvalidJSON(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Test that invalid JSON returns 400
}

func TestCreateTransaction_NegativeAmount(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Test that negative amounts are accepted
}

// Test GetTransaction endpoint

func TestGetTransaction_Success(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Create mock transaction
	// Mock repository GetByID to return transaction
	// Make request
	// Verify 200 response with correct data
}

func TestGetTransaction_NotFound(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Mock repository GetByID to return error
	// Make request
	// Verify 404 response
}

func TestGetTransaction_InvalidUUID(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Make request with invalid UUID
	// Verify 400 response
}

// Test ListTransactions endpoint

func TestListTransactions_ByUser(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Mock repository to return transactions
	// Make request with user_id param
	// Verify 200 response with transactions array
}

func TestListTransactions_ByUserAndCurrency(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Mock repository to return filtered transactions
	// Make request with user_id and currency params
	// Verify correct filtering
}

func TestListTransactions_MissingUserID(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Make request without user_id
	// Verify 400 response
}

func TestListTransactions_WithPagination(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Test limit and offset parameters
}

func TestListTransactions_EmptyResult(t *testing.T) {
	t.Skip("Implement after handler is complete")

	// Mock repository to return empty array
	// Verify 200 response with empty transactions array
}
