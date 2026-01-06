package handlers

//go:generate mockgen -destination=../../mocks/mock_handler.go -package=mocks github.com/JorgeSaicoski/ledger-service/internal/handlers TransactionHandler
import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/JorgeSaicoski/ledger-service/internal/models"
	"github.com/JorgeSaicoski/ledger-service/internal/repository"
	"github.com/JorgeSaicoski/ledger-service/internal/validator"
	"github.com/jackc/pgx/v5"
)

// Interface for transaction handlers

type TransactionHandler interface {
	CreateTransaction(w http.ResponseWriter, r *http.Request)
	GetTransaction(w http.ResponseWriter, r *http.Request)
	ListTransactions(w http.ResponseWriter, r *http.Request)
}

var _ TransactionHandler = (*Handler)(nil)

// Handler handles HTTP requests for transactions
type Handler struct {
	repo      repository.Repository
	validator validator.Validator
}

type Filter struct {
	UserID   string `json:"user_id"`
	Currency string `json:"currency"`
	Limit    int    `json:"limit"`
	Offset   int    `json:"offset"`
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
	// Get the request body and validate it
	req := models.TransactionRequest{}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		h.writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := h.validator.ValidateTransactionRequest(req); err != nil {
		h.writeError(w, http.StatusBadRequest, err.Error())
		return
	}

	ctx := r.Context()

	id, err := h.repo.Create(ctx, req)

	if err != nil {
		h.writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.writeJSON(w, http.StatusCreated, id)
}

// GetTransaction handles GET /transactions/{id}
func (h *Handler) GetTransaction(w http.ResponseWriter, r *http.Request) {
	reqID := r.URL.Query().Get("id")
	if reqID == "" {
		h.writeError(w, http.StatusBadRequest, "missing transaction ID")
		return
	}

	ctx := r.Context()

	var transaction *models.Transaction
	transaction, err := h.repo.GetByID(ctx, reqID)
	if err != nil {
		if err == pgx.ErrNoRows {
			h.writeError(w, http.StatusNotFound, "Transaction not found")
			return
		}
		h.writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.writeJSON(w, http.StatusOK, transaction)
}

// ListTransactions handles GET /transactions?user_id=X&currency=Y
func (h *Handler) ListTransactions(w http.ResponseWriter, r *http.Request) {
	reqUserID := r.URL.Query().Get("user_id")
	if reqUserID == "" {
		h.writeError(w, http.StatusBadRequest, "missing user ID")
		return
	}

	var reqCurrency *string

	if currency := r.URL.Query().Get("currency"); currency != "" {
		reqCurrency = &currency
	}

	strLimit := r.URL.Query().Get("limit")
	limit := 0
	if strLimit != "" {
		l, err := strconv.Atoi(strLimit)
		if err != nil {
			h.writeError(w, http.StatusBadRequest, "invalid limit")
			return
		}
		limit = l
	}

	strOffset := r.URL.Query().Get("offset")
	offset := 0
	if strOffset != "" {
		o, err := strconv.Atoi(strOffset)
		if err != nil {
			h.writeError(w, http.StatusBadRequest, "invalid offset")
			return
		}
		offset = o
	}

	ctx := r.Context()

	transactionList, err := h.repo.ListByUser(ctx, reqUserID, reqCurrency, limit, offset)

	if err != nil {
		h.writeError(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.writeJSON(w, http.StatusOK, transactionList)
}

// Helper functions

// writeJSON writes a JSON response with the given status code
func (h *Handler) writeJSON(w http.ResponseWriter, status int, data interface{}) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(data)
}

// writeError writes an error response
func (h *Handler) writeError(w http.ResponseWriter, status int, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	json.NewEncoder(w).Encode(models.ErrorResponse{Error: message})
}
