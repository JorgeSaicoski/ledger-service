package handlers

import (
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/JorgeSaicoski/ledger-service/internal/models"
	"github.com/JorgeSaicoski/ledger-service/mocks"
	"github.com/jackc/pgx/v5"
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
	expectedReq := models.TransactionRequest{
		UserID:   "user123",
		Amount:   10050,
		Currency: "usd",
	}

	expectedTransactionID := "transaction-123"

	mockValidator.EXPECT().
		ValidateTransactionRequest(expectedReq).
		Return(nil)

	// Expect repository Create call, match fields except CreatedAt
	mockRepo.EXPECT().
		Create(gomock.Any(), expectedReq).
		Return(expectedTransactionID, nil)

	// Make request
	handler.CreateTransaction(w, req)

	// Verify response
	assert.Equal(t, http.StatusCreated, w.Code)

	var responseID string
	err := json.NewDecoder(w.Body).Decode(&responseID)
	assert.NoError(t, err, "Expected transaction ID to be returned in response body")
	assert.Equal(t, expectedTransactionID, responseID)

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

	expectedReq := models.TransactionRequest{
		UserID:   "",
		Amount:   10050,
		Currency: "usd",
	}
	mockValidator.EXPECT().
		ValidateTransactionRequest(expectedReq).
		Return(errors.New("user_id is required"))

	handler.CreateTransaction(w, req)

	assert.Equal(t, 400, w.Code)
	var errResp models.ErrorResponse
	err := json.NewDecoder(w.Body).Decode(&errResp)
	assert.NoError(t, err, "Expected error response to be decoded")
	assert.Contains(t, errResp.Error, "user_id is required")
}

func TestCreateTransaction_MissingAmount(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	jsonBody := `{"user_id": "user123", "currency": "usd"}`
	req := httptest.NewRequest("POST", "/transactions", strings.NewReader(jsonBody))

	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()

	expectedReq := models.TransactionRequest{
		UserID:   "user123",
		Amount:   0,
		Currency: "usd",
	}
	mockValidator.EXPECT().
		ValidateTransactionRequest(expectedReq).
		Return(errors.New("amount is required"))

	handler.CreateTransaction(w, req)

	assert.Equal(t, 400, w.Code)
	var errResp models.ErrorResponse
	err := json.NewDecoder(w.Body).Decode(&errResp)
	assert.NoError(t, err, "Expected error response to be decoded")
	assert.Contains(t, errResp.Error, "amount is required")

}

func TestCreateTransaction_MissingCurrency(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	jsonBody := `{"user_id": "user123", "amount": 10050}`
	req := httptest.NewRequest("POST", "/transactions", strings.NewReader(jsonBody))
	req.Header.Set("Content-Type", "application/json")
	w := httptest.NewRecorder()

	expectedReq := models.TransactionRequest{
		UserID:   "user123",
		Amount:   10050,
		Currency: "",
	}
	mockValidator.EXPECT().
		ValidateTransactionRequest(expectedReq).
		Return(errors.New("currency is required"))

	handler.CreateTransaction(w, req)

	assert.Equal(t, 400, w.Code)
	var errResp models.ErrorResponse
	err := json.NewDecoder(w.Body).Decode(&errResp)
	assert.NoError(t, err, "Expected error response to be decoded")
	assert.Contains(t, errResp.Error, "currency is required")
}

func TestCreateTransaction_InvalidJSON(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	// Invalid JSON - missing closing brace
	jsonBody := `{"user_id": "user123", "amount": 10050`

	req := httptest.NewRequest("POST", "/transactions", strings.NewReader(jsonBody))
	req.Header.Set("Content-Type", "application/json")

	w := httptest.NewRecorder()
	handler.CreateTransaction(w, req)

	assert.Equal(t, 400, w.Code)
}

// Test GetTransaction endpoint

func TestGetTransaction_Success(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	transactionID := "transaction-123"

	expectedTransaction := models.Transaction{
		ID:       transactionID,
		UserID:   "user123",
		Amount:   10050,
		Currency: "usd",
	}

	// Mock repository GetByID to return transaction
	mockRepo.EXPECT().GetByID(gomock.Any(), transactionID).Return(&expectedTransaction, nil)

	// Make request
	req := httptest.NewRequest("GET", "/transactions?id="+transactionID, nil)
	w := httptest.NewRecorder()
	handler.GetTransaction(w, req)

	// Verify response
	assert.Equal(t, 200, w.Code)

	// Verify transaction returned in the response body
	var actualTransaction models.Transaction
	err := json.NewDecoder(w.Body).Decode(&actualTransaction)
	assert.NoError(t, err, "Expected transaction to be returned in response body")
	assert.Equal(t, expectedTransaction, actualTransaction)

}

func TestGetTransaction_NotFound(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	transactionID := "transaction-123"

	// Mock repository GetByID to return error
	mockRepo.EXPECT().GetByID(gomock.Any(), transactionID).Return(nil, pgx.ErrNoRows)

	req := httptest.NewRequest("GET", "/transactions?id="+transactionID, nil)
	w := httptest.NewRecorder()
	handler.GetTransaction(w, req)

	assert.Equal(t, 404, w.Code)

	// Verify error response returned
	var errResp models.ErrorResponse
	err := json.NewDecoder(w.Body).Decode(&errResp)
	assert.NoError(t, err, "Expected error response to be decoded")
	assert.Equal(t, "Transaction not found", errResp.Error)

}

// Test ListTransactions endpoint

func TestListTransactions_ByUser(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()

	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	expectedTransactions := []models.Transaction{
		{ID: "transaction-123", UserID: "user123", Amount: 10050, Currency: "usd"},
		{ID: "transaction-456", UserID: "user123", Amount: -10050, Currency: "usd"},
		{ID: "transaction-789", UserID: "user123", Amount: 10050, Currency: "eur"},
		{ID: "transaction-012", UserID: "user123", Amount: -10050, Currency: "eur"},
		{ID: "transaction-345", UserID: "user456", Amount: 10050, Currency: "usd"},
		{ID: "transaction-678", UserID: "user456", Amount: -10050, Currency: "usd"},
		{ID: "transaction-901", UserID: "user456", Amount: 10050, Currency: "eur"},
	}

	mockRepo.EXPECT().ListByUser(gomock.Any(), "user123", nil, 0, 0).Return(expectedTransactions, nil)

	req := httptest.NewRequest("GET", "/transactions?user_id=user123", nil)

	w := httptest.NewRecorder()
	handler.ListTransactions(w, req)

	assert.Equal(t, 200, w.Code)

	var actualTransactions []models.Transaction
	err := json.NewDecoder(w.Body).Decode(&actualTransactions)
	assert.NoError(t, err, "Expected transactions to be returned in response body")
	assert.Equal(t, expectedTransactions, actualTransactions)

}

func TestListTransactions_MissingUserID(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()
	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	req := httptest.NewRequest("GET", "/transactions", nil)
	w := httptest.NewRecorder()
	handler.ListTransactions(w, req)

	assert.Equal(t, 400, w.Code)
	var errResp models.ErrorResponse
	err := json.NewDecoder(w.Body).Decode(&errResp)
	assert.NoError(t, err, "Expected error response to be decoded")
	assert.Contains(t, errResp.Error, "missing user ID")
}

func TestListTransactions_EmptyResult(t *testing.T) {
	ctrl := gomock.NewController(t)
	defer ctrl.Finish()
	mockRepo := mocks.NewMockTransactionRepository(ctrl)
	mockValidator := mocks.NewMockValidator(ctrl)
	handler := NewTransactionHandler(mockRepo, mockValidator)

	mockRepo.EXPECT().ListByUser(gomock.Any(), "user123", nil, 0, 0).Return([]models.Transaction{}, nil)

	req := httptest.NewRequest("GET", "/transactions?user_id=user123", nil)
	w := httptest.NewRecorder()
	handler.ListTransactions(w, req)

	assert.Equal(t, 200, w.Code)
	var actualTransactions []models.Transaction
	err := json.NewDecoder(w.Body).Decode(&actualTransactions)
	assert.NoError(t, err, "Expected empty list of transactions")
	assert.Empty(t, actualTransactions)
}
