package handlers

//go:generate mockgen -destination=../../mocks/mock_handler.go -package=mocks github.com/JorgeSaicoski/ledger-service/internal/handlers TransactionHandler
import (
	"encoding/json"
	"net/http"

	"github.com/JorgeSaicoski/ledger-service/internal/models"
	"github.com/JorgeSaicoski/ledger-service/internal/repository"
	"github.com/JorgeSaicoski/ledger-service/internal/validator"
)

// Handler handles HTTP requests for transactions
type Handler struct {
	repo      repository.Repository
	validator validator.Validator
}

// NewTransactionHandler creates a new transaction handler
func NewTransactionHandler(repo repository.Repository, validator validator.Validator) *Handler {
	return &Handler{
		repo:      repo,
		validator: validator,
	}
}

// CreateTransaction handles POST /transactions
func (h *Handler) CreateTransaction(w http.ResponseWriter, r *http.Request) {
	// TODO: implement this
	w.WriteHeader(http.StatusNotImplemented)
	json.NewEncoder(w).Encode(models.ErrorResponse{Error: "not implemented"})
}

// GetTransaction handles GET /transactions/{id}
func (h *Handler) GetTransaction(w http.ResponseWriter, r *http.Request) {
	// TODO: implement this
	w.WriteHeader(http.StatusNotImplemented)
	json.NewEncoder(w).Encode(models.ErrorResponse{Error: "not implemented"})
}

// ListTransactions handles GET /transactions?user_id=X&currency=Y
func (h *Handler) ListTransactions(w http.ResponseWriter, r *http.Request) {
	// TODO: implement this
	w.WriteHeader(http.StatusNotImplemented)
	json.NewEncoder(w).Encode(models.ErrorResponse{Error: "not implemented"})
}

// Helper functions

// writeJSON writes a JSON response with the given status code
func (h *Handler) writeJSON(w http.ResponseWriter, status int, data interface{}) {
	// TODO: implement this
}

// writeError writes an error response
func (h *Handler) writeError(w http.ResponseWriter, status int, message string) {
	// TODO: implement this
}
