package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/bardockgaucho/ledger-service/internal/models"
	"github.com/bardockgaucho/ledger-service/internal/repository"
	"github.com/bardockgaucho/ledger-service/internal/validator"
)

// TransactionHandler handles HTTP requests for transactions
type TransactionHandler struct {
	repo      repository.TransactionRepository
	validator *validator.TransactionValidator
}

// NewTransactionHandler creates a new transaction handler
func NewTransactionHandler(repo repository.TransactionRepository, validator *validator.TransactionValidator) *TransactionHandler {
	return &TransactionHandler{
		repo:      repo,
		validator: validator,
	}
}

// CreateTransaction handles POST /transactions
func (h *TransactionHandler) CreateTransaction(w http.ResponseWriter, r *http.Request) {
	// TODO: implement this
	w.WriteHeader(http.StatusNotImplemented)
	json.NewEncoder(w).Encode(models.ErrorResponse{Error: "not implemented"})
}

// GetTransaction handles GET /transactions/{id}
func (h *TransactionHandler) GetTransaction(w http.ResponseWriter, r *http.Request) {
	// TODO: implement this
	w.WriteHeader(http.StatusNotImplemented)
	json.NewEncoder(w).Encode(models.ErrorResponse{Error: "not implemented"})
}

// ListTransactions handles GET /transactions?user_id=X&currency=Y
func (h *TransactionHandler) ListTransactions(w http.ResponseWriter, r *http.Request) {
	// TODO: implement this
	w.WriteHeader(http.StatusNotImplemented)
	json.NewEncoder(w).Encode(models.ErrorResponse{Error: "not implemented"})
}

// Helper functions

// writeJSON writes a JSON response with the given status code
func (h *TransactionHandler) writeJSON(w http.ResponseWriter, status int, data interface{}) {
	// TODO: implement this
}

// writeError writes an error response
func (h *TransactionHandler) writeError(w http.ResponseWriter, status int, message string) {
	// TODO: implement this
}
